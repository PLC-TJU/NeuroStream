% 切空间投影分类方法
% Author: LC Pan
% Date: Jul. 1, 2024

function model = tsm_modeling(traindata, trainlabel, metric, classifierType, optimize, timeLimit)
% 切线空间模型训练函数
if ~exist('metric','var') || isempty(metric)
    metric = 'riemann';
end
if ~exist('classifierType','var') || isempty(classifierType)
    classifierType = 'LOGISTIC';
end
if ~exist('optimize','var') || isempty(optimize)
    optimize = false;
end
if ~exist('timeLimit','var') || isempty(timeLimit)
    timeLimit = 30;
end

traincov = covariances(traindata);

% 切线空间映射
MC = mean_covariances(traincov, metric);
Strain = Tangent_space(traincov, MC)';

% 特殊处理：当选择TSLDA时使用原算法
if strcmpi(classifierType, 'TSLDA')
    % 使用原TSLDA算法
    labels = unique(trainlabel);
    Nclass = length(labels);
    Nelec = size(Strain,2);
    
    mu = zeros(Nelec, Nclass);
    Covclass = zeros(Nelec, Nelec, Nclass);
    
    for i = 1:Nclass
        class_idx = (trainlabel == labels(i));
        mu(:, i) = mean(Strain(class_idx, :))';
        Covclass(:, :, i) = covariances(Strain(class_idx, :)', 'shcovft');
    end
    
    mutot = mean(mu, 2);
    Sb = zeros(Nelec, Nelec);
    for i = 1:Nclass
        Sb = Sb + (mu(:, i) - mutot) * (mu(:, i) - mutot)';
    end
    
    S = mean(Covclass, 3);
    [W, Lambda] = eig(Sb, S);
    [~, Index] = sort(diag(Lambda), 'descend');
    W = W(:, Index(1));
    b = W' * mutot;
    s = sign(W' * mu(:, 2) - b);
    
    model.name = 'TSM';
    model.MC = MC;
    model.W = W;
    model.b = b;
    model.s = s;
    model.classifierType = 'TSLDA';
    model.type = labels;
    return;
end

% 对于其他分类器使用标准实现
classifier = train_classifier(Strain, trainlabel, classifierType, ...
        optimize, timeLimit);

model.name = 'TSM';
model.metric = metric;
model.MC = MC;
model.classifier = classifier;
model.classifierType = classifierType;
model.optimized = optimize;
model.timeLimit = timeLimit;
model.type = unique(trainlabel);
end