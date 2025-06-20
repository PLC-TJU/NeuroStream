function [psdResults, f] = calculatePSD(data, label, fs, freqs)
    % 参数设置
    nfft = 2^nextpow2(size(data, 2)); % DFT点数
    method = 'welch'; % 使用welch或periodogram方法
    window = hamming(size(data, 2)); % 窗函数
    outputType = 'dB'; % 输出单位为dB（不要更改）
    
    % 获取类别信息
    classLabels = unique(label);
    numClasses = numel(classLabels);
    
    % 预分配存储
    psdResults = cell(numClasses, 1);
    
    % 对每个类别计算PSD
    for cls = 1:numClasses
        clsData = data(:, :, label == classLabels(cls));
        
        % 计算该类别的PSD
        [meanPSD, f, allPSD, stdPSD] = p_psd(clsData, fs, freqs, nfft, method, window, outputType);
        
        % 存储结果
        psdResults{cls} = struct(...
            'meanPSD', meanPSD, ...       % 平均PSD [freqs × channels]
            'stdPSD',  stdPSD, ...        % 标准差PSD [freqs × channels]
            'allPSD',  allPSD, ...        % 所有样本PSD [freqs × channels × samples]
            'f', f);
    end
end