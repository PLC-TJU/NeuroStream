function [ERSP, freqs, times, ERSP_All] = ERSP_timefreq_calc(PlotData, Label, fs, timewindow, fRange, method, params)
% ERSP_TIMEFREQ_CALC 计算各类别各样本各通道的 ERSP（STFT或小波变换）
%
% 用法:
%   [ERSP_All, ERSP, freqs, times] = ERSP_timefreq_calc(...
%       PlotData, Label, fs, timewindow, baselineWindow, fRange, method, params)
%
% 输入:
%   PlotData       - [C × T × N] 数据矩阵，C 通道数，T 时间点，N 样本数
%   Label          - [N × 1] 样本类别标签
%   fs             - 采样率 (Hz)
%   timewindow     - [t_start t_end] 试次时间窗 (秒，相对于事件标记)
%   fRange         - [fmin fmax] 频率范围 (Hz)，默认为 [1, 40]
%   method         - 'stft' (默认) 或 'wavelet'
%   params         - 结构体, 方法参数:
%       params.outlierThreshold - 异常值检测的MAD阈值 (默认3)
%       如果 method='stft':
%         .window    - 窗长 (秒, 默认0.5)
%         .noverlap  - 重叠 (秒, 默认0.4)
%         .nfft      - FFT 点数 (默认 2^nextpow2(window*fs))
%       如果 method='wavelet':
%         .waveletName - 小波基名称 (默认 'morl')
%         .numVoices   - 每八度声部分辨率 (默认12)
%         .fbands      - 频带向量 [f1 f2; f3 f4; ...] (可选)
%
% 输出:
%   ERSP_All - 元胞数组 {K×1}, 每元胞 [F × L × C × Nk]
%   ERSP     - 元胞数组 {K×1}, 每元胞 [F × L × C]
%   freqs    - 频率向量 (Hz)
%   times    - 时间向量 (毫秒，相对于事件标记)

% 参数检查 & 默认设置
if nargin < 7, params = struct(); end
if nargin < 6 || isempty(method), method = 'stft'; end
if nargin < 5 || isempty(fRange), fRange = [1, 40]; end

% 确定样本信息
[C, T, ~] = size(PlotData);
labels = unique(Label); 
K = numel(labels);

% 验证时间窗
if timewindow(2) <= timewindow(1)
    error('时间窗无效: 结束时间必须大于开始时间');
end

% 设置目标分辨率
target_time_res = 0.02; % 0.02秒时间分辨率
target_freq_res = 0.5;  % 0.5Hz频率分辨率

% 计算时间窗裁剪量（去除边缘0.5秒）
crop_sec = 0.5; % 裁剪0.5秒边缘
cropped_timewindow = [timewindow(1) + crop_sec, timewindow(2) - crop_sec];
if cropped_timewindow(2) <= cropped_timewindow(1)
    error('裁剪后时间窗无效: 原始时间窗至少需要%.1f秒', 2*crop_sec);
end

% 创建优化时间向量（仅包含裁剪后范围）
time_points = cropped_timewindow(1):target_time_res:cropped_timewindow(2);

% 默认基线窗口（刺激前）
baselineWindow = [timewindow(1), 0];
if baselineWindow(2) <= baselineWindow(1)
    baselineWindow = [timewindow(1), timewindow(1) + 0.1]; % 默认100ms基线
end

% 设置方法参数
min_win_sec = 1.0; % 最小窗长1秒
if strcmpi(method, 'stft')
    % STFT 参数优化
    if ~isfield(params, 'window')
        % 确保窗长≥1秒
        params.window = max(min_win_sec, 1/(2*target_freq_res)); 
    end
    if ~isfield(params, 'noverlap'), params.noverlap = 0.8; end
    if ~isfield(params, 'nfft'), params.nfft = 2^nextpow2(params.window*fs); end
    
    wlen = round(params.window * fs);
    nov = round(params.noverlap * wlen);
    nfft = 2^nextpow2(wlen);
    
    % 计算裁剪索引
    crop_samples = round(crop_sec * fs);
    
elseif strcmpi(method, 'wavelet')
    % 小波参数优化
    if ~isfield(params, 'waveletName'), params.waveletName = 'morl'; end
    if ~isfield(params, 'numVoices'), params.numVoices = 12; end
    if ~isfield(params, 'minCycles'), params.minCycles = 4; end % 最小4个周期
    if ~isfield(params, 'maxCycles'), params.maxCycles = 8; end % 最大8个周期
    
    % 计算裁剪索引（小波使用最大半长）
    crop_samples = 0; % 初始化为0
end

% 创建优化频率向量（控制分辨率）
minFreq = max(0.5, fRange(1));
maxFreq = fRange(2);
freqs = minFreq:target_freq_res:maxFreq;
F = length(freqs);

% 预分配输出
ERSP_All = cell(K, 1);
ERSP = cell(K, 1);

% ======================== 准备并行计算 ========================
% 创建任务列表（类别×通道×试次）
taskList = cell(0);
taskCount = 0;

for k = 1:K
    idx = find(Label == labels(k));
    Nk = numel(idx);
    for ch = 1:C
        for i = 1:Nk
            taskCount = taskCount + 1;
            taskList{taskCount} = struct(...
                'k', k, ...
                'ch', ch, ...
                'trialIdx', idx(i), ...
                'sig', squeeze(PlotData(ch, :, idx(i))));
        end
    end
end

% 预分配结果存储
allResults = cell(taskCount, 1);

% ======================== 并行计算核心 ========================
fprintf('开始并行计算 %d 个ERSP任务...\n', taskCount);
startTime = tic;

% 准备小波（如果使用小波方法）
if strcmpi(method, 'wavelet')
    wavelets = cell(F, 1);
    halfLens = zeros(F, 1);
    maxHalfLen = 0; % 跟踪最大半长
    
    for fi = 1:F
        nCycles = max(params.minCycles, min(params.maxCycles, freqs(fi)/2));
        sf = freqs(fi)/nCycles;
        st = 1/(2*pi*sf);
        t_wavelet = -3.5*st:1/fs:3.5*st;
        wavelet = exp(2i*pi*freqs(fi)*t_wavelet) .* exp(-t_wavelet.^2/(2*st^2));
        wavelets{fi} = wavelet / norm(wavelet);
        halfLen = floor(length(wavelet)/2);
        halfLens(fi) = halfLen;
        
        % 更新最大半长（用于裁剪）
        if halfLen > maxHalfLen
            maxHalfLen = halfLen;
        end
    end
    
    % 设置小波裁剪量
    crop_samples = maxHalfLen;
else
    wavelets = [];
    halfLens = [];
end

% 计算原始时间向量
t_orig = linspace(timewindow(1), timewindow(2), T);

% 裁剪索引（去除边缘）
crop_start = crop_samples + 1;
crop_end = T - crop_samples;
t_cropped = t_orig(crop_start:crop_end);

% 确保目标时间点在裁剪范围内
valid_time_points = time_points >= min(t_cropped) & time_points <= max(t_cropped);
time_points = time_points(valid_time_points);
T_opt = length(time_points);

% 基线索引（基于裁剪后时间）
baseIdx = time_points >= baselineWindow(1) & time_points <= baselineWindow(2);
if sum(baseIdx) < 3
    baseIdx = 1:floor(T_opt*0.1); % 使用前10%作为基线
    warning('基线窗口太小，使用时间窗前10%%作为基线');
end

% 并行处理所有任务
for taskIdx = 1:taskCount%parfor for cwt
    task = taskList{taskIdx};
    sig = task.sig;
    
    % 裁剪信号边缘
    sig_cropped = sig(crop_start:crop_end);
    P_opt = zeros(F, T_opt);
    switch lower(method)
        case 'stft'
            % 高分辨率STFT
            %[S, ~, t_stft] = spectrogram(sig_cropped, hann(wlen), nov, freqs, fs);

            [S, ~, t_stft] = stft(sig_cropped, fs, 'Window', hann(wlen), ...
                'OverlapLength', nov, 'FFTLength', nfft);

            P = real(abs(S).^2);
            
            % 插值到优化时间点
            for fi = 1:F
                P_opt(fi, :) = interp1( ...
                    t_stft + t_cropped(1), ...
                    P(fi, :), ...
                    time_points, ...
                    'linear', 'extrap');%#ok
            end
            
        case 'wavelet'
            % 高效小波变换
            P_cropped = zeros(F, length(sig_cropped));
            
            for fi = 1:F
                wavelet = wavelets{fi};%#ok
                halfLen = halfLens(fi);%#ok
                
                % 卷积计算
                convResult = conv(sig_cropped, wavelet, 'same');
                
                % 计算功率
                power = real(abs(convResult).^2);
                
                % 处理边缘效应
                if halfLen > 0
                    power(1:halfLen) = mean(power(halfLen+1:halfLen+min(10, ...
                        length(power)-halfLen)));
                    power(end-halfLen+1:end) = mean(power(end-halfLen-min(9, ...
                        length(power)-halfLen-1):end-halfLen));
                end
                
                P_cropped(fi, :) = power;
            end
            
            % 插值到优化时间点
            for fi = 1:F
                P_opt(fi, :) = interp1(t_cropped, P_cropped(fi, :), time_points, 'linear', 'extrap');
            end
    end
    
    % 基线校正
    basePower = mean(P_opt(:, baseIdx), 2);
    basePower(basePower <= 0) = eps; % 避免除以0
    ersp = real(10*log10(bsxfun(@rdivide, P_opt, basePower)));
    
    % 存储结果
    allResults{taskIdx} = struct(...
        'k', task.k, ...
        'ch', task.ch, ...
        'trialIdx', task.trialIdx, ...
        'ersp', ersp);
end

fprintf('并行计算完成，耗时 %.2f 秒\n', toc(startTime));

% ======================== 重组结果 ========================
% 初始化存储
for k = 1:K
    Nk = sum(Label == labels(k)); % 使用实际样本数
    ERSP_All{k} = zeros(F, T_opt, C, Nk);
end

% 填充结果
for taskIdx = 1:taskCount
    result = allResults{taskIdx};
    if isempty(result)
        continue; 
    end

    k = result.k;
    ch = result.ch;
    trialIdx = result.trialIdx;
    
    % 在类别内找到试次索引
    classTrials = find(Label == labels(k));
    trialPos = find(classTrials == trialIdx, 1);
    
    if ~isempty(trialPos) && trialPos <= size(ERSP_All{k}, 4)
        ERSP_All{k}(:, :, ch, trialPos) = result.ersp;
    end
end

% ======================== 异常值处理 ========================
% 设置默认阈值
if isfield(params, 'outlierThreshold')
    outlier_threshold = params.outlierThreshold;
else
    outlier_threshold = 3; % 默认MAD阈值
end

cleanERSP_All = cell(K, 1);

for k = 1:K
    fprintf('处理类别 %d 的异常值...\n', labels(k));
    
    % 使用removeOutliers函数检测和移除异常值
    [cleanERSP_All{k}, outliers] = removeOutliers(ERSP_All{k}, ...
        outlier_threshold);
    
    fprintf('  类别 %d: 移除了 %d/%d 个异常试次\n', ...
        labels(k), sum(outliers), size(ERSP_All{k}, 4));
end

% ======================== 计算平均ERSP ========================
for k = 1:K
    if isempty(cleanERSP_All{k})
        warning('类别 %d 无有效试次，使用原始数据', labels(k));
        ERSP{k} = mean(ERSP_All{k}, 4);
    else
        ERSP{k} = mean(cleanERSP_All{k}, 4);
    end
end

% 输出时间向量（毫秒）
times = time_points * 1000;
end

% ======================== 异常值检测函数 ========================
function [cleanData, outliers] = removeOutliers(data, threshold)
    % 基于MAD的稳健异常值检测
    % 输入:
    %   data - [F × T × C × N] 四维数组
    %   threshold - MAD阈值 (默认3)
    %   推荐值范围:
    %      threshold = 3;     % 标准严格度 (推荐)
    %      threshold = 2.5;   % 更严格 (小样本)
    %      threshold = 3.5;   % 更宽松 (大样本)
    % 输出:
    %   cleanData - 移除异常值后的数据
    %   outliers - 逻辑向量，标记异常试次
    
    if nargin < 2 || isempty(threshold)
        threshold = 3; % 默认阈值
    end
    
    % 计算每个试次的总体ERSP强度
    trialIntensity = squeeze(mean(mean(mean(abs(data), 1), 2), 3));
    
    % 稳健统计量计算
    medIntensity = median(trialIntensity);
    madIntensity = mad(trialIntensity, 1) * 1.4826; % 转换为标准差估计
    
    % 计算Z分数
    zScores = abs(trialIntensity - medIntensity) / (madIntensity + eps);
    
    % 检测异常值
    outliers = zScores > threshold;
    
    % 移除非异常试次
    cleanData = data(:, :, :, ~outliers);
end