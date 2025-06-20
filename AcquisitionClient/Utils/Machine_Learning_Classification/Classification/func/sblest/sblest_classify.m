% SBLEST
% Author: LC Pan
% Date: Jul. 1, 2024

function [prediction, decision_values, TestAcc] = sblest_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

tau = model.tau;
K = model.K;
type = model.type;
W = model.W;
Wh = model.Wh;

if ismatrix(testdata)
    testdata = reshape(testdata, size(testdata,1), size(testdata,2), 1);
end

Xtest = Augmented_data(testdata, K, tau);
R_test = Enhanced_cov(Xtest, Wh);

decision_values = R_test * W(:);
prediction = zeros(length(decision_values),1);
prediction(decision_values <= 0) = type(1);
prediction(decision_values > 0) = type(2);

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end