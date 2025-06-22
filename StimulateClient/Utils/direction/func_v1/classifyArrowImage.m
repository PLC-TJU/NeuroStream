%% classifyArrowImage.m
% 输入：
%   Xtest: HxWx3xM 测试图像集合
%   model: trainArrowClassifier 输出的模型
% 输出：
%   labels: Mx1 预测标签
%   scores: Mx3 每类判别分数或概率
function [labels, scores] = classifyArrowImage(Xtest, model)
    M = size(Xtest,4);
    feats = zeros(M,4);
    for j = 1:M
        feats(j,:) = extractFeatures(Xtest(:,:,:,j));
    end
    % 归一化
    featsNorm = (feats - model.mu) ./ model.sigma;
    % 预测
    [labels, scoreMat] = predict(model.Mdl, featsNorm);
    scores = scoreMat;
end