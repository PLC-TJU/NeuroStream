function [X_reduced, selectedChannels] = selectEEGChannels(X, y, params, flag)
% EEG通道筛选函数：结合平坦通道去除和CSP通道选择
% 输入：
%   X - EEG数据 (n_channels × n_times × n_trials)
%   y - 类别标签 (n_trials × 1)
%   params - 参数结构体（可选）
%       .nelec     : 要选择的通道数 (默认16)
%       .metric    : 距离度量 ('euclid'或'riemann', 默认'euclid') *未完成，待完善*
%       .varThresh : 平坦通道方差阈值 (默认1e-6)
% 输出：
%   X_reduced        - 筛选后的EEG数据
%   selectedChannels - 最终选中的通道索引

% 参数设置
if nargin < 4 || isempty(flag)
    flag = true;
end
if nargin < 3 || isempty(params)
    params = struct();
end
if ~isfield(params, 'nelec'), params.nelec = 16; end
if ~isfield(params, 'metric'), params.metric = 'euclid'; end
if ~isfield(params, 'varThresh'), params.varThresh = 1e-6; end

if ~flag
    X_reduced = X;
    selectedChannels = 1:size(X,1);
    return;
end

% 1. 去除平坦通道
[n_channels, n_times, n_trials] = size(X);
channel_vars = zeros(1, n_channels);

% 计算每个通道的平均方差
for i = 1:n_channels
    channel_data = squeeze(X(i, :, :)); % 提取单个通道数据
    trial_vars = var(channel_data, 0, 1); % 计算每个trial的方差
    channel_vars(i) = mean(trial_vars);   % 计算平均方差
end

% 找出非平坦通道
nonFlatIdx = find(channel_vars > params.varThresh);
if isempty(nonFlatIdx)
    error('所有通道都被识别为平坦通道，请检查数据或调整阈值');
end
X_nonFlat = X(nonFlatIdx, :, :);

% 2. CSP通道选择
% 准备协方差矩阵计算
n_nonFlat = length(nonFlatIdx);
Cov = zeros(n_nonFlat, n_nonFlat, n_trials);

% 计算每个trial的协方差矩阵
for i = 1:n_trials
    trial_data = squeeze(X_nonFlat(:, :, i));
    trial_data = trial_data - mean(trial_data, 2); % 去除均值
    Cov(:, :, i) = (trial_data * trial_data') / (n_times - 1);
end

% 获取类别信息
classes = unique(y);
n_classes = length(classes);

if n_classes < 2
    error('通道选择需要至少两个类别');
end

% 计算每个类别的平均协方差
classCov = zeros(n_nonFlat, n_nonFlat, n_classes);
for k = 1:n_classes
    classIdx = (y == classes(k));
    classCov(:, :, k) = mean(Cov(:, :, classIdx), 3); % 欧几里得平均
end

% 二分类情况下的CSP通道选择
if n_classes == 2
    C1 = squeeze(classCov(:, :, 1));
    C2 = squeeze(classCov(:, :, 1));
    
    % 广义特征分解
    [~, D] = eig(C2, C1 + C2);
    evals = diag(D);
    
    % 按区分能力排序
    [~, idx] = sort(abs(evals - 0.5), 'descend');
    CSPIdx = idx(1:min(params.nelec, length(idx)));
    
% 多分类情况（简化实现）
else
    % 计算总体协方差
    totalCov = squeeze(mean(classCov, 3));
    
    % 计算每个通道的区分度得分
    channelScores = zeros(1, n_nonFlat);
    for ch = 1:n_nonFlat
        classVars = zeros(1, n_classes);
        for k = 1:n_classes
            covMat = squeeze(classCov(:, :, k));
            classVars(k) = covMat(ch, ch);
        end
        % 使用方差差异作为区分度指标
        channelScores(ch) = max(classVars) - min(classVars);
    end
    
    % 选择区分度最高的通道
    [~, sortedIdx] = sort(channelScores, 'descend');
    CSPIdx = sortedIdx(1:min(params.nelec, length(sortedIdx)));
end

% 3. 组合结果
selectedInNonFlat = CSPIdx;
selectedChannels = nonFlatIdx(selectedInNonFlat);
X_reduced = X_nonFlat(selectedInNonFlat, :, :);

% 显示筛选结果
fprintf('通道筛选完成：\n');
fprintf('原始通道数: %d, 非平坦通道: %d, 最终选择: %d\n', ...
        n_channels, length(nonFlatIdx), length(selectedChannels));
end