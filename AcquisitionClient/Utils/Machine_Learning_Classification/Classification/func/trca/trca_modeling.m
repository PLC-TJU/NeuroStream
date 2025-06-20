%% TRCA
function model=trca_modeling(traindata,trainlabel)
% traindata:channel*time*trial*class
type=unique(trainlabel);
for k=1:length(type)
    traindata1{k}=traindata(:,:,trainlabel==type(k));
end
m=4;
% *******TRCA********* 训练集用于TRCA找W****************************************
for x=1:length(type)
    TrainData=traindata1{x};
    [W_trca(:,:,x),D_trca]=TRCA_Matrix(TrainData);
end
% *******基于TRCA的W对TrainData降维**************
for template_class=1:length(type)
    for trials=1:size(traindata1{template_class},3)
        Train_Data_after_TRCA{template_class}(:,:,trials)=W_trca(:,1:m,template_class)'*traindata1{template_class}(:,:,trials);
    end
    Template(:,:,template_class)=mean(Train_Data_after_TRCA{template_class},3);
end

% 建模
model.name='TRCA';
model.W=W_trca(:,1:m,:);
model.Reference=real(Template);
model.type=type;

end

function [V,D] = TRCA_Matrix(X)
% X : eeg data (Num of channels * num of sample points * number of trials)

nChans  = size(X,1);
nTrials = size(X,3);
S = zeros(nChans, nChans);

for trial_i=1:nTrials
    S=S+X(:,:,trial_i)*(sum(X(:,:,trial_i+1:end),3))';
end
S2=S+S';

X1 = X(:,:);
X1 = X1 - repmat(mean(X1,2),1,size(X1,2));
Q = X1*X1';
% TRCA eigenvalue algorithm
[V_raw,D_raw] = eig(S2,Q);
eigvalue=diag(D_raw);
[D,index]=sort(eigvalue(:,1),1,'descend');
V=V_raw(:,index);
W=orth(V);
end
