function YPred = classifyArrowCNN(XTest, net)
    % 输入：
    %   net: 训练好的CNN模型
    %   XTest: HxWx3xM 待测图像
    % 输出：
    %   YPred: Mx1 分类标签 (categorical)

    % 测试图像预处理
    XTest = imresize(XTest, [240, 300]) / 255;
    % 预测
    YPred = classify(net, XTest);
    % 转换为数值数组
    YPred = double(YPred);
end
