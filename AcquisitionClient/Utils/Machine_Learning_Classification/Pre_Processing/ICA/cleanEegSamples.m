function [cleanEEG, removedInfo, icaInfo] = cleanEegSamples(EEG, window)
% cleanEegSamples - 清洗连续 EEG 数据，去除伪迹成分及高噪声试次

% 输入:
%   EEG    - 连续 EEG 数据结构体，由 pop_loadcnt 加载 (EEGLAB 格式)
%   window - 试次的时间窗口 (默认 [0, 4] 秒)

% 输出:
%   cleanEEG    - 清洗后的连续 EEG 数据结构体
%   removedInfo - 表格，记录被剔除试次的事件编号、类型、RMS、马氏距离、伪迹标记
%   icaInfo     - 结构体，包含 ICA 投影矩阵和保留的脑源成分信息

% 方法:
%   (1) 确定每个试次的样本区间: [eventLatency+window(1)*srate : +window(2)*srate]
%   (2) 运行 ICA 分解与ICLabel 分类，剔除伪迹成分并重构信号
%   (3) 计算每个试次的数据段:
%       - RMS 幅值: sqrt(mean(data(:).^2))
%       - 通道方差向量
%   (4) 计算 RMS 和马氏距离的阈值: 均值 + 3*标准差
%   (5) 若任一指标超阈值，则标记该试次为坏试次
%   (6) 从 EEG 数据连续流中剔除坏试次的时间窗，更新 EEG 数据和事件结构

% 设置默认窗口
if nargin < 2
    window = [0, 4];
end
srate = EEG.srate;
winSamples   = round(diff(window) * srate);
startOffset  = round(window(1) * srate);

% 确保有通道位置，以支持 ICLabel
if ~isfield(EEG, 'chanlocs') || isempty({EEG.chanlocs.labels})
    error('EEG.chanlocs 未提供，请确保已加载通道位置信息以支持 ICLabel 分类。');
end

% --------------------------- ICA 分解 + ICLabel ---------------------------
EEG = pop_runica(EEG, 'icatype', 'runica');    % ICA 分解
EEG = iclabel(EEG);                            % ICLabel 分类

% 获取分类概率矩阵 comps×classes
ICprob = EEG.etc.ic_classification.ICLabel.classifications;
if size(ICprob,1) ~= size(EEG.icaweights,1)
    error('ICLabel 输出维度与 ICA 成分数量不匹配');
end
% 保留脑源成分: 选择 Brain 类别概率 > 0.5
brainICs = find(ICprob(:,1) > 0.5);
artifactICs = setdiff(1:size(ICprob,1), brainICs);

% 保存 ICA 信息
icaInfo.weights      = EEG.icaweights;
icaInfo.sphere       = EEG.icasphere;
icaInfo.brainCompIdx = brainICs;
icaInfo.ICprob       = ICprob;

% 从数据中剔除伪迹 IC
EEG = pop_subcomp(EEG, artifactICs, 0);

% ----------------------- 提取试次 & 质量指标 -----------------------
latencies = round([EEG.event.latency]);   % 原始事件样本索引
types     = {EEG.event.type}';            % 事件类型
nEvents   = numel(latencies);

RMSvals = nan(nEvents,1);
varMat  = nan(nEvents, EEG.nbchan);
for i = 1:nEvents
    st = latencies(i) + startOffset;
    ed = st + winSamples - 1;
    if st>=1 && ed <= size(EEG.data,2)
        seg = EEG.data(:, st:ed);
        RMSvals(i)   = sqrt(mean(seg(:).^2));
        varMat(i,:)  = var(seg,0,2)';
    end
end

% 计算阈值
thrRMS = mean(RMSvals,'omitnan') + 3*std(RMSvals,'omitnan');
muVar  = mean(varMat,1,'omitnan');
covVar = cov(varMat,'omitrows');
if rank(covVar) < size(covVar,1)
    covVar = covVar + eye(size(covVar))*1e-10;
end
MDvals = nan(nEvents,1);
for i = 1:nEvents
    if ~any(isnan(varMat(i,:)))
        d = varMat(i,:) - muVar;
        MDvals(i) = sqrt(d*(covVar\d'));
    end
end
thrMD = mean(MDvals,'omitnan') + 3*std(MDvals,'omitnan');

% 标记待剔除试次
badIdx = find(RMSvals>thrRMS | MDvals>thrMD);
if isempty(badIdx)
    warning('未检测到异常试次');
    cleanEEG    = EEG;
    removedInfo = table([],[],[],[],[], 'VariableNames', ...
        {'EventIndex','Type','RMS','Mahalanobis','ICAArtifact'});
    return;
end

% 记录删除信息（使用原始事件编号）
removedInfo = table(...
    badIdx, types(badIdx), RMSvals(badIdx), MDvals(badIdx), ...
    false(numel(badIdx),1), ...
    'VariableNames', {'EventIndex','Type','RMS','Mahalanobis','ICAArtifact'});

% ----------------------- 剔除坏试次数据段 -----------------------
remSegs = zeros(numel(badIdx),2);
for k = 1:numel(badIdx)
    i = badIdx(k);
    st = latencies(i) + startOffset;
    ed = st + winSamples - 1;
    remSegs(k,:) = [st, ed];
end
EEG = eeg_eegrej(EEG, remSegs);
cleanEEG = EEG;
end
