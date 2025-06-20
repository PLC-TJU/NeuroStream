%% 汇总各个评估指标
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

% 宏级别指标(所有折叠的平均结果)：
% -准确率 (accuracy)
% -宏平均精确率 (macroPrecision)
% -宏平均召回率 (macroRecall)
% -宏平均 F1 (macroF1)
% -G-Mean
% -AUC
% -Kappa 系数
% -训练时间

% 类别级别指标：
% -每个类别的精确率
% -每个类别的召回率
% -每个类别的 F1 分数
function summary = calculate_timepoint_summary(timeResults)
    % 初始化汇总结构
    summary = struct();
    
    % 提取当前时间点的所有折叠结果
    accuracy = timeResults.accuracy;
    precision = timeResults.precision;  % 确保precision被提取
    recall = timeResults.recall;
    f1 = timeResults.f1;
    auc = timeResults.auc;
    trainTime = timeResults.trainTime;
    
    % 计算Kappa系数 (基于当前时间点的混淆矩阵)
    confMat = timeResults.confusionMatrix;
    if ~isempty(confMat) && sum(confMat(:)) > 0
        n = sum(confMat(:)); % 总样本数
        po = sum(diag(confMat)) / n; % 观察一致性
        pe = sum(sum(confMat, 1) .* sum(confMat, 2)) / n^2; % 期望一致性
        kappa = (po - pe) / (1 - pe);
    else
        kappa = NaN;
    end
    
    % 计算宏平均召回率 (G-Mean)
    % 先计算每个折叠的G-Mean
    gmeanPerFold = zeros(size(recall, 1), 1);
    for fold = 1:size(recall, 1)
        gmeanPerFold(fold) = exp(mean(log(recall(fold, :) + eps)));
    end
    
    % 计算平衡准确率 (每个折叠的宏平均召回率)
    balancedAccPerFold = mean(recall, 2);
    
    % 计算宏平均精确率 (每个折叠的宏平均精确率)
    macroPrecisionPerFold = mean(precision, 2);
    
    % 计算宏平均F1 (每个折叠的宏平均F1)
    macroF1PerFold = mean(f1, 2);
    
    % === 计算汇总统计 (当前时间点) ===
    % 准确率
    summary.accuracy = struct(...
        'mean', mean(accuracy), ...
        'std', std(accuracy));
    
    % Kappa系数
    summary.kappa = kappa;
    
    % AUC
    auc = auc(~isnan(auc));
    if ~isempty(auc)
        summary.auc = struct(...
            'mean', mean(auc), ...
            'std', std(auc));
    else
        summary.auc = struct( ...
            'mean', NaN, ...
            'std', NaN);
    end
    
    % 训练时间
    summary.trainTime = struct(...
        'mean', mean(trainTime), ...
        'std', std(trainTime));
    
    % 宏平均精确率
    summary.macroPrecision = struct(...
        'mean', mean(macroPrecisionPerFold) * 100, ...
        'std', std(macroPrecisionPerFold) * 100);
    
    % 宏平均召回率
    summary.macroRecall = struct(...
        'mean', mean(balancedAccPerFold) * 100, ...
        'std', std(balancedAccPerFold) * 100);
    
    % 宏平均F1
    summary.macroF1 = struct(...
        'mean', mean(macroF1PerFold) * 100, ...
        'std', std(macroF1PerFold) * 100);
    
    % G-Mean
    summary.gmean = struct(...
        'mean', mean(gmeanPerFold) * 100, ...
        'std', std(gmeanPerFold) * 100);
    
    % 类别级别指标
    classMetrics = struct();
    for cls = 1:size(f1, 2)
        classMetrics(cls).precision = struct(...
            'mean', mean(precision(:, cls)) * 100, ...
            'std', std(precision(:, cls)) * 100);
        
        classMetrics(cls).recall = struct(...
            'mean', mean(recall(:, cls)) * 100, ...
            'std', std(recall(:, cls)) * 100);
        
        classMetrics(cls).f1 = struct(...
            'mean', mean(f1(:, cls)) * 100, ...
            'std', std(f1(:, cls)) * 100);
    end
    summary.classMetrics = classMetrics;
    
    % ROC曲线数据标记
    summary.includeROC = ~isempty(timeResults.rocCurves) && ...
        ~isempty(timeResults.rocCurves{1});
end