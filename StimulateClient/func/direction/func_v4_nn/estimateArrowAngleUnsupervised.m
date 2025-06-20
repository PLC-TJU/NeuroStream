%% estimateArrowAngleUnsupervised.m
function angles = estimateArrowAngleUnsupervised(X, net)
    % 无监督估计箭头朝向角度
    % 输入: net - 训练好的CNN模型
    %       X   - HxWx3xM 待测图像
    % 输出: angles - Mx1 连续角度 (0~360)

    % 1. 图像预处理
    X = imresize(X, [240,300]) / 255;
    % 2. 提取 fc 层特征
    featLayer = 'fc';
    features = activations(net, X, featLayer, 'OutputAs','rows');
    % 3. PCA 降维得到第一主成分投影
    coeff = pca(features);
    proj = features * coeff(:,1);
    % 4. 归一化投影到 [0,1]
    proj = (proj - min(proj)) / (max(proj) - min(proj));
    % 5. 映射到角度 [0,360)
    angles = proj * 360;
end