% Arrow Image Classification Using Robust Segmentation and Orientation Features
% 1. Offline training: trainArrowClassifier.m
% 2. Online classification & angle estimation: classifyArrowImage.m

%% trainArrowClassifier.m
% 输入：
%   Xtrain: HxWx3xN   训练图像集合
%   Ytrain: Nx1       标签向量，取值 {1,2,3}
% 输出：
%   model:            训练好的分类模型结构体
function model = trainArrowClassifier(Xtrain, Ytrain)
    assert(ndims(Xtrain)==4, 'Xtrain 必须为 HxWx3xN');
    N = size(Xtrain,4);
    feats = zeros(N,7);
    for i = 1:N
        img = Xtrain(:,:,:,i);
        feats(i,:) = extractFeatures(img);
    end
    % 特征归一化
    mu = mean(feats,1);
    sigma = std(feats,[],1);
    featsNorm = (feats - mu) ./ sigma;
    % 训练多类SVM
    t = templateSVM('KernelFunction','rbf','Standardize',false);
    Mdl = fitcecoc(featsNorm, Ytrain, 'Learners', t);
    model.Mdl = Mdl;
    model.mu = mu;
    model.sigma = sigma;
end


