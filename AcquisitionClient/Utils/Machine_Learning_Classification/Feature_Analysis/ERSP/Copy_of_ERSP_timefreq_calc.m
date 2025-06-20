function [ERSP, ERSP_All, freqs, times] = ERSP_timefreq_calc(PlotData, Label, fs, timewindow, fRange, method, params)
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
if nargin < 6 || isempty(method), method = 'wavelet'; end
if nargin < 5 || isempty(fRange), fRange = [1, 40]; end

% 确定样本信息
[C, ~, N] = size(PlotData);
labels = unique(Label); 
K = numel(labels);

% 验证时间窗
if timewindow(2) <= timewindow(1)
    error('时间窗无效: 结束时间必须大于开始时间');
end

% 设置目标分辨率
target_time_res = 0.02; % 0.02秒时间分辨率
target_freq_res = 0.5;  % 0.5Hz频率分辨率

% 默认基线窗口（刺激前）
baselineWindow = [timewindow(1), 0];
if baselineWindow(2) <= baselineWindow(1)
    baselineWindow = [timewindow(1), timewindow(1) + 0.1]; % 默认100ms基线
end

% 创建优化时间向量（控制分辨率）
time_points = timewindow(1):target_time_res:timewindow(2);
T_opt = length(time_points);
baseIdx = time_points >= baselineWindow(1) & time_points <= baselineWindow(2);
if sum(baseIdx) < 3
    baseIdx = 1:floor(T_opt*0.1); % 使用前10%作为基线
    warning('基线窗口太小，使用时间窗前10%作为基线');
end

% 设置方法参数
if strcmpi(method, 'stft')
    % STFT 参数优化
    if ~isfield(params, 'window'),   params.window   = 1/(2*target_freq_res); end % 满足频率分辨率
    if ~isfield(params, 'noverlap'), params.noverlap = 0.8; end
    if ~isfield(params, 'nfft'),     params.nfft     = 2^nextpow2(params.window*fs); end
        
elseif strcmpi(method, 'wavelet')
    % 小波参数优化
    if ~isfield(params, 'waveletName'), params.waveletName = 'morl'; end
    if ~isfield(params, 'numVoices'),   params.numVoices   = 12; end
end

% 创建优化频率向量（控制分辨率）
minFreq = max(0.5, fRange(1));
maxFreq = fRange(2);
freqs = minFreq:target_freq_res:maxFreq;
F = length(freqs);

% 预分配输出
ERSP_All = cell(K, 1);
ERSP = cell(K, 1);

% 准备小波（如果使用小波方法）
if strcmpi(method, 'wavelet')
    wavelets = cell(F, 1);
    halfLens = zeros(F, 1);
    for fi = 1:F
        nCycles = max(3, min(8, freqs(fi)/2)); % 频率相关周期数(3-8)
        sf = freqs(fi)/nCycles;
        st = 1/(2*pi*sf);
        t_wavelet = -3.5*st:1/fs:3.5*st;
        wavelet = exp(2i*pi*freqs(fi)*t_wavelet) .* exp(-t_wavelet.^2/(2*st^2));
        wavelets{fi} = wavelet / norm(wavelet);
        halfLens(fi) = floor(length(wavelet)/2);
    end
end

% 确定并行策略
useParallel = (N * C) > 100; % 总计算单元>100时启用并行

% 按类别处理
for k = 1:K
    idx = Label == labels(k);
    Nk = sum(idx);
    fprintf('处理类别 %d: %d 个试次...\n', labels(k), Nk);
    
    % 预分配类别数据
    ERSPk = zeros(F, T_opt, C, Nk);
    
    % 处理每个试次
    if useParallel
        parfor i = 1:Nk
            ERSPk(:, :, :, i) = processTrial(...
                PlotData(:, :, find(idx, i, 'first')), ...
                time_points, baseIdx, freqs, method, params, wavelets, halfLens, fs);%#ok
        end
    else
        for i = 1:Nk
            ERSPk(:, :, :, i) = processTrial(...
                PlotData(:, :, find(idx, i, 'first')), ...
                time_points, baseIdx, freqs, method, params, wavelets, halfLens, fs);
        end
    end
    
    ERSP_All{k} = ERSPk;
    ERSP{k} = mean(ERSPk, 4); % 平均所有试次
end

% 输出时间向量（毫秒）
times = time_points * 1000;
end

%% 处理单个试次的辅助函数
function trialERSP = processTrial(trialData, time_points, baseIdx, freqs, method, params, wavelets, halfLens, fs)
% 处理单个试次的所有通道
[C, T_orig] = size(trialData);
F = length(freqs);
T_opt = length(time_points);
trialERSP = zeros(F, T_opt, C);

% 原始时间向量
t_orig = linspace(time_points(1), time_points(end), T_orig);

for ch = 1:C
    sig = squeeze(trialData(ch, :));
    
    switch lower(method)
        case 'stft'
            % 高分辨率STFT
            [S, ~, t] = spectrogram(sig, hann(params.wlen), params.nov, freqs, fs);
            P = abs(S).^2;
            
            % 插值到优化时间点
            P_opt = zeros(F, T_opt);
            for fi = 1:F
                P_opt(fi, :) = interp1(t, P(fi, :), time_points, 'linear', 'extrap');
            end
            
        case 'wavelet'
            % 高效小波变换
            P_orig = zeros(F, T_orig);
            for fi = 1:F
                wavelet = wavelets{fi};
                halfLen = halfLens(fi);
                
                % 卷积计算
                convResult = conv(sig, wavelet, 'same');
                
                % 计算功率
                power = abs(convResult).^2;
                
                % 处理边缘效应
                if halfLen > 0
                    power(1:halfLen) = mean(power(halfLen+1:halfLen+min(10, ...
                        T_orig-halfLen)));
                    power(end-halfLen+1:end) = mean(power(end-halfLen-min(9, ...
                        T_orig-halfLen-1):end-halfLen));
                end
                
                P_orig(fi, :) = power;
            end
            
            % 插值到优化时间点
            P_opt = zeros(F, T_opt);
            for fi = 1:F
                P_opt(fi, :) = interp1(t_orig, P_orig(fi, :), time_points, 'linear', 'extrap');
            end
    end
    
    % 基线校正
    basePower = mean(P_opt(:, baseIdx), 2);
    basePower(basePower == 0) = eps; % 避免除以0
    ersp = 10*log10(bsxfun(@rdivide, P_opt, basePower));
    
    % 存储结果
    trialERSP(:, :, ch) = ersp;
end
end