%% classifyArrowImage.m
% 输入：
%   Xtest: HxWx3xM 测试图像集合
%   model: trainArrowClassifier 输出的模型
% 输出：
%   labels: Mx1       预测标签
%   scores: Mx3       每类判别分数
%   angles: Mx1       估计箭头与水平轴夹角（度，-90~+90）
function [labels, scores, angles] = classifyArrowImage(Xtest, model)
    M = size(Xtest,4);
    feats = zeros(M,4);
    angles = zeros(M,1);
    for j = 1:M
        img = Xtest(:,:,:,j);
        [feat, ang] = extractFeatures(img);
        feats(j,:) = feat;
        angles(j) = ang;
    end
    featsNorm = (feats - model.mu) ./ model.sigma;
    [labels, scoreMat] = predict(model.Mdl, featsNorm);
    scores = scoreMat;
end

