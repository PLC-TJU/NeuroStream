% Arrow Classification with CNN and Validation Split
% 1. trainArrowCNN.m: 轻量级CNN训练，带验证集划分监控过拟合
% 2. classifyArrowCNN.m: CNN分类预测
% 3. splitData.m: 数据集划分函数

%% trainArrowCNN.m
function net = trainArrowCNN_v1(X, Y)
    % 输入：
    %   X: HxWx3xN RGB图像数据
    %   Y: Nx1 标签向量或 categorical
    % 输出：
    %   net: 训练后的CNN模型

    % 1. 图像预处理：调整尺寸并归一化
    X = imresize(X, [240, 300]) / 255;
    % 转换标签为 categorical
    if ~isa(Y, 'categorical')
        Y = categorical(Y);
    end

    % 2. 划分训练集与验证集（按80%%训练，20%%验证）
    [XTrain, XVal, YTrain, YVal] = splitData(X, Y, 0.8);

    % 3. 定义网络结构
    layers = [
        imageInputLayer([240 300 3],'Name','input')
        convolution2dLayer(3,16,'Padding','same','Name','conv1')
        batchNormalizationLayer('Name','bn1')
        reluLayer('Name','relu1')
        maxPooling2dLayer(2,'Stride',2,'Name','pool1')

        convolution2dLayer(3,32,'Padding','same','Name','conv2')
        batchNormalizationLayer('Name','bn2')
        reluLayer('Name','relu2')
        maxPooling2dLayer(2,'Stride',2,'Name','pool2')

        convolution2dLayer(3,64,'Padding','same','Name','conv3')
        batchNormalizationLayer('Name','bn3')
        reluLayer('Name','relu3')
        maxPooling2dLayer(2,'Stride',2,'Name','pool3')

        fullyConnectedLayer(3,'Name','fc')
        softmaxLayer('Name','softmax')
        classificationLayer('Name','classoutput')
    ];

    % 4. 训练选项：加入验证集监控
    options = trainingOptions('adam', ...
        'MaxEpochs',20, ...               % 可根据数据量调整
        'MiniBatchSize',32, ...
        'Shuffle','every-epoch', ...
        'ValidationData',{XVal, YVal}, ...
        'ValidationFrequency',floor(numel(YTrain)/32), ...
        'Verbose',false, ...
        'Plots','training-progress');

    % 5. 训练网络
    net = trainNetwork(XTrain, YTrain, layers, options);
end