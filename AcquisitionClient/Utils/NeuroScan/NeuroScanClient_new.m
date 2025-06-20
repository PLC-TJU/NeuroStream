classdef NeuroScanClient_new < handle
    % NeuroScanClient 用于与 Scan4.5 脑电采集软件建立 TCP 连接，
    % 并获取未解析的原始 EEG+标签 数据包（单位：single / int32）。
    %
    % 构造：ns = NeuroScanClient(chanNum);
    %   chanNum：通道数（含标签通道），例如 29 表示 28 个 EEG 通道 + 1 个标签通道。
    %
    % 方法：
    %   startAcq(IPAdr, PortNum)   - 打开 tcpclient 并发送开始采集/获取命令
    %   [obj, rawData] = getData() - 读取所有完整数据包并解析为 [chanNum × (40×N)] 大小的矩阵
    %   stopAcq()                  - 发送停止指令并断开连接
    
    properties
        Client      % tcpclient 对象
        ChanNum     % 包含标签通道在内的通道总数
        LabelFlag   % 用于标签上下沿检测的标志，两元素向量，Flag = [isHigh; lastLabelValue]
    end
    
    methods
        function obj = NeuroScanClient_new(chanNum)
            if nargin < 1
                error('必须指定通道数 ChanNum');
            end
            obj.ChanNum   = chanNum;
            obj.LabelFlag = [0; 0];  % [当前是否高电平; 保存上一个标签值]
            obj.Client    = [];
        end
        
        % 开启从Scan获取EEG数据
        function startAcq(obj, IPAdr, PortNum)
            % 使用 tcpclient 建立到 Scan 软件的连接，并发送“开始采集” + “开始获取数据”命令
            if nargin < 3 || isempty(PortNum)
                PortNum = 4000;
            end
            % 1. 创建 tcpclient（Matlab R2019b 及以上）
            try
                obj.Client = tcpclient(IPAdr, PortNum, 'Timeout', 1);
            catch ME
                error('无法创建 tcpclient: %s', ME.message);
            end
            
            % 2. 清空缓冲区
            while obj.Client.BytesAvailable > 0
                read(obj.Client, obj.Client.BytesAvailable);
            end
            
            % 3. 发送“开始采集”命令： CTRL 0x00 0x02 0x00 0x01 0x00 0x00 0x00 0x00
            ctrlStart = uint8([67,84,82,76,0,2,0,1,0,0,0,0]);
            write(obj.Client, ctrlStart, "uint8");
            pause(0.0001);
            
            % 4. 等待并丢弃 24 字节的应答
            read(obj.Client, 24, "uint8");
            
            % 5. 发送“开始获取数据”命令： CTRL 0x00 0x03 0x00 0x03 0x00 0x00 0x00 0x00
            ctrlFetch = uint8([67,84,82,76,0,3,0,3,0,0,0,0]);
            write(obj.Client, ctrlFetch, "uint8");
        end
        
        % 停止从Scan获取EEG数据
        function stopAcq(obj)
            % 发送“停止获取数据”、“停止采集”、“断开连接”命令，然后关闭 tcpclient
            if isempty(obj.Client) || ~isvalid(obj.Client)
                return;
            end
            
            % 1. 停止获取数据： CTRL 0x00 0x03 0x00 0x04 0x00 0x00 0x00 0x00
            ctrlStopFetch = uint8([67,84,82,76,0,3,0,4,0,0,0,0]);
            write(obj.Client, ctrlStopFetch, "uint8");
            pause(0.0001);
            
            % 2. 停止采集： CTRL 0x00 0x02 0x00 0x02 0x00 0x00 0x00 0x00
            ctrlStopAcq = uint8([67,84,82,76,0,2,0,2,0,0,0,0]);
            write(obj.Client, ctrlStopAcq, "uint8");
            
            % 3. 断开连接： CTRL 0x00 0x01 0x00 0x02 0x00 0x00 0x00 0x00
            ctrlClose = uint8([67,84,82,76,0,1,0,2,0,0,0,0]);
            write(obj.Client, ctrlClose, "uint8");
            
            % 4. 清理 tcpclient 对象
            clear obj.Client
            obj.Client = [];
        end
        
        function tempData = getData(obj)
            % getData 读取所有可用完整数据包，并解析为 [ChanNum × (40×N)] 矩阵
            %
            % 若当前可读字节 < 一个完整包大小，则返回 tempData = []。
            %
            % 每个包格式：
            %  12 字节包头（跳过） +
            %  ChanNum × 40 × 4 字节（每个通道 40 个样本，每个样本 4 字节）
            
            if isempty(obj.Client) || ~isvalid(obj.Client)
                tempData = [];
                return;
            end
            
            Channum         = obj.ChanNum;
            bytesPerChannel = 4;
            headerSize      = 12;
            pointsPerPacket = 40;
            bytesPerPacket  = headerSize + Channum * pointsPerPacket * bytesPerChannel;
            
            % 计算可用数据包数量
            availBytes = obj.Client.BytesAvailable;
            packetCount = floor(availBytes / bytesPerPacket);
            
            if packetCount == 0
                tempData = [];
                return;
            end
            
            % 预分配输出
            tempData = zeros(Channum, pointsPerPacket * packetCount);
            
            for pkt = 1:packetCount
                % 1. 读并丢弃包头
                read(obj.Client, headerSize, "uint8");
                
                % 2. 读取完整数据包体（保持原始字节流）
                rawBytes = read(obj.Client, Channum * pointsPerPacket * bytesPerChannel, "uint8");
                
                % 3. 重构为 [(Channum×4) × pointsPerPacket] 的矩阵
                reshapedData = reshape(rawBytes, Channum * bytesPerChannel, []);
                
                % 4. EEG 通道数据（前 Channum-1 通道），32bit 整数转 double，再乘以物理常数
                eegBytes = reshapedData(1:(Channum-1)*bytesPerChannel, :);
                eegInt32 = typecast(uint8(eegBytes(:)), 'int32');
                eegMatrix = reshape(eegInt32, Channum-1, pointsPerPacket);
                
                eegMatrix = double(eegMatrix) * 0.0298;% 物理量转换（0.298μV/LSB）
                
                % 5. 标签通道（第 Channum 通道），取每个点的第 1 字节
                labelBytes = reshapedData(Channum*bytesPerChannel - 3, :);
                labelChannel = zeros(1, pointsPerPacket);

                % 标签检测逻辑
                for j = 1:pointsPerPacket
                    currLabel = labelBytes(j);
                    if currLabel ~= 0
                        if obj.LabelFlag(1) == 0
                            % 上升沿
                            obj.LabelFlag(1) = 1;
                            obj.LabelFlag(2) = currLabel;
                            labelChannel(j) = currLabel;
                        elseif obj.LabelFlag(2) == currLabel
                            % 重复标签，置 0
                            labelChannel(j) = 0;
                        end
                    else
                        if obj.LabelFlag(1) == 1
                            % 下降沿
                            obj.LabelFlag(1) = 0;
                        end
                        labelChannel(j) = 0;
                    end
                end
                
                % 6. 拼成 [Channum × pointsPerPacket]
                packetMatrix = [eegMatrix; labelChannel];
                
                % 7. 放到 tempData 中
                startIdx = (pkt-1)*pointsPerPacket + 1;
                endIdx   = pkt*pointsPerPacket;
                tempData(:, startIdx:endIdx) = packetMatrix;
            end
        end
        
        % 打开Scan的Impedances视图
        function startImp(obj, IPAdr, PortNum)
            % 使用 tcpclient 建立到 Scan 软件的连接，并发送“开始采集” 命令
            if nargin < 3 || isempty(PortNum)
                PortNum = 4000;
            end
            % 1. 创建 tcpclient
            try
                obj.Client = tcpclient(IPAdr, PortNum, 'Timeout', 1);
            catch ME
                error('无法创建 tcpclient: %s', ME.message);
            end
            
            % 2. 清空缓冲区
            flush(obj.Client)
            
            % 3. 发送“开始采集”命令： CTRL 0x00 0x02 0x00 0x03 0x00 0x00 0x00 0x00
            ctrlStart = uint8([67,84,82,76,0,2,0,3,0,0,0,0]);
            write(obj.Client, ctrlStart, "uint8");
            pause(0.0001);
            
            % 4. 等待并丢弃 24 字节的应答
            read(obj.Client, 24, "uint8");
        end
        
        % 关闭Scan的Impedances视图
        function stopImp(obj)
            % 发送“停止采集”、“断开连接”命令，然后关闭 tcpclient
            if isempty(obj.Client) || ~isvalid(obj.Client)
                return;
            end
                        
            % 1. 停止采集： CTRL 0x00 0x02 0x00 0x02 0x00 0x00 0x00 0x00
            ctrlStopAcq = uint8([67,84,82,76,0,2,0,2,0,0,0,0]);
            write(obj.Client, ctrlStopAcq, "uint8");
            pause(0.0001);
            
            % 2. 断开连接： CTRL 0x00 0x01 0x00 0x02 0x00 0x00 0x00 0x00
            ctrlClose = uint8([67,84,82,76,0,1,0,2,0,0,0,0]);
            write(obj.Client, ctrlClose, "uint8");
            
            % 4. 清理 tcpclient 对象
            clear obj.Client
            obj.Client = [];
        end

    end
end
