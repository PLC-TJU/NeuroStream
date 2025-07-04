%% Model Evaluation
function results = ModelEvaluation(model, testdata, testlabel, classLabels)

% 测试模型
tStart = tic;
[prediction, dv, accuracy] = online_classify(model, testdata, testlabel);
testTime = toc(tStart);

% 计算其他指标
[precision, recall, f1] = calculate_class_metrics(prediction, testlabel, classLabels);

% 计算混淆矩阵
timeConfMat = confusionmat(testlabel, prediction);

% 计算AUC (二分类)
if length(classLabels) == 2
    try
        x_vals = linspace(0, 1, 1000); % 使用1000个点
        [x, y, ~, auc] = perfcurve(...
            testlabel, dv, classLabels(2), ...
            'XVals', x_vals, 'UseNearest', 'on');

        % 确保有足够的数据点
        if numel(x) < 2 || numel(y) < 2
            auc = NaN;
            rocCurves = [];
        else
            rocCurves = struct('x', x(:)', 'y', y(:)');
        end
    catch
        auc = NaN;
        rocCurves = [];
    end
else
    auc = NaN; 
    rocCurves = [];
end

% 存储当前时间点结果 (直接赋值到预分配结构体)
results.dv = dv;
results.accuracy = accuracy;
results.precision = precision;
results.recall = recall;
results.f1 = f1;
results.auc = auc;
results.rocCurves = rocCurves;
results.confusionMatrix = timeConfMat;
results.prediction = prediction;
results.testlabel = testlabel;
results.testTime = testTime;
end

