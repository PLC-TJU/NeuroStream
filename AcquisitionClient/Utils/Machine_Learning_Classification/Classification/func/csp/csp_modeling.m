% 共空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2021.5.1

function model = csp_modeling(traindata, trainlabel, nFilters, classifierType, optimize, timeLimit)
if ~exist('nFilters','var') || isempty(nFilters)
    nFilters = 4;
end
if ~exist('classifierType','var') || isempty(classifierType)
    classifierType = 'SVM';
end
if ~exist('optimize','var') || isempty(optimize)
    optimize = false;
end
if ~exist('timeLimit','var') || isempty(timeLimit)
    timeLimit = 30;
end

type = unique(trainlabel);
xTrain0 = traindata(:,:,trainlabel == type(1));
xTrain1 = traindata(:,:,trainlabel == type(2));

% 计算协方差矩阵
Sigma0 = mean_covariances(covariances(xTrain0), 'arithmetic');
Sigma1 = mean_covariances(covariances(xTrain1), 'arithmetic');

% 解决特征分解问题
[d, v] = eig(pinv(Sigma1) * Sigma0);
[~, ids] = sort(diag(v), 'descend');
W = d(:, ids([1:nFilters, end-nFilters+1:end]));

% 提取特征
trainfea = zeros(size(traindata,3), size(W,2));
for i = 1:size(traindata,3)
    cov_i = W' * traindata(:,:,i) * traindata(:,:,i)' * W;
    trainfea(i,:) = log10(diag(cov_i) / trace(cov_i));
end

% 使用内置分类器
classifier = train_classifier(trainfea, trainlabel, classifierType, ...
        optimize, timeLimit);

model.name = 'CSP';
model.W = W;
model.classifierType = classifierType;
model.classifier = classifier;
model.optimized = optimize;
model.timeLimit = timeLimit;
model.nFilters = nFilters;
model.type = type;
end