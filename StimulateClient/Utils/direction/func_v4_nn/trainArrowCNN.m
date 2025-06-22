% Arrow Classification with CNN and Validation Split
% 1. trainArrowCNN.m: 轻量级CNN训练，带验证集划分监控过拟合
% 2. classifyArrowCNN.m: CNN分类预测
% 3. splitData.m: 数据集划分函数

%% trainArrowCNN.m
function net = trainArrowCNN(X, Y)
    % 轻量级CNN训练，带验证集划分、数据增强及Early Stopping
    % 输入：
    %   X: HxWx3xN RGB图像数据
    %   Y: Nx1 标签向量或 categorical
    % 输出：
    %   net: 训练后的CNN模型

    % 1. 图像预处理：调整尺寸并归一化
    X = imresize(X, [240, 300]) / 255;
    if ~isa(Y, 'categorical')
        Y = categorical(Y);
    end

    % 2. 划分训练集与验证集（按80%训练，20%验证）
    [XTrain, XVal, YTrain, YVal] = splitData(X, Y, 0.8);

    % 3. 数据增强
    augmenter = imageDataAugmenter(...
        'RandRotation',[-15,15],...
        'RandXTranslation',[-10,10],...
        'RandYTranslation',[-10,10],...
        'RandXScale',[0.9,1.1],...
        'RandYScale',[0.9,1.1]);
    augTrainDs = augmentedImageDatastore([240,300,3], XTrain, YTrain, 'DataAugmentation', augmenter);
    augValDs   = augmentedImageDatastore([240,300,3], XVal,   YVal);

    % 4. 定义网络结构，增加dropout防过拟合
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

        dropoutLayer(0.5,'Name','drop1')
        fullyConnectedLayer(3,'Name','fc')
        softmaxLayer('Name','softmax')
        classificationLayer('Name','classoutput')
    ];

    % 5. 训练选项：增加Early Stopping监控验证集
    options = trainingOptions('adam', ...
        'MaxEpochs',30, ...               % 增加Epoch
        'MiniBatchSize',32, ...
        'Shuffle','every-epoch', ...
        'ValidationData',augValDs, ...
        'ValidationFrequency',50, ...     % 每50个迭代验证一次
        'ValidationPatience',5, ...       % Early Stopping
        'Verbose',false, ...
        'Plots','training-progress');

    % 6. 训练网络
    net = trainNetwork(augTrainDs, layers, options);
end