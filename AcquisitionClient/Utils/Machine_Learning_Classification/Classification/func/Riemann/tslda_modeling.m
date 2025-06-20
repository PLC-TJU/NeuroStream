% 切空间投影分类方法
% Author: LC Pan
% Date: Jul. 1, 2024

function model = tslda_modeling(traindata,trainlabel)

method_mean = 'riemann';
traincov = covariances(traindata);

labels = unique(trainlabel);
Nclass = length(labels);

% Tangent space mapping
MC = mean_covariances(traincov,method_mean);
Strain = Tangent_space(traincov,MC);
Nelec = size(Strain,1);

% Regularized LDA
mu = zeros(Nelec,Nclass);
Covclass = zeros(Nelec,Nelec,Nclass);

for i=1:Nclass
    mu(:,i) = mean(Strain(:,trainlabel==labels(i)),2);
    Covclass(:,:,i) = covariances(Strain(:,trainlabel==labels(i)),'shcovft');
end

mutot = mean(mu,2);

Sb = zeros(Nelec,Nelec);
for i=1:Nclass
    Sb = Sb+(mu(:,i) - mutot)*(mu(:,i)-mutot)';
end

S = mean(Covclass,3);

[W, Lambda] = eig(Sb,S);
[~, Index] = sort(diag(Lambda),'descend');

W = W(:,Index(1));
b = W(:,1)'*mutot;

s = sign(W(:,1)'*mu(:,2)-b);

model.name = 'TSLDA';
model.MC = MC;
model.W = W;
model.b = b;
model.s = s;
model.type = labels;

end