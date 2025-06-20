% 黎曼分类方法
% Author: LC Pan
% Date: Jul. 1, 2024

function [prediction, decision_values, TestAcc] = fgmdm_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

method_dist = 'riemann';
Cg = model.Cg;
W = model.W;
Nclass = model.Nclass;
MC = model.MC;
type = model.type;

testcov = covariances(testdata);
testcov = geodesic_filter(testcov, Cg, W(:,1:Nclass-1));

% classification
d = zeros(size(testcov,3), Nclass);
for j = 1:size(testcov,3)
    for i = 1:Nclass
        d(j,i) = distance(testcov(:,:,j), MC{i}, method_dist);
    end
end

% 转换为决策值（二分类）
[~, min_idx] = min(d, [], 2);
prediction = type(min_idx);

% 计算决策值（类别1的距离 - 类别2的距离）
decision_values = d(:,1) - d(:,2); % 假设二分类，类型为[1,2]

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end