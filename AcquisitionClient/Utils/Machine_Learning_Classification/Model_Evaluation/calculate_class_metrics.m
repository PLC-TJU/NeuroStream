% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

function [precision, recall, f1] = calculate_class_metrics(predictions, trueLabels, classLabels)
    numClasses = numel(classLabels);
    precision = zeros(1, numClasses);
    recall = zeros(1, numClasses);
    f1 = zeros(1, numClasses);
    
    for i = 1:numClasses
        class = classLabels(i);
        
        % 真正例 (TP): 预测为正，实际为正
        TP = sum((predictions == class) & (trueLabels == class));
        
        % 假正例 (FP): 预测为正，实际为负
        FP = sum((predictions == class) & (trueLabels ~= class));
        
        % 假负例 (FN): 预测为负，实际为正
        FN = sum((predictions ~= class) & (trueLabels == class));
        
        % 计算指标
        precision(i) = TP / (TP + FP + eps); % 避免除以零
        recall(i) = TP / (TP + FN + eps);
        f1(i) = 2 * (precision(i) * recall(i)) / (precision(i) + recall(i) + eps);
    end
end
