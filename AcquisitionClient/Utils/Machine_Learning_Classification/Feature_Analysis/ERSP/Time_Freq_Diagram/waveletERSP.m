function [ERSP, freqs, times, powbase, ERSP_All] = waveletERSP(PlotData, Label, channel, passband, timewindow, fs)
    % 输入验证
    if nargin < 6
        fs = 250;
        warning('未提供采样率，默认使用250Hz');
    end
    if numel(passband) ~= 2
        error('passband应为包含两个元素的数组，例如[8, 30]');
    end
    if size(PlotData, 1) ~= length(channel)
        error('导联数量(%d)与数据维度(%d)不匹配!', length(channel), size(PlotData, 1));
    end
    
    % 参数设置
    frames = size(PlotData, 2);
    classLabels = unique(Label);
    numClasses = numel(classLabels);
    numChannels = numel(channel);
    
    % 时间窗处理
    if nargin < 5 || isempty(timewindow)
        timewindow = [0, frames/fs];
    end
    t = linspace(timewindow(1), timewindow(2), frames);
    
    % 频率参数设置
    minFreq = passband(1);
    maxFreq = passband(2);
    numFreqs = min(100, max(30, round((maxFreq-minFreq)*2))); % 自适应频率点数
    freqs = logspace(log10(minFreq), log10(maxFreq), numFreqs); % 对数间隔频率
    
    % 基线设置
    baseIdx = t >= timewindow(1) & t <= 0;  % 刺激前为基线
    
    % 小波参数
    nCycles = 7; % 小波周期数
    dt = 1/fs;   % 采样间隔
    
    % 预计算小波
    wavelets = cell(numFreqs, 1);
    for fi = 1:numFreqs
        sf = freqs(fi)/nCycles;
        st = 1/(2*pi*sf);
        t_wavelet = -3.5*st:dt:3.5*st;
        wavelet = exp(2i*pi*freqs(fi)*t_wavelet) .* exp(-t_wavelet.^2/(2*st^2));
        wavelets{fi} = wavelet / sqrt(sum(abs(wavelet).^2)); % 能量归一化
    end
    
    % 预分配输出
    ERSP = cell(numClasses, 1);
    ERSP_All = cell(numClasses, 1);
    powbase = cell(numClasses, 1);
    
    % 主计算循环
    for cls = 1:numClasses
        % 获取当前类别的数据
        clsIdx = Label == classLabels(cls);
        clsData = PlotData(:, :, clsIdx);
        numTrials = size(clsData, 3);
        
        % 预分配类别存储
        clsERSP = zeros(numFreqs, frames, numChannels);
        clsERSP_All = zeros(numFreqs, frames, numChannels, numTrials);
        clsPowbase = zeros(numFreqs, numChannels);
        
        % 并行计算通道
        for ch = 1:numChannels
            fprintf('处理类别 %d/%d, 通道 %d/%d\n', cls, numClasses, ch, numChannels);
            
            chPowbase = zeros(numFreqs, numTrials);
            chERSP_All = zeros(numFreqs, frames, numTrials);
            
            % 计算每个试次
            for trial = 1:numTrials
                signal = squeeze(clsData(ch, :, trial));
                
                % 小波变换
                tf = zeros(numFreqs, frames);
                for fi = 1:numFreqs
                    wavelet = wavelets{fi};
                    halfLen = floor(length(wavelet)/2);
                    
                    % 卷积计算
                    convResult = conv(signal, wavelet, 'same');
                    
                    % 计算功率
                    power = abs(convResult).^2;
                    
                    % 处理边缘效应
                    power(1:halfLen) = power(halfLen+1);
                    power(end-halfLen+1:end) = power(end-halfLen);
                    
                    tf(fi, :) = power;
                end
                
                % 基线校正
                basePower = mean(tf(:, baseIdx), 2);
                ersp = 10*log10(bsxfun(@rdivide, tf, basePower));
                
                % 存储结果
                chERSP_All(:, :, trial) = ersp;
                chPowbase(:, trial) = basePower;
            end
            
            % 平均处理
            clsERSP(:, :, ch) = mean(chERSP_All(:, :, ch), 3);
            clsERSP_All(:, :, ch, :) = chERSP_All;
            clsPowbase(:, ch) = mean(chPowbase, 2);
        end
        
        ERSP{cls} = clsERSP;
        ERSP_All{cls} = clsERSP_All;
        powbase{cls} = clsPowbase;
    end
    
    % 输出时间向量（毫秒）
    times = t * 1000;
end