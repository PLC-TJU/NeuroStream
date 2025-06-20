% SBLEST
% Author: LC Pan
% Date: Jul. 1, 2024

function model = sblest_modeling(traindata, trainlabel, tau)
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

model.name='SBLEST';
model.tau=tau;
model.K=K;
model.type=type;
model.W=W;
model.Wh=Wh;

end