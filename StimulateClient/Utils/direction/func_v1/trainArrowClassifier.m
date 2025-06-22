% Arrow Image Classification Using Simple Color and Position Features
% 1. Offline training: trainArrowClassifier.m
% 2. Online classification: classifyArrowImage.m

%% trainArrowClassifier.m
% 输入：
%   Xtrain: HxWx3xN 训练图像集合
%   Ytrain: Nx1 标签向量，取值 {1,2,3}
% 输出：
%   model: 训练好的分类模型结构体
function model = trainArrowClassifier(Xtrain, Ytrain)
    % 参数检查
    assert(ndims(Xtrain)==4, 'Xtrain 必须为 HxWx3xN');
    N = size(Xtrain,4);
    % 提取特征矩阵
    feats = zeros(N,4);
    for i = 1:N
        img = Xtrain(:,:,:,i);
        feats(i,:) = extractFeatures(img);
    end
    % 特征归一化
    mu = mean(feats,1);
    sigma = std(feats,[],1);
    featsNorm = (feats - mu) ./ sigma;
    % 训练多类SVM (Error-Correcting Output Codes 框架)
    t = templateSVM('KernelFunction','rbf','Standardize',false);
    Mdl = fitcecoc(featsNorm, Ytrain, 'Learners', t);
    % 保存模型及归一化参数
    model.Mdl = Mdl;
    model.mu = mu;
    model.sigma = sigma;
end



