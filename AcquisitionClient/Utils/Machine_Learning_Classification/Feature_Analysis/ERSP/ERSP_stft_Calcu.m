function [ERSP_All, freqs, times] = ERSP_stft_Calcu(PlotData, Label, fs, baselineWindow, stftParams)
% ERSP_STFT_CALCU 使用 STFT 计算各类别各样本各通道的 ERSP
% 输入:
%   PlotData       - [C × T × N] 数据矩阵，C 通道数，T 时间点数，N 样本数
%   Label          - [N × 1] 样本类别标签
%   fs             - 采样率 (Hz)\%   baselineWindow - [t0 t1] 基线时间窗 (秒，相对于数据起点)
%   stftParams     - 结构体, 包含 STFT 参数:
%       .window    - STFT 窗口长度 (样本)
%       .noverlap  - STFT 窗口重叠 (样本)
%       .nfft      - FFT 点数
%
% 输出:
%   ERSP_All       - 元胞数组 {K×1}, K 类别数，每元胞大小 [F × L × C × Nk]
%   freqs          - 频率向量 (Hz)
%   times          - 时间向量 (秒)

% 参数检查
if nargin < 5 || isempty(stftParams)
    stftParams.window   = round(0.5 * fs);   % 0.5s 窗口
    stftParams.noverlap = round(0.4 * fs);   % 80% 重叠
    stftParams.nfft     = max(256, 2^nextpow2(stftParams.window));
end
[C, ~, ~] = size(PlotData);
labels = unique(Label);
K = numel(labels);
% 计算 STFT 范围并预分配
% 使用第一个通道第一个样本计算 freqs 和 times
[~, times, freqs] = stft(double(PlotData(1,:,1)), fs, ...
    'Window', hann(stftParams.window), ...
    'OverlapLength', stftParams.noverlap, ...
    'FFTLength', stftParams.nfft);
F = length(freqs);
L = length(times);

% 找到基线区间索引
tIdx = times >= baselineWindow(1) & times <= baselineWindow(2);

% 初始化输出
ERSP_All = cell(K,1);
for k = 1:K
    idx = find(Label == labels(k));
    Nk = numel(idx);
    ERSPk = zeros(F, L, C, Nk);
    for ch = 1:C
        for i = 1:Nk
            sig = double(PlotData(ch,:,idx(i)));
            % 计算 STFT
            [S, ~, ~] = stft(sig, fs, ...
                'Window', hann(stftParams.window), ...
                'OverlapLength', stftParams.noverlap, ...
                'FFTLength', stftParams.nfft);
            P = abs(S).^2; % 功率谱
            % 基线功率 (对每频率平均基线时段)
            Pbase = mean(P(:, tIdx), 2);
            % ERSP: 10*log10(P ./ Pbase)
            ERSPk(:,:,ch,i) = 10*log10(bsxfun(@rdivide, P, Pbase));
        end
    end
    ERSP_All{k} = ERSPk;
end
end
