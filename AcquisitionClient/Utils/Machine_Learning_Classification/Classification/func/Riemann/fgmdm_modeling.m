% 黎曼分类方法
% Author: LC Pan
% Date: Jul. 1, 2024

function model = fgmdm_modeling(traindata,trainlabel,metric)
if nargin < 3 || isempty(metric)
    metric = 'riemann';
end

traincov = covariances(traindata);

labels = unique(trainlabel);
Nclass = length(labels);

% geodesic filtering
[W,Cg] = fgda(traincov,trainlabel,metric,{},'shcov',{});
traincov = geodesic_filter(traincov,Cg,W(:,1:Nclass-1));

% estimation of center
MC = cell(Nclass,1);
for i=1:Nclass
    MC{i} = mean_covariances(traincov(:,:,trainlabel==labels(i)),metric);
end

model.name = 'FgMDM';
model.metric = metric;
model.Cg = Cg;
model.W = W;
model.Nclass = Nclass;
model.MC = MC;
model.type = labels;

end