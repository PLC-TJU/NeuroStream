% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

function text = formatSummaryText(results)
    text = sprintf('模型评估结果汇总:\n\n');
    text = [text, sprintf('算法: %s\n', results.algorithm)];
    text = [text, sprintf('评估模式: %s\n', results.evaluationType)];
    
    if strcmp(results.evaluationType, '迁移模型')
        text = [text, sprintf('源域样本数: %d\n', results.sourceSamples)];
        text = [text, sprintf('目标域样本数: %d\n', results.targetSamples)];
    else
        text = [text, sprintf('总样本数: %d\n', results.totalSamples)];
    end
    
    % 添加类别信息
    if isfield(results, 'classLabels')
        text = [text, sprintf('类别标签: %s\n', mat2str(results.classLabels'))];
    end
    
    % 添加时间点指标
    text = [text, sprintf('\n时间点评估结果:\n')];
    for tIdx = 1:min(3, numel(results.timePoints)) % 最多显示前3个时间点
        tp = results.timePoints(tIdx);
        sum = tp.summary;
        
        text = [text, sprintf('\n时间点 %.1fs:\n', tp.feedbackTime)];
        text = [text, sprintf('  - 准确率: %.2f%% ± %.2f\n', sum.accuracy.mean, sum.accuracy.std)];
        text = [text, sprintf('  - 宏精确率: %.2f%% ± %.2f\n', sum.macroPrecision.mean, sum.macroPrecision.std)];
        text = [text, sprintf('  - 宏召回率: %.2f%% ± %.2f\n', sum.macroRecall.mean, sum.macroRecall.std)];
        text = [text, sprintf('  - 宏F1: %.2f%% ± %.2f\n', sum.macroF1.mean, sum.macroF1.std)];
        
        if ~isnan(sum.auc.mean)
            text = [text, sprintf('  - AUC: %.3f ± %.3f\n', sum.auc.mean, sum.auc.std)];
        end
        
        if ~isnan(sum.kappa)
            text = [text, sprintf('  - Kappa: %.3f\n', sum.kappa)];
        end
        
        text = [text, sprintf('  - G-Mean: %.2f%% ± %.2f\n', sum.gmean.mean, sum.gmean.std)];
        text = [text, sprintf('  - 训练时间: %.3fs ± %.3f\n', sum.trainTime.mean, sum.trainTime.std)];
    end
    
    % 添加类别级别指标 (示例显示第一个时间点的第一个类别)
    if isfield(results, 'timePoints') && ~isempty(results.timePoints) && ...
       isfield(results.timePoints(1).summary, 'classMetrics') && ...
       ~isempty(results.timePoints(1).summary.classMetrics)
        
        text = [text, sprintf('\n类别级别指标 (时间点 %.1fs):\n', results.timePoints(1).feedbackTime)];
        for cls = 1:min(3, numel(results.timePoints(1).summary.classMetrics)) % 最多显示前3个类别
            metrics = results.timePoints(1).summary.classMetrics(cls);
            text = [text, sprintf('  类别 %d: 精确率=%.2f%%±%.2f, 召回率=%.2f%%±%.2f, F1=%.2f%%±%.2f\n', ...
                cls, ...
                metrics.precision.mean, metrics.precision.std, ...
                metrics.recall.mean, metrics.recall.std, ...
                metrics.f1.mean, metrics.f1.std)];
        end
    end
end