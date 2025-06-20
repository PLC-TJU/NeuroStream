function results = routineFeatureAnalysis(data, label, Info, domain)
    results = struct();
    results.analysisType = '常规特征分析';
    results.domain = domain;
    results.fs = Info.fs;
    results.freqs = [1, 40];
    results.channels = Info.chaninfo;
    results.timewindow = Info.period;
    results.chanSelect = {'C3','C4'};
    
    % 获取前两类类别信息
    numClasses = 2;
    classLabels = unique(label);
    data=data(:,:,label<=classLabels(numClasses));
    label=label(label<=classLabels(numClasses));
    results.classLabels = classLabels(1:numClasses);

    % 预处理
    targetFs=250;
    temp=resample(permute(data,[2,1,3]),targetFs,results.fs);
    data=permute(temp,[2,1,3]);
    results.fs=targetFs;

    % 1. 计算功率谱密度 (PSD)
    [psdResults, f] = calculatePSD(data, label, results.fs, results.freqs);
    results.psd = psdResults;
    results.psdFreqs = f;
    
    % 2. 计算时频分析 (ERSP) - 仅计算一次
    [ERSP,freqsERSP,timesERSP,~,ERSP_All] = ERSP_timefre_Calcu(data, label, ...
        results.freqs, results.timewindow, results.fs);

    erspResults = cell(numClasses, 1);
    for cls = 1:numClasses 
        erspResults{cls} = struct(...
            'ERSP', ERSP{cls}, ...
            'freqs', freqsERSP, ...
            'times', timesERSP, ...
            'ERSP_All', ERSP_All{cls});
    end
    results.ersp = erspResults;

    % 3. 计算时频图显著性差异（如果类别数>=2）
    if numClasses >= 2
        
        [~, chanIdx] = ismember(results.chanSelect, results.channels);
        chanIdx(chanIdx == 0) = [];
        sigERSP = cell(numel(chanIdx), 1);
        
        for ch = 1:numel(chanIdx)
            % 获取两个类别的所有样本数据
            data1 = squeeze(erspResults{1}.ERSP_All(:, erspResults{1}.times>0, chanIdx(ch), :));
            data2 = squeeze(erspResults{2}.ERSP_All(:, erspResults{2}.times>0, chanIdx(ch), :));
            
            % 计算每个时频点的p值
            [~, pvals] = ttest2(data1, data2, 'Dim', 3);
            
            % FDR校正
            % flatPvals = pvals(:);
            % flatPvals = mafdr(flatPvals);
            % pvals = reshape(flatPvals, size(pvals));
            
            % 创建显著性差异图
            sigImage = ones(size(pvals));
            sigImage(pvals < 0.05) = pvals(pvals < 0.05);
            %sigImage(pvals < 0.05) = pvals(pvals < 0.05);

            baseImage = ones(length(erspResults{1}.freqs), length(find(erspResults{1}.times<=0)));
            sigImage = cat(2, baseImage, sigImage);
            
            sigERSP{ch} = sigImage;
        end

        results.sigERSP = sigERSP;
    end
    
    % 4. 计算脑地形图 - 使用预定义频带
    topoConfig = struct(...
        'alpha', [8, 13], ...
        'beta',  [13, 30], ...
        'theta', [4, 8], ...
        'gamma', [30, 40]);
    
    topoResults = struct();
    sigTopoResults = struct(); % 存储显著性差异结果

    for band = fieldnames(topoConfig)'
        bandName = band{1};
        freqRange = topoConfig.(bandName);
        
        bandResults = cell(numClasses, 1);
        allBandData = cell(numClasses, 1); % 存储所有样本数据

        for cls = 1:numClasses           
            % 选择特定时间窗和频带
            timeIdx = timesERSP >= 0 & timesERSP <= results.timewindow(2)*1000;
            freqIdx = freqsERSP >= freqRange(1) & freqsERSP <= freqRange(2);
            
            % 提取所有样本的地形图数据
            clsERSP_All = erspResults{cls}.ERSP_All;
            bandData = squeeze(mean(clsERSP_All(freqIdx, timeIdx, :, :), [1, 2]));
            bandResults{cls} = mean(bandData, 2);
            bandData = real(10*log10(bandData));%转换为dB
            bandResults{cls} = real(10*log10(bandResults{cls}));%转换为dB

            % 存储结果
            allBandData{cls} = bandData;%通道数*样本数
        end

        topoResults.(bandName) = bandResults;
        
        % 计算显著性差异（如果类别数>=2）
        if numClasses >= 2
            % 准备数据
            data1 = allBandData{1};
            data2 = allBandData{2};
            
            % 计算每个通道的p值
            [~, pvals] = ttest2(data1, data2, 'Dim', 2);
            
            % FDR校正
            % pvals = mafdr(pvals);
            
            % 创建显著性差异图数据
            sigTopo = ones(size(pvals));
            sigTopo(pvals < 0.05) = pvals(pvals < 0.05); % 使用校正后的p值
            %sigTopo(pvals < 0.05) = pvals(pvals < 0.05);
            
            sigTopoResults.(bandName) = sigTopo;
        end
    end

    results.topo = topoResults;
    if numClasses >= 2
        results.sigTopo = sigTopoResults;
    end

end


