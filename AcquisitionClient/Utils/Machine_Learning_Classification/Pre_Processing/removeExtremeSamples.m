function [cleanData, outlierIndices] = removeExtremeSamples(data, sensitivity)
% REMOVEEXTREMESAMPLES 基于样本间距离的稳健离群值检测
% 输入:
%   data - [channels × samples] 矩阵 (例如 28×71)
%   sensitivity - 敏感度参数 (0-1)，默认0.75
% 输出:
%   cleanData - 移除异常样本后的数据
%   outlierIndices - 被移除样本的索引

% 参数检查
if nargin < 2 || isempty(sensitivity)
    sensitivity = 0.75; % 默认敏感度
end

% 确保敏感度在0-1之间
sensitivity = max(0, min(1, sensitivity));

[~, numSamples] = size(data);

% 步骤1: 计算样本间相似性矩阵
% 使用稳健的相关性度量 (Kendall tau-b)
similarityMatrix = zeros(numSamples, numSamples);
for i = 1:numSamples
    for j = i:numSamples
        % 计算样本i和j之间的Kendall tau-b相关性
        tau = corr(data(:, i), data(:, j), 'type', 'kendall');
        similarityMatrix(i, j) = tau;
        similarityMatrix(j, i) = tau;
    end
end

% 步骤2: 计算每个样本的离群分数
% 基于样本间相关性的分位数分析
outlierScores = zeros(1, numSamples);

% 计算每个样本与其他样本相关性的中位数
medianCorrelations = median(similarityMatrix, 2);

% 计算相关性的分位数
Q1 = quantile(medianCorrelations, 0.25);
Q3 = quantile(medianCorrelations, 0.75);
IQR = Q3 - Q1;

% 动态设置阈值 (基于敏感度参数)
threshold = Q1 - sensitivity * IQR;

for s = 1:numSamples
    % 计算低于阈值的相关性比例
    lowCorrelationRatio = sum(similarityMatrix(s, :) < threshold) / numSamples;
    
    % 计算相关性分布偏度
    skewnessVal = skewness(similarityMatrix(s, :));
    
    % 综合离群分数 = 低相关比例 * (1 + 偏度)
    outlierScores(s) = lowCorrelationRatio * (1 + abs(skewnessVal));
end

% 步骤3: 识别离群样本
% 使用自适应阈值
scoreMed = median(outlierScores);
scoreMAD = mad(outlierScores, 1) * 1.4826;
outlierThreshold = scoreMed + 3 * scoreMAD;

% 找出离群样本
isOutlier = outlierScores > outlierThreshold;
outlierIndices = find(isOutlier);

% 步骤4: 可视化检测结果
figure('Name', '样本离群值检测分析', 'Position', [100, 100, 1200, 600]);

% 子图1: 所有样本的离群分数
subplot(1, 2, 1);
plot(outlierScores, 'o-', 'LineWidth', 1.5);
hold on;
plot(xlim, [outlierThreshold, outlierThreshold], 'r--', 'LineWidth', 2);
plot(xlim, [scoreMed, scoreMed], 'g-', 'LineWidth', 1.5);
title(sprintf('样本离群分数 (敏感度=%.2f)', sensitivity));
xlabel('样本索引');
ylabel('离群分数');
legend('样本分数', '异常阈值', '中位数', 'Location', 'best');
grid on;

% 标记离群样本
outlierScores = outlierScores(isOutlier);
outlierPos = find(isOutlier);
scatter(outlierPos, outlierScores, 100, 'r', 'filled');

% 子图2: 样本间相似性矩阵
subplot(1, 2, 2);
imagesc(similarityMatrix);
colorbar;
title('样本间相似性 (Kendall tau-b)');
xlabel('样本索引');
ylabel('样本索引');

% 标记离群样本
hold on;
for i = 1:length(outlierIndices)
    plot([0, numSamples+0.5], [outlierIndices(i), outlierIndices(i)], 'r-', 'LineWidth', 1);
    plot([outlierIndices(i), outlierIndices(i)], [0, numSamples+0.5], 'r-', 'LineWidth', 1);
end

% 步骤5: 移除离群样本
cleanData = data(:, ~isOutlier);

% 输出结果
fprintf('检测到 %d/%d 个离群样本 (%.1f%%)\n', ...
    sum(isOutlier), numSamples, 100*mean(isOutlier));
fprintf('敏感度参数: %.2f\n', sensitivity);
end