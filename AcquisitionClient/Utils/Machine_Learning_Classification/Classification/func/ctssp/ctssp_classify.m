% 共时-频-空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.5.1
% Lincong Pan, et al. CTSSP: A Temporal-Spectral-Spatio Joint Optimization 
% Algorithm for Motor Imagery EEG Decoding. TechRxiv. April 10, 2025.

function [prediction, decision_values, TestAcc] = ctssp_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel = [];
end

t_win = model.t_win;
tau = model.tau;
type = model.type;
W = model.W;
Wh = model.Wh;
classifierType=model.classifierType;

if ismatrix(testdata)
    testdata = reshape(testdata, size(testdata,1), size(testdata,2), 1);
end

% 特征提取
[Covtest, ~] = p_enhanced_cov(testdata, t_win, tau, Wh);
Rtest = get_vector(Covtest);

% 分类
switch upper(classifierType)
    case {'SVM','LDA','LOGISTIC'}
        features=zeros(size(Rtest,1),size(model.V,2));
        for i = 1:size(Rtest,1)
            sample_mat = reshape(Rtest(i,:), sqrt(size(Rtest,2)), []);
            features(i,:) = diag(model.V'*sample_mat*model.V);
        end
        [prediction, scores] = predict(model.classifier, features);
        decision_values = scores(:,2); % 正类概率
    otherwise
        decision_values = Rtest * W(:);
        prediction = zeros(length(decision_values),1);
        prediction(decision_values <= 0) = type(1);
        prediction(decision_values > 0) = type(2);
end

if ~isempty(testlabel)
    TestAcc = mean(prediction == testlabel) * 100;
else
    TestAcc = [];
end
end