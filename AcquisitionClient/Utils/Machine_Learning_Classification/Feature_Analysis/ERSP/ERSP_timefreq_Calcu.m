function [ERSP, freqs, times, powbase, ERSP_All] = ERSP_timefreq_Calcu(PlotData, Label, passband, timewindow, fs)
% ERSP_TIMEFREQ_CALCU 计算不同类别、不同通道下每个样本的ERSP值
%   基于 EEGLAB newtimef，支持对每次试次单独计算，避免样本ERSP相同错误。
%
% 输入:
%   PlotData   - 数据矩阵，大小 [C × T × N]，C为通道数，T为时间点数，N为样本数
%   Label      - 标签向量 [N × 1]，指示每个样本类别
%   passband   - ERSP计算的频率范围 [fmin fmax]
%   timewindow - 时间范围 [startMS endMS] (s 相对于刺激)
%   fs         - 采样率 (Hz)
%
% 输出:
%   ERSP       - 元胞数组 {K×1}，K为类别数，每元胞为 [F × L × C] 的平均ERSP矩阵
%   freqs      - 频率向量 (Hz)
%   times      - 时间向量 (ms)
%   powbase    - 基线功率，元胞数组 {K×1}，K为类别数，每元胞大小为 [F × C]
%   ERSP_All   - 元胞数组 {K×1}，每元胞为 [F × L × C × Nk]，Nk为该类别样本数

if nargin < 5, fs = 250; end
[C, T, ~] = size(PlotData);
labels = unique(Label);
K = numel(labels);

% 准备输出结构
ERSP = cell(K,1);
ERSP_All = cell(K,1);
freqs = [];
times = [];
powbase = cell(K,1);

% newtimef参数
cycles = 0;    % 使用 STFT
tlimits = timewindow * 1000;  % ms
baseline = [timewindow(1)*1000, 0];
basenorm = 'off'; % 是否使用归一化基线
padratio = 4;

% 循环类别
for k = 1:K
    idx = find(Label == labels(k));
    Nk = numel(idx);
    for ch = 1:C
        % 对每个样本单独运行 newtimef
        for i = 1:Nk
            dataEpoch = squeeze(PlotData(ch, :, idx(i)));
            [ersp, ~, powb, times, freqs, ~, ~, ~] = newtimef(dataEpoch, T, tlimits, fs, cycles, ...
                'freqs', passband, 'padratio', padratio, 'plotitc','off','plotersp','off', ...
                'verbose','off', 'baseline', baseline, 'basenorm', basenorm);
            % ersp: [F×L]
            if i == 1 && ch == 1
                F = size(ersp,1);
                L = size(ersp,2);
                ERSPk = zeros(F, L, C, Nk);
                powbasek = zeros(F, C, Nk);
            end
            ERSPk(:,:,ch,i) = ersp;
            powbasek(:,ch,i) = powb(:); % [F×1] replicated later
        end
    end
    % 存储每类别结果
    ERSP_All{k} = ERSPk;
    ERSP{k} = mean(ERSPk, 4);
    powbase{k} = powbasek(:,ch,i);
end
end
