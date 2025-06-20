function [flag, out] = configureCommunication(Adress)
% configureCommunication 通信方式配置函数
%   输入:
%       Adress - 字符串或字符数组类型的通信地址
%   输出:
%       flag   - 通信方式标识 (0: 无通信, 1: 并口, 2: 串口)
%       out    - 串口对象或并口号

    % 初始化输出
    flag = 0;
    out = [];

    % 检查输入有效性（确保所有条件返回标量逻辑值）
    if nargin < 1 || isempty(Adress)
        return;
    end

    % 统一转换为字符串类型处理
    if ischar(Adress)
        Adress = string(Adress);
    end

    % 处理特殊情况：'0'表示不通信
    if Adress == "0"
        return;
    end

    % 处理串口通信：以COM开头（不区分大小写）
    if ~isempty(regexp(Adress, '^COM', 'ignorecase'))
        % 提取COM后的数字部分
        portStr = extractAfter(Adress, 'COM');
        
        % 验证数字有效性（必须是正整数）
        portNum = str2double(portStr);
        if portNum > 255
            warning('端口号超出范围: %s', Adress);
        end
        if ~isnan(portNum) && isequal(portNum, round(portNum)) && portNum > 0
            try
                out = serialport(['COM', char(portStr)], 9600);  % 创建串口对象
                flag = 2;
            catch ME
                warning(['串口初始化失败: %s', ME.message]);
            end
        else
            warning('无效串口号: %s', Adress);
        end
    % 处理并口通信：纯数字字符串且非零
    elseif all(isstrprop(char(Adress), 'digit'))
        portNum = str2double(Adress);
        
        % 验证数字有效性（必须是正整数）
        if ~isnan(portNum) && isequal(portNum, round(portNum)) && portNum > 0
            try
                config_io;  % 初始化并口
                out = portNum;  % 假设COM结构体已存在
                flag = 1;
            catch ME
                warning(['并口初始化失败: %s', ME.message]);
            end
        else
            warning('无效并口号: %s', Adress);
        end
    else
        warning('地址格式不匹配要求: %s', Adress);
    end
end
