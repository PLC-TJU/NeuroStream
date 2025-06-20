function createFeatureDiagram()
    % 创建功能示意图
    fig = figure('Position', [100, 100, 800, 600], 'Color', 'w');
    axes('Position', [0, 0, 1, 1], 'Visible', 'off');
    
    % 标题
    text(0.5, 0.95, '脑机接口系统功能架构', ...
        'FontSize', 18, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
    
    % 核心模块
    drawModule(0.2, 0.75, 0.15, 0.1, '数据采集', [0.8, 0.9, 1.0]);
    drawModule(0.5, 0.75, 0.15, 0.1, '信号处理', [0.8, 1.0, 0.9]);
    drawModule(0.8, 0.75, 0.15, 0.1, '分类引擎', [1.0, 0.9, 0.8]);
    
    % 数据采集子模块
    drawModule(0.1, 0.55, 0.12, 0.08, 'TCP通信', [0.7, 0.8, 1.0]);
    drawModule(0.3, 0.55, 0.12, 0.08, '实时缓存', [0.7, 0.8, 1.0]);
    drawModule(0.2, 0.45, 0.12, 0.08, '数据持久化', [0.7, 0.8, 1.0]);
    
    % 信号处理子模块
    drawModule(0.4, 0.55, 0.12, 0.08, '预处理', [0.7, 1.0, 0.8]);
    drawModule(0.5, 0.55, 0.12, 0.08, '特征提取', [0.7, 1.0, 0.8]);
    drawModule(0.6, 0.55, 0.12, 0.08, '标签检测', [0.7, 1.0, 0.8]);
    drawModule(0.5, 0.45, 0.12, 0.08, '时间窗提取', [0.7, 1.0, 0.8]);
    
    % 分类引擎子模块
    drawModule(0.7, 0.55, 0.12, 0.08, '模型加载', [1.0, 0.9, 0.7]);
    drawModule(0.8, 0.55, 0.12, 0.08, '实时分类', [1.0, 0.9, 0.7]);
    drawModule(0.9, 0.55, 0.12, 0.08, '结果验证', [1.0, 0.9, 0.7]);
    drawModule(0.8, 0.45, 0.12, 0.08, 'UDP通信', [1.0, 0.9, 0.7]);
    
    % 输出模块
    drawModule(0.2, 0.3, 0.15, 0.08, '数据文件', [0.9, 0.9, 0.9]);
    drawModule(0.5, 0.3, 0.15, 0.08, '状态监控', [0.9, 0.9, 0.9]);
    drawModule(0.8, 0.3, 0.15, 0.08, '设备控制', [0.9, 0.9, 0.9]);
    
    % 连接线
    drawConnection(0.2, 0.7, 0.2, 0.62);
    drawConnection(0.5, 0.7, 0.5, 0.62);
    drawConnection(0.8, 0.7, 0.8, 0.62);
    
    drawConnection(0.2, 0.52, 0.2, 0.38);
    drawConnection(0.5, 0.52, 0.5, 0.38);
    drawConnection(0.8, 0.52, 0.8, 0.38);
    
    drawConnection(0.2, 0.32, 0.2, 0.25);
    drawConnection(0.5, 0.32, 0.5, 0.25);
    drawConnection(0.8, 0.32, 0.8, 0.25);
    
    % 数据流箭头
    annotation('arrow', [0.35, 0.45], [0.75, 0.75], 'LineWidth', 1.5);
    annotation('arrow', [0.65, 0.75], [0.75, 0.75], 'LineWidth', 1.5);
    
    % 保存图像
    saveas(fig, 'feature_diagram.png');
    close(fig);
end

function drawModule(x, y, w, h, label, color)
    % 绘制功能模块
    rectangle('Position', [x-w/2, y-h/2, w, h], ...
        'Curvature', 0.1, 'FaceColor', color, ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    text(x, y, label, 'FontSize', 10, ...
        'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold');
end

function drawConnection(x1, y1, x2, y2)
    % 绘制连接线
    line([x1, x2], [y1, y2], 'Color', 'k', 'LineWidth', 1.5);
    annotation('arrow', [x2, x2], [y2-0.01, y2-0.03], 'LineWidth', 1.5);
end
