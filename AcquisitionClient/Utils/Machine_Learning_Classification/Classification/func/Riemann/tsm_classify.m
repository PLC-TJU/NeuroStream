% 切空间投影分类方法
% Author: LC Pan
% Date: Jul. 1, 2024

function [prediction, decision_values, TestAcc] = tsm_classify(model, testdata, testlabel)
% 切线空间模型分类函数
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

testcov = covariances(testdata);
Stest = Tangent_space(testcov, model.MC)';

% 使用训练好的分类器进行预测
switch upper(model.classifierType)
    case 'TSLDA'
        % 使用原TSLDA算法
        decision_values = model.s * (model.W(:,1)' * Stest' - model.b);
        prediction = model.type((decision_values > 0) + 1);
    case 'LIBSVM'
        [prediction, ~, decision_values] = svmpredict(zeros(size(Stest,1),1), ...
            Stest, model.classifier, '-q');
    otherwise % 'SVM', 'LDA', 'LOGISTIC'
        [prediction, scores] = predict(model.classifier, Stest);
        decision_values = scores(:,2); % 正类概率
end

% 计算准确率
if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end