%% 计算功率谱密度（PSD），支持周期图法和Welch法
% 来源: Pan LC. 2021.3.15

function [meanPSD, f, allPSD, stdPSD] = p_psd(data, fs, freqs, nfft, method, window, outputType)
% 输入参数：
%   data: 通道×样本点数×样本数的三维矩阵
%   fs: 采样率 (Hz)
%   freqs: 输出频率范围 [fmin, fmax] (默认：[1,40] Hz)
%   nfft: DFT点数（默认：自适应选择）
%   method: 'periodogram' 或 'welch' (默认：'periodogram')
%   window: 窗函数（默认：hanning窗）
%   outputType: 输出类型参数, dB 或 linear (默认：dB)

% 输出参数：
%   meanPSD: 平均功率谱密度 [频率点数×通道]
%   f: 频率向量 [频率点数]
%   allPSD: 所有样本的PSD [频率点数×通道×样本数]
%   stdPSD: 标准差功率谱密度 [频率点数×通道]
% 注：当输出参数为空时，将输出绘制的PSD曲线图

% 参数检查与默认值设置
if nargin < 2
    error('必须提供数据和采样率');
end
if nargin < 3 || isempty(freqs)
    freqs = [1, 40];
end
if nargin < 4 || isempty(nfft)
    % 自适应选择最佳 nfft
    freq_range = freqs(2) - freqs(1);
    target_resolution = freq_range / 100; % 目标频率分辨率
    nfft = 2^ceil(log2(fs / target_resolution)); % 保证分辨率
    nfft = max(nfft, size(data,2)); % 保证 nfft ≥ 数据长度
end
if nargin < 5 || isempty(method)
    method = 'periodogram';
end
if nargin < 6 || isempty(window)
    window = hanning(size(data, 2));
end
if nargin < 7 || isempty(outputType)
    outputType = 'dB'; 
end

% 频率范围验证
nyquist = fs/2;
if freqs(2) > nyquist
    warning('频率上限超过Nyquist频率（%f Hz），自动调整为%f Hz', freqs(2), nyquist);
    freqs(2) = nyquist;
end

% 数据维度检查
[C, ~, M] = size(data);
if ndims(data) ~= 3
    error('输入数据必须为三维矩阵 (通道×样本点数×样本数)');
end

% 窗函数长度验证
% if length(window) ~= N
%     error('窗函数长度（%d）必须与样本点数（%d）一致', length(window), N);
% end

% 初始化变量
allPSD = [];
f = [];

% 主计算循环
for m = 1:M
    segment_matrix = permute(squeeze(data(:, :, m)), [2 1]);
    
    switch lower(method)
        case 'periodogram'
            [pxx, f_full] = periodogram(segment_matrix, window, nfft, fs);
            
        case 'welch'
            if isempty(nfft)
                nfft = 256;
            end
            % 计算重叠点数（50%重叠）
            overlap = floor(length(window)/2);
            [pxx, f_full] = pwelch(segment_matrix, window, overlap, nfft, fs);
            
        otherwise
            error('未知方法：%s，请选择''periodogram''或''welch''', method);
    end
    
    % 频率范围截取
    [~, idx1] = min(abs(f_full - freqs(1)));
    [~, idx2] = min(abs(f_full - freqs(2)));
    f_start = max(1, idx1);
    f_end = min(length(f_full), idx2);
    f = f_full(f_start:f_end);
    pxx = pxx(f_start:f_end, :);
    
    % 输出类型处理
    switch lower(outputType)
        case 'db'
            pxx_out = 10*log10(pxx);
        case 'linear'
            pxx_out = pxx;
        otherwise
            error('未知输出类型：%s，请选择''dB''或''linear''', outputType);
    end
    
    if m == 1
        [freq_points, ch] = size(pxx_out);%#ok
        allPSD = zeros(freq_points, C, M);
    end
    allPSD(:, :, m) = pxx_out;%#ok
end

% 计算平均/标准差 PSD
if strcmpi(outputType, 'db')
    meanPSD = squeeze(mean(10.^(allPSD/10), 3));
    meanPSD = 10*log10(meanPSD);
    stdPSD = squeeze(std(10.^(allPSD/10), 0, 3));
    stdPSD = 10*log10(stdPSD);
else
    meanPSD = squeeze(mean(allPSD, 3));
    stdPSD = squeeze(std(allPSD, 0, 3));
end

% 可选绘图
if nargout == 0
    figure;
    for ch = 1:C
        subplot(C, 1, ch);
        plot(f, meanPSD(:, ch));
        xlabel('频率 (Hz)');
        
        % 修改后的ylabel设置
        if strcmpi(outputType, 'db')
            ylabel_str = 'PSD (dB/Hz)';
        else
            ylabel_str = 'PSD (线性单位)';
        end
        ylabel(ylabel_str);
        
        title(['通道 ', num2str(ch), ' 的功率谱密度']);
        grid on;
        xlim(freqs);
    end
end
end