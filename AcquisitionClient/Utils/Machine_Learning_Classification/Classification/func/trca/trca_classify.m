%% TRCA分类（仅用于二分类）
function [prediction, decision_values, TestAcc] = trca_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

W_trca = model.W;
Reference = model.Reference;
type = model.type;

Devalue = zeros(size(testdata,3), size(W_trca,3));
for trials = 1:size(testdata,3)
    for Wtrca_index = 1:size(W_trca,3)
        Devalue(trials, Wtrca_index) = corr2(real((testdata(:,:,trials)' * ...
            W_trca(:,:,Wtrca_index))'), squeeze(Reference(:,:,Wtrca_index)));
    end
end

% 计算决策值（类别2的相关系数 - 类别1的相关系数）
decision_values = Devalue(:,2) - Devalue(:,1); % 假设二分类
prediction = zeros(size(testdata,3),1);
prediction(decision_values <= 0) = type(1);
prediction(decision_values > 0) = type(2);

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end