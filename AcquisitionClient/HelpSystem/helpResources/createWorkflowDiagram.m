function createWorkflowDiagram()
    % 创建工作流程图
    fig = figure('Position', [100, 100, 1000, 700], 'Color', 'w');
    axes('Position', [0, 0, 1, 1], 'Visible', 'off');
    
    % 标题
    text(0.5, 0.95, '脑机接口系统工作流程', ...
        'FontSize', 18, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
    
    % 流程步骤
    steps = {
        '开始实验'
        '建立TCP连接'
        '启动数据采集'
        '接收实时数据'
        '更新环形缓存'
        '检测事件标签'
        '提取时间窗数据'
        '特征提取与处理'
        '执行分类'
        '发送UDP结果'
        '更新状态显示'
        '保存数据文件'
        '结束实验'
    };
    
    % 步骤位置
    y_pos = linspace(0.85, 0.15, length(steps));
    
    % 绘制流程步骤
    for i = 1:length(steps)
        % 绘制步骤框
        rectangle('Position', [0.4, y_pos(i)-0.03, 0.2, 0.05], ...
            'Curvature', 0.2, 'FaceColor', [0.8, 0.9, 1.0], ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
        
        % 添加步骤文本
        text(0.5, y_pos(i), steps{i}, 'FontSize', 11, ...
            'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold');
        
        % 添加步骤编号
        text(0.35, y_pos(i), ['Step ' num2str(i)], 'FontSize', 10, ...
            'HorizontalAlignment', 'right');
    end
    
    % 绘制连接箭头
    for i = 1:length(steps)-1
        annotation('arrow', [0.5, 0.5], [y_pos(i)-0.03, y_pos(i+1)+0.03], ...
            'LineWidth', 1.5, 'HeadWidth', 10, 'HeadLength', 10);
    end
    
    % 添加分支点 (标签检测后)
    branch_y = y_pos(6);
    annotation('arrow', [0.5, 0.7], [branch_y, branch_y], ...
        'LineWidth', 1.5, 'HeadWidth', 10, 'HeadLength', 10);
    
    % 添加分支说明
    text(0.75, branch_y-0.01, '检测到标签?', 'FontSize', 10, ...
        'HorizontalAlignment', 'center');
    
    % 是分支
    rectangle('Position', [0.7, branch_y-0.05, 0.1, 0.03], ...
        'Curvature', 0.2, 'FaceColor', [0.8, 1.0, 0.8], ...
        'EdgeColor', 'k', 'LineWidth', 1);
    text(0.75, branch_y-0.05, '是', 'FontSize', 10, ...
        'HorizontalAlignment', 'center');
    
    % 否分支
    annotation('arrow', [0.7, 0.5], [branch_y-0.05, branch_y-0.08], ...
        'LineWidth', 1.5, 'HeadWidth', 10, 'HeadLength', 10);
    rectangle('Position', [0.4, branch_y-0.10, 0.1, 0.03], ...
        'Curvature', 0.2, 'FaceColor', [1.0, 0.8, 0.8], ...
        'EdgeColor', 'k', 'LineWidth', 1);
    text(0.45, branch_y-0.10, '否', 'FontSize', 10, ...
        'HorizontalAlignment', 'center');
    
    % 添加图例
    legend_x = 0.1;
    legend_y = 0.1;
    
    rectangle('Position', [legend_x, legend_y, 0.15, 0.05], ...
        'Curvature', 0.2, 'FaceColor', [0.8, 0.9, 1.0], ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    text(legend_x+0.075, legend_y+0.025, '处理步骤', 'FontSize', 10, ...
        'HorizontalAlignment', 'center');
    
    rectangle('Position', [legend_x, legend_y-0.07, 0.15, 0.03], ...
        'Curvature', 0.2, 'FaceColor', [0.8, 1.0, 0.8], ...
        'EdgeColor', 'k', 'LineWidth', 1);
    text(legend_x+0.075, legend_y-0.055, '条件分支(是)', 'FontSize', 9, ...
        'HorizontalAlignment', 'center');
    
    rectangle('Position', [legend_x, legend_y-0.12, 0.15, 0.03], ...
        'Curvature', 0.2, 'FaceColor', [1.0, 0.8, 0.8], ...
        'EdgeColor', 'k', 'LineWidth', 1);
    text(legend_x+0.075, legend_y-0.105, '条件分支(否)', 'FontSize', 9, ...
        'HorizontalAlignment', 'center');
    
    % 保存图像
    saveas(fig, 'workflow_diagram.png');
    close(fig);
end
