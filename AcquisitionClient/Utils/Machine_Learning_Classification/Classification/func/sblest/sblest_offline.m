% 集成train和test步骤，适用于离线运行
function testlabel = sblest_offline(traindata, trainlabel, testdata, tau)
% Initialization
if ~exist('tau','var') || isempty(tau)
    tau = 1;
end

if tau == 0
    K = 1;
else
    K = 2;
end

type = unique(trainlabel);
label = zeros(length(trainlabel),1);
label(trainlabel==type(1)) = -1;
label(trainlabel==type(2)) =  1;

% Training stage: run SBLEST on the training set
Xtrain = Augmented_data(traindata, K, tau);
[W, ~, ~, Wh] = SBLEST(Xtrain, label);

% Test stage : predicte labels in the test set
Xtest = Augmented_data(testdata, K, tau);
R_test = Enhanced_cov(Xtest, Wh);

predict_Y = R_test*W(:);
predict_Y = sign(predict_Y);

testlabel = zeros(length(predict_Y),1);
testlabel(predict_Y==-1 | predict_Y==0) = type(1);
testlabel(predict_Y== 1) = type(2);

end