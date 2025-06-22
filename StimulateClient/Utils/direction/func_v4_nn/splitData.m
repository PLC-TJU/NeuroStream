function [XTrain, XVal, YTrain, YVal] = splitData(X, Y, trainRatio)
    % 将数据按比例划分为训练集和验证集
    % X: HxWx3xN, Y: Nx1 categorical
    % trainRatio: 训练集比例 (0~1)

    N = size(X, 4);
    idx = randperm(N);
    nTrain = round(trainRatio * N);
    trainIdx = idx(1:nTrain);
    valIdx   = idx(nTrain+1:end);

    XTrain = X(:,:,:,trainIdx);
    XVal   = X(:,:,:,valIdx);
    YTrain = Y(trainIdx);
    YVal   = Y(valIdx);
end