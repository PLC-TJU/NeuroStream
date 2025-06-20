%% DCPM分类
function [prediction, decision_values, TestAcc] = dcpm_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

U = model.U;
tmp_1 = model.tmp_1;
tmp_0 = model.tmp_0;
type = model.type;

rr = zeros(size(testdata,3), 5);
for n = 1:size(testdata,3)
    test = squeeze(testdata(:,:,n))';
    test = test - repmat(mean(test), size(test,1), 1);
    TestData = test * U;
    
    rr(n,1) = corr2(tmp_1, TestData) - corr2(tmp_0, TestData);
    rr(n,2) = mean(diag(cov(tmp_0 - TestData)) - diag(cov(tmp_1 - TestData)));
    [A_1, B_1, r_1] = canoncorr(tmp_1, TestData);
    [A_0, B_0, r_0] = canoncorr(tmp_0, TestData);
    rr(n,3) = mean(r_1) - mean(r_0);
    rr(n,4) = corr2(tmp_1*A_1, TestData*A_1) - corr2(tmp_0*A_0, TestData*A_0);
    rr(n,5) = corr2(tmp_1*B_1, TestData*B_1) - corr2(tmp_0*B_0, TestData*B_0);
end

decision_values = mean(rr, 2);
prediction = zeros(size(testdata,3),1);
prediction(decision_values <= 0) = type(1);
prediction(decision_values > 0) = type(2);

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end