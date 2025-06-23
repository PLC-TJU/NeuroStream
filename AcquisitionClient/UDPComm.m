classdef UDPComm < handle
    % UDPComm 封装了采集端电脑 <—> 反馈端电脑之间的 UDP 双向通信逻辑
    % LC.Pan <panlincong@tju.edu.cn>
    % Data: 2025.5.1

    % 本类功能：
    %     1. 建立本地 UDP 端口（udpport），并发送 0xFF01(连接请求)
    %     2. 接收远端 ACK，通过回调 processAckFcn 处理
    %     3. 启动超时定时器，若无 ACK 则调用 timeoutFcn
    %     4. 提供 sendData 方法可随时发送数据给远端
    %     5. 停止连接时，发送 0xFF00(断开通知)，并清理资源

    % 使用示例：
    %   uc = UDPComm();
    %   uc.start('192.168.1.20', 9094, 9095, @app.processAck, @app.checkConnectionTimeout);
    %   if uc.IsConnected, uc.sendData(uint8([1,2,3])); end
    %   uc.stop();
    
    properties
        UdpObj              % udpport 对象
        ConnectionTimer     % 用于检测连接超时的 timer 对象
        IsConnected = false % 通信连接与否建立完成的标志
    end
    
    methods
        function start(obj, remoteHost, remotePort, localPort)
            % start 建立本地 UDP 端口，并发送连接请求(0xFF02)
            %   remoteHost   - 远程端 IP
            %   remotePort   - 远程端 监听端口
            %   localPort    - 本地端 监听端口
            
            % 确保先清理旧资源
            obj.cleanup();

            try
                % 1. 创建 udpport 对象
                obj.UdpObj = udpport("IPV4", ...
                    "LocalPort", localPort, ...
                    "Timeout", 1);
                
                % 2. 设置远端主机/端口
                obj.UdpObj.RemoteHost = remoteHost;
                obj.UdpObj.RemotePort = remotePort;
                
                % 3. 配置“收到 2 字节”时触发回调
                configureCallback(obj.UdpObj, "byte", 4, @(src,~) obj.processUDPData(src));
                
                % 4. 发送连接请求
                write(obj.UdpObj, uint8([255,1,0,0]), "uint8", remoteHost, remotePort);
                
                % 5. 启动 2 秒超时检测
                obj.ConnectionTimer = timer(...
                    'TimerFcn', @(~,~) obj.checkConnectionTimeout(), ...
                    'StartDelay', 2, ...
                    'ExecutionMode', 'singleShot');
                start(obj.ConnectionTimer);
                
            catch ME
                % 若任一步失败，则清理资源并抛错
                obj.cleanup();
                error('UDP 启动失败: %s', ME.message);
            end
        end
        
        % 处理<接收数据>响应
        function processUDPData(obj, src)
            % 停止超时定时器
            if ~isempty(obj.ConnectionTimer) && isvalid(obj.ConnectionTimer)
                stop(obj.ConnectionTimer);
                delete(obj.ConnectionTimer);
            end
            
            try
                % 读取2字节数据
                data = read(src, 4, "uint8");  
    
                % 协议处理
                switch data(1)
                    case 255  % 控制指令
                        obj.handleControlCommand(data(2));
                        
                    case 254  % 数据包
                        obj.handleDataPacket(data(2));
                end
            catch ME
                warning(['数据处理错误: %s', ME.message]);
            end

        end
        
        % 处理控制指令
        function handleControlCommand(obj, command)
            switch command
                case 0  % 收到断开通知
                    obj.IsConnected = false;
                    disp('收到远程端的断开连接通知');

                case 1  % 收到连接请求
                    % 发送连接确认[255, 2]
                    write(app.udp_ctrl, uint8([255,2,0,0]), "uint8", ...
                        app.udp_ctrl.RemoteIP, app.udp_ctrl.RemotePort);
                    disp('收到连接请求，已发送确认');

                case 2 % 收到连接确认
                    disp('远程端连接成功');
                    obj.IsConnected = true;

                case 3 % 其它可能添加的功能

                    
                otherwise
                    warning('未知控制指令: %d', command);
            end
        end
        
        % 处理数据包
        function handleDataPacket(obj, value)  %#ok <*UNUSEDP>
            % 此处撰写收到反馈数据后的处理程序
            % 在此处执行反馈操控指令
        end

        % 连接超时
        function checkConnectionTimeout(obj)
            % 如果超时仍未收到 ACK，则认定连接失败
            if ~isempty(obj.UdpObj) && ~obj.IsConnected
                warning('UDP 连接超时');
                obj.cleanup();
            end
        end

        % 发送数据包
        function sendData(obj, dataBytes)
            % sendData 向远端发送原始字节流
            %   dataBytes: uint8 数组
            if isempty(obj.UdpObj) || ~isvalid(obj.UdpObj)
                error('UDP 未连接或已关闭');
            end

            % 构建数据包：[254,~,~,分类结果]
            try
                packet = uint8([254, dataBytes]);
                write(obj.UdpObj, packet, "uint8", ...
                    obj.UdpObj.RemoteHost, obj.UdpObj.RemotePort);
            catch ME
                warning(['发送数据失败: %s', ME.message]);
            end
        end
        
        function stop(obj)
            % stop 发送断开通知(0xFF00)，并清理全部资源
            if ~isempty(obj.UdpObj) && isvalid(obj.UdpObj)
                try
                    write(obj.UdpObj, uint8([255,0,0,0]), "uint8", ...
                        obj.UdpObj.RemoteHost, obj.UdpObj.RemotePort);
                    pause(0.05);
                catch
                    % 忽略发送失败
                end
            end
            obj.cleanup();
        end
        
        function cleanup(obj)
            % cleanup 强制清理，删除所有对象资源
            
            % 清理定时器
            try
                if ~isempty(obj.ConnectionTimer) && isvalid(obj.ConnectionTimer)
                    stop(obj.ConnectionTimer);
                    delete(obj.ConnectionTimer);
                end
            catch
            end

            % 清理UDP对象
            try
                if ~isempty(obj.UdpObj) && isvalid(obj.UdpObj)
                    configureCallback(obj.UdpObj, "off");% 关闭回调
                    pause(0.5);
                    clear obj.UdpObj;
                    obj.UdpObj = [];
                end
            catch
            end

            % 重置状态
            obj.IsConnected = false;
        end
    end
end