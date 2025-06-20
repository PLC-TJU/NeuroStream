%LC.Pan 2025.6.1 (tcpclient)
function [DataBuf, tempData] = EEGGetData_new(TCPHandle, DataBuf)
    % 参数配置
    Channum = DataBuf.ChanNum;
    bytesPerChannel = 4;
    headerSize = 12;
    pointsPerPacket = 40;
    
    % 计算可用数据包数量
    bytesPerPacket = headerSize + Channum * pointsPerPacket * bytesPerChannel;
    availableBytes = TCPHandle.BytesAvailable;
    packetCount = floor(availableBytes / bytesPerPacket);
    
    if packetCount == 0
        tempData = [];
        return;
    end

    % 预分配输出矩阵
    tempData = zeros(Channum, pointsPerPacket * packetCount);

    for i = 1:packetCount
        % 读取包头
        read(TCPHandle, headerSize, "uint8");
        
        % 读取完整数据包体（保持原始字节流）
        rawPacket = read(TCPHandle, Channum*pointsPerPacket*bytesPerChannel, 'uint8');
        
        % 重构为[通道字节数 × 时间点]矩阵
        reshapedData = reshape(rawPacket, Channum*bytesPerChannel, []);
        
        % 转换前N-1通道数据
        eegBytes = reshapedData(1:(Channum-1)*bytesPerChannel, :);
        eegInt32 = typecast(uint8(eegBytes(:)), 'int32');
        eegMatrix = reshape(eegInt32, Channum-1, pointsPerPacket);
        
        % 物理量转换
        eegMatrix = double(eegMatrix) * 0.0298;
        
        % 提取标签通道原始字节（每个时间点的第4个通道的第1个字节）
        labelBytes = reshapedData(Channum*bytesPerChannel-3, :); % 索引修正
        
        % 初始化标签通道
        labelChannel = zeros(1, pointsPerPacket);
        
        % 标签检测逻辑
        for j = 1:pointsPerPacket
            currentLabel = labelBytes(j);
            
            if currentLabel ~= 0
                if DataBuf.Flag(1) == 0
                    % 上升沿检测
                    DataBuf.Flag(1) = 1;
                    DataBuf.Flag(2) = currentLabel;
                    labelChannel(j) = currentLabel;
                elseif DataBuf.Flag(2) == currentLabel
                    % 重复标签抑制
                    labelChannel(j) = 0;
                end
            else
                if DataBuf.Flag(1) == 1
                    % 下降沿检测
                    DataBuf.Flag(1) = 0;
                end
                labelChannel(j) = 0;
            end
        end

        % 组装完整数据包
        packetMatrix = [eegMatrix; labelChannel];
        
        % 写入输出缓冲区
        startIdx = (i-1)*pointsPerPacket + 1;
        endIdx = i*pointsPerPacket;
        tempData(:, startIdx:endIdx) = packetMatrix;
    end
end