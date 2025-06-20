function results = crossDomainFeatureAnalysis(sdata, slabel, tdata, tlabel, Info)
    results = struct();
    results.analysisType = '跨域特征分析';
    results.fs = Info.fs;
    results.freqs = [1, 40];
    results.channels = Info.chaninfo;
    results.timewindow = Info.period;
    results.chanSelect = {'C3','C4'};
    
    % 获取类别信息（最多处理前两类）
    classLabels = unique([slabel(:); tlabel(:)]);
    numClasses = min(2, numel(classLabels)); % 最多处理两类
    results.classLabels = classLabels(1:numClasses);
    
    % 筛选前两类数据
    sdata = sdata(:,:,ismember(slabel, results.classLabels));
    slabel = slabel(ismember(slabel, results.classLabels));
    tdata = tdata(:,:,ismember(tlabel, results.classLabels));
    tlabel = tlabel(ismember(tlabel, results.classLabels));

    % 预处理
    targetFs=250;
    temp=resample(permute(sdata,[2,1,3]),targetFs,results.fs);
    sdata=permute(temp,[2,1,3]);
    temp=resample(permute(tdata,[2,1,3]),targetFs,results.fs);
    tdata=permute(temp,[2,1,3]);
    results.fs=targetFs;
    
    % 1. 计算源域和目标域的PSD
    [psdSource, f] = calculatePSD(sdata, slabel, results.fs, results.freqs);
    [psdTarget, ~] = calculatePSD(tdata, tlabel, results.fs, results.freqs);
    results.psdSource = psdSource;
    results.psdTarget = psdTarget;
    results.psdFreqs = f;
    
    % 2. 计算源域和目标域的ERSP (共享频率和时间轴)
    [ERSP_S, freqsERSP, timesERSP, ~, ERSP_All_S] = ERSP_timefre_Calcu( ...
        sdata, slabel, results.freqs, results.timewindow, results.fs);
    
    [ERSP_T, ~, ~, ~, ERSP_All_T] = ERSP_timefre_Calcu( ...
        tdata, tlabel, results.freqs, results.timewindow, results.fs);
    
    % 存储结果
    results.erspFreqs = freqsERSP;
    results.erspTimes = timesERSP;
    
    erspSource = cell(numClasses, 1);
    erspTarget = cell(numClasses, 1);
    for cls = 1:numClasses 
        erspSource{cls} = struct(...
            'ERSP', ERSP_S{cls}, ...
            'ERSP_All', ERSP_All_S{cls});
        
        erspTarget{cls} = struct(...
            'ERSP', ERSP_T{cls}, ...
            'ERSP_All', ERSP_All_T{cls});
    end
    results.erspSource = erspSource;
    results.erspTarget = erspTarget;

    % 3. 计算时频图显著性差异（针对前两个类别和C3、C4通道）
    [~, chanIdx] = ismember(results.chanSelect, results.channels);
    chanIdx(chanIdx == 0) = [];
    sigERSP = cell(numClasses, numel(chanIdx));

    for cls = 1:numClasses
        for ch = 1:numel(chanIdx)
            % 获取源域和目标域的所有样本数据
            data_S = squeeze(erspSource{cls}.ERSP_All(:, timesERSP>0, chanIdx(ch), :));
            data_T = squeeze(erspTarget{cls}.ERSP_All(:, timesERSP>0, chanIdx(ch), :));
            
            % 计算每个时频点的p值
            [~, pvals] = ttest2(data_S, data_T, 'Dim', 3);
            
            % FDR校正
            % flatPvals = pvals(:);
            % flatPvals = mafdr(flatPvals);
            % pvals = reshape(flatPvals, size(pvals));
            
            % 创建显著性差异图
            sigImage = ones(size(pvals));
            sigImage(pvals < 0.05) = pvals(pvals < 0.05);

            baseImage = ones(length(freqsERSP), length(find(timesERSP<=0)));
            sigImage = cat(2, baseImage, sigImage);
            
            sigERSP{cls, ch} = sigImage;
        end
    end
    
    results.sigERSP = sigERSP;
    
    % 4. 计算脑地形图 (多频带)
    topoConfig = struct(...
        'alpha', [8, 13], ...
        'beta',  [13, 30]);
    
    topoSource = struct();
    topoTarget = struct();
    sigTopoResults = struct(); % 存储显著性差异结果
    
    for band = fieldnames(topoConfig)'
        bandName = band{1};
        freqRange = topoConfig.(bandName);
        
        srcResults = cell(numClasses, 1);
        tgtResults = cell(numClasses, 1);
        sigResults = cell(numClasses, 1);
        
        for cls = 1:numClasses
            % 选择特定时间窗和频带
            timeIdx = timesERSP >= 0 & timesERSP <= results.timewindow(2)*1000;
            freqIdx = freqsERSP >= freqRange(1) & freqsERSP <= freqRange(2);

            % 提取所有样本的地形图数据
            clsERSP_S = erspSource{cls}.ERSP_All;
            topoVal_S = squeeze(mean(clsERSP_S(freqIdx, timeIdx, :, :), [1, 2]));%通道数*样本数
            srcResults{cls} = mean(topoVal_S, 2);
            topoVal_S = real(10*log10(topoVal_S));%转换为dB
            srcResults{cls} = real(10*log10(srcResults{cls}));%转换为dB
            
            % 目标域地形图
            clsERSP_T = erspTarget{cls}.ERSP_All;
            topoVal_T = squeeze(mean(clsERSP_T(freqIdx, timeIdx, :, :), [1, 2]));%通道数*样本数
            tgtResults{cls} = mean(topoVal_T, 2);
            topoVal_T = real(10*log10(topoVal_T));%转换为dB
            tgtResults{cls} = real(10*log10(tgtResults{cls}));%转换为dB

            % 计算每个通道的p值
            [~, pvals] = ttest2(topoVal_S, topoVal_T, 'Dim', 2);

            % FDR校正
            % pvals = mafdr(pvals);
            
            % 创建显著性差异图数据
            sigTopo = ones(size(pvals));
            sigTopo(pvals < 0.05) = pvals(pvals < 0.05); % 使用校正后的p值
                        
            sigResults{cls} = sigTopo;
        end
        
        topoSource.(bandName) = srcResults;
        topoTarget.(bandName) = tgtResults;
        sigTopoResults.(bandName) = sigResults;
        
    end
    
    results.topoSource = topoSource;
    results.topoTarget = topoTarget;
    results.sigTopo = sigTopoResults;
end