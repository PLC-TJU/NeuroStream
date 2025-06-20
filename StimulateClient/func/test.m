% 获取所有显示器的位置信息（逻辑像素，已考虑系统缩放）
monitorPositions = get(0, 'MonitorPositions');

% 计算每个显示器的坐标范围
numMonitors = size(monitorPositions, 1);
displayInfo = cell(numMonitors, 1);

for i = 1:numMonitors
    % 提取当前显示器参数
    x = monitorPositions(i, 1);
    y = monitorPositions(i, 2);
    width = monitorPositions(i, 3);
    height = monitorPositions(i, 4);
    
    % 计算坐标范围 [x_min, x_max] 和 [y_min, y_max]
    xRange = [x, x + width - 1];
    yRange = [y, y + height - 1];
    
    % 存储结果
    displayInfo{i} = struct(...
        'MonitorNumber', i, ...
        'Position', [x, y, width, height], ...  % [x, y, width, height]
        'XRange', xRange, ...                   % [x_min, x_max]
        'YRange', yRange ...                    % [y_min, y_max]
    );
end

% 显示结果
fprintf('检测到 %d 个显示器:\n', numMonitors);
for i = 1:numMonitors
    info = displayInfo{i};
    fprintf('【显示器 %d】\n', i);
    fprintf('  位置坐标: [x=%d, y=%d]\n', info.Position(1), info.Position(2));
    fprintf('  尺寸: %d×%d 像素\n', info.Position(3), info.Position(4));
    fprintf('  X区间: [%d, %d]\n', info.XRange(1), info.XRange(2));
    fprintf('  Y区间: [%d, %d]\n\n', info.YRange(1), info.YRange(2));
end