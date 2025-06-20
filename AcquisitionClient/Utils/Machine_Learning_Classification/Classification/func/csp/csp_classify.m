% 共空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2021.5.1

function [prediction, decision_values, TestAcc] = csp_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

W = model.W;
classifierType = model.classifierType;
classifier = model.classifier;

testcov = zeros(size(W,2), size(W,2), size(testdata,3));
testfea = zeros(size(testdata,3), size(W,2));
for i = 1:size(testdata,3)
    testcov(:,:,i) = W' * testdata(:,:,i) * testdata(:,:,i)' * W;
    testfea(i,:) = log10(diag(testcov(:,:,i)) / trace(testcov(:,:,i)));
end

switch upper(classifierType)
    case 'LIBSVM'
        [prediction, ~, decision_values] = libsvmpredict(zeros(size(testfea,1),1), ...
            testfea, classifier, '-q');
    otherwise % 'SVM', 'LDA', 'LOGISTIC'
        [prediction, scores] = predict(classifier, testfea);
        decision_values = scores(:,2); % 正类概率
end

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end
