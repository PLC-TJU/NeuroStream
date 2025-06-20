classdef NeuroScanClient < handle
    % NeuroScanClient 用于与 Scan4.5 脑电采集软件建立 TCP 连接，并获取未解析的
    %                 原始 EEG+标签 数据包（单位：single / int32）。
    
    % LC.Pan <panlincong@tju.edu.cn>
    % Data: 2025.5.1

    % 构造：ns = NeuroScanClient(chanNum);
    %   chanNum：通道数（含标签通道），例如 29 表示 28 个 EEG 通道 + 1 个标签通道。
    
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
        function obj = NeuroScanClient(chanNum)
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
            % 使用旧版tcpip
            try
                obj.Client = tcpip(IPAdr, PortNum, ...
                          'LocalPort', 40999, ...
                          'NetworkRole', 'client', ...
                          'InputBufferSize', (obj.ChanNum*160+12)*100 ...
                          ); %#ok
                fopen(obj.Client); % tcpip需要显式打开连接

                % 完全清空缓冲区（与第一版本一致）
                while obj.Client.BytesAvailable > 0
                    fread(obj.Client, obj.Client.BytesAvailable);
                end

            catch ME
                if ~isempty(obj.Client) && isvalid(obj.Client)
                    fclose(obj.Client);
                end
                error('无法创建 tcpclient: %s', ME.message);
            end
            
            % 发送“开始采集”命令： CTRL 0x00 0x02 0x00 0x01 0x00 0x00 0x00 0x00
            ctrlStart = uint8([67,84,82,76,0,2,0,1,0,0,0,0]);
            fwrite(obj.Client, ctrlStart, "uint8");
            pause(0.0001);
            
            % 等待并丢弃 24 字节的应答
            fread(obj.Client, 24, 'uint8');
            
            % 发送“开始获取数据”命令： CTRL 0x00 0x03 0x00 0x03 0x00 0x00 0x00 0x00
            ctrlFetch = uint8([67,84,82,76,0,3,0,3,0,0,0,0]);
            fwrite(obj.Client, ctrlFetch, 'uint8');
        end
        
        % 停止从Scan获取EEG数据
        function stopAcq(obj)
            % 发送“停止获取数据”、“停止采集”、“断开连接”命令，然后关闭 tcpclient
            if isempty(obj.Client) || ~isvalid(obj.Client)
                return;
            end
            try
                % 1. 停止获取数据： CTRL 0x00 0x03 0x00 0x04 0x00 0x00 0x00 0x00
                ctrlStopFetch = uint8([67,84,82,76,0,3,0,4,0,0,0,0]);
                fwrite(obj.Client, ctrlStopFetch, "uint8");
                pause(0.0001);
                
                % 2. 停止采集： CTRL 0x00 0x02 0x00 0x02 0x00 0x00 0x00 0x00
                ctrlStopAcq = uint8([67,84,82,76,0,2,0,2,0,0,0,0]);
                fwrite(obj.Client, ctrlStopAcq, "uint8");
                
                % 3. 断开连接： CTRL 0x00 0x01 0x00 0x02 0x00 0x00 0x00 0x00
                ctrlClose = uint8([67,84,82,76,0,1,0,2,0,0,0,0]);
                fwrite(obj.Client, ctrlClose, "uint8");
                
                % 4. 关闭tcpip连接
                fclose(obj.Client);
                delete(obj.Client);
            catch 
            end
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
                fread(obj.Client, headerSize, "uint8");
                
                % 2. 读取完整数据包体（保持原始字节流）
                rawBytes = fread(obj.Client, Channum * pointsPerPacket * bytesPerChannel, "uint8");
                
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
            % 使用旧版tcpip
            try
                obj.Client = tcpip(IPAdr, PortNum, ...
                          'LocalPort', 40999, ...
                          'NetworkRole', 'client', ...
                          'InputBufferSize', 400000, ...
                          'Timeout', 5); %#ok
                fopen(obj.Client); % tcpip需要显式打开连接

                % 完全清空缓冲区（与第一版本一致）
                while obj.Client.BytesAvailable > 0
                    fread(obj.Client, obj.Client.BytesAvailable);
                end

            catch ME
                if ~isempty(obj.Client) && isvalid(obj.Client)
                    fclose(obj.Client);
                end
                error('无法创建 tcpclient: %s', ME.message);
            end
            
            % 发送“开始采集”命令： CTRL 0x00 0x02 0x00 0x03 0x00 0x00 0x00 0x00
            ctrlStart = uint8([67,84,82,76,0,2,0,3,0,0,0,0]);
            fwrite(obj.Client, ctrlStart, "uint8");
            pause(0.0001);
            
            % 等待并丢弃 24 字节的应答
            fread(obj.Client, 24, 'uint8');
        end
        
        % 关闭Scan的Impedances视图
        function stopImp(obj)
            % 发送“停止采集”、“断开连接”命令，然后关闭 tcpclient
            if isempty(obj.Client) || ~isvalid(obj.Client)
                return;
            end
            
            try
                % 1. 停止采集： CTRL 0x00 0x02 0x00 0x02 0x00 0x00 0x00 0x00
                ctrlStopAcq = uint8([67,84,82,76,0,2,0,2,0,0,0,0]);
                fwrite(obj.Client, ctrlStopAcq, "uint8");

                % 2. 断开连接： CTRL 0x00 0x01 0x00 0x02 0x00 0x00 0x00 0x00
                ctrlClose = uint8([67,84,82,76,0,1,0,2,0,0,0,0]);
                fwrite(obj.Client, ctrlClose, "uint8");

                % 3. 关闭 tcp 对象
                fclose(obj.Client);
                delete(obj.Client);
            catch
            end
            obj.Client = [];
        end

    end
end
