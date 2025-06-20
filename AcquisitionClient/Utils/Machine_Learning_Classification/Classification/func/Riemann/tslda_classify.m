% 切空间投影分类方法
% Author: LC Pan
% Date: Jul. 1, 2024

function [prediction, decision_values, TestAcc] = tslda_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

MC = model.MC;
W = model.W;
b = model.b;
s = model.s;
type = model.type;

testcov = covariances(testdata);
Stest = Tangent_space(testcov, MC);

% 直接使用判别值作为决策值
decision_values = s * (W(:,1)' * Stest - b);
prediction = type((decision_values > 0) + 1);

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end