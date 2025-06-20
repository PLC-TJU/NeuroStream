%% 辅助函数: 降采样处理
function dataOut = resampleData(dataIn, origFs, newFs)
% 降采样三维数据 (通道 × 时间点 × 试次)
[nChannels, nTimes, nTrials] = size(dataIn);
dataOut = zeros(nChannels, round(nTimes * newFs / origFs), nTrials);

for ch = 1:nChannels
    for tr = 1:nTrials
        % 对每个通道和试次单独降采样
        chData = squeeze(dataIn(ch, :, tr));
        resampled = resample(chData, newFs, origFs);
        dataOut(ch, :, tr) = resampled;
    end
end
end