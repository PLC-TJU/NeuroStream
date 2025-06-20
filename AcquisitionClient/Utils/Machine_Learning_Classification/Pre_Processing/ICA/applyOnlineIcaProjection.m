function projectedData = applyOnlineIcaProjection(eegSegment, icaInfo)
    % 输入 eegSegment 为 [通道 x 时间点] 数据
    W = icaInfo.weights(icaInfo.brainCompIdx,:);  % 脑源成分的权重
    S = icaInfo.sphere;
    % 将新数据投影到脑源 IC 空间
    projectedData = W * (S * eegSegment);
end
