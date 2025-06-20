function displayFeatureResults(results)
    fig = figure('Name', 'EEG特征分析结果', 'NumberTitle', 'off', ...
        'Position', [100, 100, 1200, 800], 'Color', 'w');

    if strcmp(results.analysisType, '常规特征分析')
        displayRoutineResults(fig, results);
    else
        displayCrossDomainResults(fig, results);
    end
end

%% 常规特征分析结果显示
function displayRoutineResults(fig, results)
    % 加载时频图映射颜色图
    load('colormap_mne.mat','RdBu_r') 

    % 加载显著性p值映射颜色图
    load('pvalue_colormap.mat','pvalue_colormap');

    % 创建图窗
    figure(fig);
    classLabels = results.classLabels;
    numClasses = numel(classLabels);
    hasSig = numClasses >= 2 && isfield(results, 'sigERSP') && isfield(results, 'sigTopo');
    
    % 预设参数
    chanSelect = results.chanSelect;
    [~, chanIdx] = ismember(chanSelect, results.channels);
    chanIdx(chanIdx == 0) = [];
    bands = fieldnames(results.topo);
    
    % 创建选项卡组
    tabGroup = uitabgroup(fig, 'Position', [0, 0, 1, 1]);
    
    %% 1. 功率谱选项卡
    psdTab = uitab(tabGroup, 'Title', '功率谱');
    t = tiledlayout(psdTab, numel(chanIdx), 1, 'TileSpacing', 'compact');
    
    for ch = 1:numel(chanIdx)
        ax = nexttile(t);
        hold(ax, 'on');
        grid(ax, 'on');
        
        colors = lines(numClasses);
        legendEntries = cell(numClasses, 1);
        % 绘制每个类别的PSD曲线
        for cls = 1:numClasses
            % 平均PSD
            meanPSD = results.psd{cls}.meanPSD(:, chanIdx(ch));
            % 标准差
            stdPSD = results.psd{cls}.stdPSD(:, chanIdx(ch));
            
            % 绘制曲线和阴影
            freq = results.psdFreqs;
            h(cls) = plot(ax, freq, meanPSD, ...
                'LineWidth', 2, 'Color', colors(cls, :));%#ok
            
            % 添加标准差阴影
            x = [freq; flipud(freq)];
            y = [meanPSD - stdPSD; flipud(meanPSD + stdPSD)];
            fill(ax, x, y, colors(cls, :), ...
                'FaceAlpha', 0.2, 'EdgeColor', 'none');
            
            legendEntries{cls} = sprintf('类别 %d', classLabels(cls)); 
        end
        
        hold(ax, 'off');
        title(ax, sprintf('通道 %s 功率谱', chanSelect{ch}));
        xlabel(ax, '频率 (Hz)');
        ylabel(ax, '功率 (dB)');
        xlim(ax, [min(freq), max(freq)]);
        legend(ax, h, legendEntries, 'Location', 'best');
    end

    %% 2. 时频图选项卡
    erspTab = uitab(tabGroup, 'Title', '时频分析');
    rows = numClasses + double(hasSig); % 增加一行用于显著性图
    t = tiledlayout(erspTab, rows, numel(chanIdx), 'TileSpacing', 'tight', ...
        'Padding', 'compact');
    
    % 绘制每个类别和通道的ERSP
    for cls = 1:numClasses
        for ch = 1:numel(chanIdx)
            ax = nexttile(t);
            clsERSP = real(results.ersp{cls}.ERSP);
            
            hold(ax, 'on');
            imagesc(ax, results.ersp{cls}.times/1000, results.ersp{cls}.freqs, ...
                clsERSP(:, :, chanIdx(ch)), [-5, 5]);
            plot(ax, [0, 0], [results.ersp{cls}.freqs(1), results.ersp{cls}.freqs(end)], ...
                '--k','linewidth', 1.5);
            hold(ax, 'off');
            axis(ax, 'xy');
            xlim([round(results.ersp{cls}.times(1)/1000), round(results.ersp{cls}.times(end)/1000)]);
            ylim([round(results.ersp{cls}.freqs(1)), round(results.ersp{cls}.freqs(end))]);

            colorbar(ax);
            title(ax, sprintf('类别 %d - %s', classLabels(cls), chanSelect{ch}));
            xlabel(ax, '时间 (s)');
            ylabel(ax, '频率 (Hz)');

            % 设置颜色映射
            colormap(ax, RdBu_r);
        end
    end
    
    % 添加显著性差异图（比较前两个类别）
    if hasSig
        for ch = 1:numel(chanIdx)
            ax = nexttile(t);
            sigImage = results.sigERSP{ch};
            
            % 创建显著性差异图
            hold on
            imagesc(ax, results.ersp{1}.times/1000, results.ersp{1}.freqs, sigImage);
            plot(ax, [0, 0], [results.ersp{1}.freqs(1), results.ersp{1}.freqs(end)], ...
                '--k','linewidth', 1.5);
            hold off
            axis(ax, 'xy');
            xlim(ax, [round(results.ersp{1}.times(1)/1000), round(results.ersp{1}.times(end)/1000)]);
            ylim(ax, [round(results.ersp{1}.freqs(1)), round(results.ersp{1}.freqs(end))]);

            colorbar(ax, 'Ticks', [0, 0.05, 0.1], 'TickLabels', {'0 (sig)', '0.05', '>0.05'});
            caxis(ax, [0, 0.1]);
            title(ax, sprintf('类别 %d vs %d - %s', classLabels(1), classLabels(2), chanSelect{ch}));
            
            % 设置颜色映射
            colormap(ax, pvalue_colormap);
            caxis(ax, [0, 0.1]); % 突出显示显著区域
        end
    end
    
    %% 3. 脑地形图选项卡
    topoTab = uitab(tabGroup, 'Title', '脑地形图');
    rows = numClasses + double(hasSig); % 增加一行用于显著性图
    t = tiledlayout(topoTab, rows, numel(bands), 'TileSpacing', 'tight', 'Padding', 'compact');
    
    % 绘制每个类别和频带的地形图
    for cls = 1:numClasses
        for b = 1:numel(bands)
            ax = nexttile(t);
            band = bands{b};
            topoData = results.topo.(band){cls};
            
            try
                PlotTopomap(topoData);
                title(ax, sprintf('类别 %d - %s频带', classLabels(cls), band));
%                 set(ax, 'Clim', [-2, 2]);
%                 colorbar(ax, 'Ticks', -2:1:2);
                colorbar(ax);
            catch
                text(ax, 0.5, 0.5, '需要EEGLAB', 'HorizontalAlignment', 'center');
                axis(ax, 'off');
            end
        end
    end
    
    % 添加显著性差异图（比较前两个类别）
    if hasSig
        for b = 1:numel(bands)
            ax = nexttile(t);
            band = bands{b};
            sigTopo = results.sigTopo.(band);
            
            try
                % 创建显著性地形图
                PlotTopomap(sigTopo, pvalue_colormap);
                
                title(ax, sprintf('类别 %d vs %d - %s', classLabels(1), classLabels(2), band));
                colorbar(ax, 'Ticks', [0, 0.05, 0.1], 'TickLabels', {'0 (sig)', '0.05', '>0.05'});
                caxis(ax, [0, 0.1]);
            catch
                text(ax, 0.5, 0.5, '需要EEGLAB', 'HorizontalAlignment', 'center');
                axis(ax, 'off');
            end
        end
    end
end

%% 跨域特征分析结果显示
function displayCrossDomainResults(fig, results)
    % 加载时频图映射颜色图
    load('colormap_mne.mat','RdBu_r') 

    % 加载显著性p值映射颜色图
    load('pvalue_colormap.mat','pvalue_colormap');

    % 创建图窗
    figure(fig);
    classLabels = results.classLabels;
    numClasses = numel(classLabels);
    hasSig = numClasses >= 1 && isfield(results, 'sigERSP') && isfield(results, 'sigTopo');
    
    % 预设参数
    chanSelect = results.chanSelect;
    [~, chanIdx] = ismember(chanSelect, results.channels);
    chanIdx(chanIdx == 0) = [];
    bands = fieldnames(results.topoSource);
    numBands = numel(bands);
    
    % 创建选项卡组
    tabGroup = uitabgroup(fig, 'Position', [0, 0, 1, 1]);
    
    %% 1. 功率谱选项卡（保持不变）
    psdTab = uitab(tabGroup, 'Title', '功率谱');
    numRows = 2; % 源域与目标域
    numCols = numel(chanSelect);
    t = tiledlayout(psdTab, numRows, numCols, 'TileSpacing', 'compact');
    
    freq = results.psdFreqs;
    % 源域PSD
    for ch = 1:numel(chanSelect)
        ax = nexttile(t, ch);
        hold(ax, 'on');
        grid(ax, 'on');

        colors = lines(numClasses);
        legendEntries = cell(numClasses, 1);

        for cls = 1:numClasses
            meanPSD_S = results.psdSource{cls}.meanPSD(:, chanIdx(ch));
            stdPSD_S = results.psdSource{cls}.stdPSD(:, chanIdx(ch));
            
            % 均值曲线
            h(cls) = plot(ax, freq, meanPSD_S, 'Color', colors(cls, :), 'LineWidth', 2);%#ok
    
            % 标准差阴影
            x = [freq; flipud(freq)];
            y_S = [meanPSD_S - stdPSD_S; flipud(meanPSD_S + stdPSD_S)];
            fill(ax, x, y_S, colors(cls, :), 'FaceAlpha', 0.2, 'EdgeColor', 'none');

            legendEntries{cls} = sprintf('类别 %d ', classLabels(cls)); 
        end
        
        title(ax, sprintf('源域-通道-%s', chanSelect{ch}));
        xlim(ax, [min(freq), max(freq)]);
        xlabel(ax, '频率 (Hz)');
        ylabel(ax, '功率 (dB)');
        legend(ax, h, legendEntries, 'Location', 'best');
    end

    % 目标域PSD
    for ch = 1:numel(chanSelect)
        ax = nexttile(t, numCols + ch);
        hold(ax, 'on');
        grid(ax, 'on');

        colors = lines(numClasses);
        legendEntries = cell(numClasses, 1);

        for cls = 1:numClasses
            meanPSD_T = results.psdTarget{cls}.meanPSD(:, chanIdx(ch));
            stdPSD_T = results.psdTarget{cls}.stdPSD(:, chanIdx(ch));
            
            % 均值曲线
            h(cls) = plot(ax, freq, meanPSD_T, 'Color', colors(cls, :), 'LineWidth', 2);
    
            % 标准差阴影
            x = [freq; flipud(freq)];
            y_T = [meanPSD_T - stdPSD_T; flipud(meanPSD_T + stdPSD_T)];
            fill(ax, x, y_T, colors(cls, :), 'FaceAlpha', 0.2, 'EdgeColor', 'none');

            legendEntries{cls} = sprintf('类别 %d ', classLabels(cls)); 
        end
        
        title(ax, sprintf('目标域-通道-%s', chanSelect{ch}));
        xlim(ax, [min(freq), max(freq)]);
        xlabel(ax, '频率 (Hz)');
        ylabel(ax, '功率 (dB)');
        legend(ax, h, legendEntries, 'Location', 'best');
    end


    %% 2. 时频图选项卡
    % 计算布局：3行（源域、目标域、显著性差异） × (类别数×通道数)列
    erspTab = uitab(tabGroup, 'Title', '时频分析');
    numRows = 2 + double(hasSig); % 增加一行用于显著性图
    numCols = numClasses * numel(chanSelect);
    t = tiledlayout(erspTab, numRows, numCols, 'TileSpacing', 'tight', ...
        'Padding', 'compact');
    
    % 第一行：源域时频图
    for cls = 1:numClasses
        for ch = 1:numel(chanSelect)
            colIdx = (cls-1)*numel(chanSelect) + ch;
            ax = nexttile(t, colIdx);
            
            clsERSP_S = real(results.erspSource{cls}.ERSP);
            imagesc(ax, results.erspTimes/1000, results.erspFreqs, ...
                clsERSP_S(:, :, chanIdx(ch)), [-5, 5]);
            
            hold(ax, 'on');
            plot(ax, [0, 0], [results.erspFreqs(1), results.erspFreqs(end)], ...
                '--k', 'LineWidth', 1.5);
            hold(ax, 'off');
            
            axis(ax, 'xy');
            xlim(ax, [results.erspTimes(1)/1000, results.erspTimes(end)/1000]);
            ylim(ax, [results.erspFreqs(1), results.erspFreqs(end)]);
            colormap(ax, RdBu_r);
            colorbar(ax);
            
            if cls == 1 && ch == 1
                ylabel(ax, '频率 (Hz)');
            end
            title(ax, sprintf('源域-类别 %d-%s', classLabels(cls), chanSelect{ch}));
        end
    end
    
    % 第二行：目标域时频图
    for cls = 1:numClasses
        for ch = 1:numel(chanSelect)
            colIdx = numCols + (cls-1)*numel(chanSelect) + ch;
            ax = nexttile(t, colIdx);
            
            clsERSP_T = real(results.erspTarget{cls}.ERSP);
            imagesc(ax, results.erspTimes/1000, results.erspFreqs, ...
                clsERSP_T(:, :, chanIdx(ch)), [-5, 5]);
            
            hold(ax, 'on');
            plot(ax, [0, 0], [results.erspFreqs(1), results.erspFreqs(end)], ...
                '--k', 'LineWidth', 1.5);
            hold(ax, 'off');
            
            axis(ax, 'xy');
            xlim(ax, [results.erspTimes(1)/1000, results.erspTimes(end)/1000]);
            ylim(ax, [results.erspFreqs(1), results.erspFreqs(end)]);
            colormap(ax, RdBu_r);
            colorbar(ax);
            
            if cls == 1 && ch == 1
                ylabel(ax, '频率 (Hz)');
            end
            title(ax, sprintf('目标域-类别 %d-%s', classLabels(cls), chanSelect{ch}));
        end
    end
    
    % 第三行：显著性差异图（比较源域和目标域）
    if hasSig
        for cls = 1:numClasses
            for ch = 1:numel(chanSelect)
                colIdx = 2*numCols + (cls-1)*numel(chanSelect) + ch;
                ax = nexttile(t, colIdx);

                sigImage = results.sigERSP{cls, ch};
                imagesc(ax, results.erspTimes/1000, results.erspFreqs, sigImage);

                hold(ax, 'on');
                plot(ax, [0, 0], [results.erspFreqs(1), results.erspFreqs(end)], ...
                    '--k', 'LineWidth', 1.5);
                hold(ax, 'off');

                axis(ax, 'xy');
                xlim(ax, [results.erspTimes(1)/1000, results.erspTimes(end)/1000]);
                ylim(ax, [results.erspFreqs(1), results.erspFreqs(end)]);
                colormap(ax, pvalue_colormap);
                caxis(ax, [0, 0.1]);

                cb = colorbar(ax);
                cb.Ticks = [0, 0.05, 0.1];
                cb.TickLabels = {'0 (sig)', '0.05', '>0.05'};

                if cls == 1 && ch == 1
                    ylabel(ax, '频率 (Hz)');
                end
                xlabel(ax, '时间 (s)');
                title(ax, sprintf('差异-类别 %d-%s', classLabels(cls), chanSelect{ch}));
            end
        end
    end
    
    %% 3. 脑地形图选项卡
    topoTab = uitab(tabGroup, 'Title', '脑地形图');
    numRows = 2 + double(hasSig); % 增加一行用于显著性图
    numCols = numel(bands) * numClasses;
    t = tiledlayout(topoTab, numRows, numCols, 'TileSpacing', 'tight', ...
        'Padding', 'compact');
    
    % 绘制源域和目标域的地形图
    for cls = 1:numClasses
        for b = 1:numBands
            band = bands{b};
            
            % 源域地形图
            colIdx = (cls-1)*numBands + b;
            ax = nexttile(t, colIdx);

            topoData_S = results.topoSource.(band){cls};
            try
                PlotTopomap(topoData_S, RdBu_r);
%                 topoplot(topoData_S, results.channels, ...
%                     'maplimits', 'maxmin', 'electrodes', 'on');
                title(ax, sprintf('源域-类别 %d-%s', classLabels(cls), band));
%                 set(ax, 'Clim', [-2, 2]);
%                 colorbar(ax, 'Ticks', -2:1:2);
                colorbar(ax);
            catch
                text(ax, 0.5, 0.5, '需要EEGLAB', 'HorizontalAlignment', 'center');
                axis(ax, 'off');
            end
            
            % 目标域地形图
            colIdx = numCols + (cls-1)*numBands + b;
            ax = nexttile(t, colIdx);
            topoData_T = results.topoTarget.(band){cls};
            try
                PlotTopomap(topoData_T, RdBu_r);
%                 topoplot(topoData_T, results.channels, ...
%                     'maplimits', 'maxmin', 'electrodes', 'on');
                title(ax, sprintf('目标域-类别 %d-%s', classLabels(cls), band));
%                 set(ax, 'Clim', [-2, 2]);
%                 colorbar(ax, 'Ticks', -2:1:2);
                colorbar(ax);
            catch
                text(ax, 0.5, 0.5, '需要EEGLAB', 'HorizontalAlignment', 'center');
                axis(ax, 'off');
            end
        end 
    end

    % 添加显著性差异图（比较源域和目标域）
    if hasSig
        for cls = 1:numClasses % 显示各类别
            for b = 1:numBands
                band = bands{b};
                colIdx = 2*numCols + (cls-1)*numBands + b;
                ax = nexttile(t, colIdx);

                sigTopo = results.sigTopo.(band){cls};
                try
                    % 创建显著性地形图
                    PlotTopomap(sigTopo, pvalue_colormap);
%                     topoplot(sigTopo, results.channels, ...
%                         'maplimits', [0, 0.1], 'electrodes', 'on', ...
%                         'emarker2', {find(sigTopo < 0.05), 'o', 'k', 8});
                    title(ax, sprintf('源域 vs 目标域 - %s (类别 %d)', band, classLabels(cls)));
                    colorbar(ax, 'Ticks', [0, 0.05, 0.1], 'TickLabels', {'0 (sig)', '0.05', '>0.05'});
                    caxis(ax, [0, 0.1]);
                catch
                    text(ax, 0.5, 0.5, '需要EEGLAB', 'HorizontalAlignment', 'center');
                    axis(ax, 'off');
                end
            end
        end
    end
end