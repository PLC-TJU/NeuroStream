function createAboutDialog()
    % 创建关于对话框
    aboutFig = uifigure('Name', '关于脑机接口在线识别与反馈系统', ...
        'Position', [100, 100, 700, 650], ...
        'WindowStyle','alwaysontop',...%置顶
        'Color', [1, 1, 1], ...
        'Icon','app_icon_2.png');
    
    % 主网格布局 - 4行1列
    mainGrid = uigridlayout(aboutFig, [4, 1]);
    mainGrid.RowHeight = {'fit', 'fit', '1x', 'fit'};
    mainGrid.RowSpacing = 10;
    mainGrid.BackgroundColor = [1, 1, 1];
    mainGrid.Padding = [15, 15, 15, 15];
    
    % ================== 标题区域 ==================
    titlePanel = uipanel(mainGrid);
    titlePanel.Layout.Row = 1;
    titlePanel.BackgroundColor = [0.2, 0.4, 0.8]; % 深蓝色背景
    
    titleGrid = uigridlayout(titlePanel, [1, 1]);
    titleGrid.Padding = [10, 15, 10, 15];
    titleGrid.BackgroundColor = [0.2, 0.4, 0.8];
    
    titleLabel = uilabel(titleGrid);
    titleLabel.Text = '脑机接口在线识别与反馈系统 (NeuroStream)';
    titleLabel.FontSize = 26;
    titleLabel.FontWeight = 'bold';
    titleLabel.FontColor = [1, 1, 1]; % 白色文字
    titleLabel.HorizontalAlignment = 'center';
    titleLabel.VerticalAlignment = 'center';
    
    % ================== 信息区域 ==================
    infoPanel = uipanel(mainGrid);
    infoPanel.Layout.Row = 2;
    infoPanel.BackgroundColor = [1, 1, 1];
    
    infoGrid = uigridlayout(infoPanel, [4, 2]);
    infoGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    infoGrid.ColumnWidth = {'fit', '1x'};
    infoGrid.RowSpacing = 8;
    infoGrid.ColumnSpacing = 15;
    infoGrid.Padding = [20, 15, 20, 15];
    
    % 版本信息
    versionLabel1 = uilabel(infoGrid);
    versionLabel1.Text = '版本:';
    versionLabel1.FontSize = 14;
    versionLabel1.FontWeight = 'bold';
    versionLabel1.FontColor = [0.3, 0.3, 0.3];
    versionLabel1.Layout.Row = 1;
    versionLabel1.Layout.Column = 1;
    versionLabel1.HorizontalAlignment = 'left';
    
    versionLabel2 = uilabel(infoGrid);
    versionLabel2.Text = 'v1.3';
    versionLabel2.FontSize = 14;
    versionLabel2.FontColor = [0.1, 0.1, 0.1];
    versionLabel2.Layout.Row = 1;
    versionLabel2.Layout.Column = 2;
    
    % 开发者信息
    devLabel1 = uilabel(infoGrid);
    devLabel1.Text = '开发者:';
    devLabel1.FontSize = 14;
    devLabel1.FontWeight = 'bold';
    devLabel1.FontColor = [0.3, 0.3, 0.3];
    devLabel1.Layout.Row = 2;
    devLabel1.Layout.Column = 1;
    devLabel1.HorizontalAlignment = 'left';
    
    devLabel2 = uilabel(infoGrid);
    devLabel2.Text = 'Lincong Pan';
    devLabel2.FontSize = 14;
    devLabel2.FontColor = [0.1, 0.1, 0.1];
    devLabel2.Layout.Row = 2;
    devLabel2.Layout.Column = 2;
    
    % 机构信息
    orgLabel1 = uilabel(infoGrid);
    orgLabel1.Text = '机构:';
    orgLabel1.FontSize = 14;
    orgLabel1.FontWeight = 'bold';
    orgLabel1.FontColor = [0.3, 0.3, 0.3];
    orgLabel1.Layout.Row = 3;
    orgLabel1.Layout.Column = 1;
    orgLabel1.HorizontalAlignment = 'left';
    
    orgLabel2 = uilabel(infoGrid);
    orgLabel2.Text = '神经工程实验室 | 天津大学';
    orgLabel2.FontSize = 14;
    orgLabel2.FontColor = [0.1, 0.1, 0.1];
    orgLabel2.Layout.Row = 3;
    orgLabel2.Layout.Column = 2;
    
    % 发布日期
    dateLabel1 = uilabel(infoGrid);
    dateLabel1.Text = '发布日期:';
    dateLabel1.FontSize = 14;
    dateLabel1.FontWeight = 'bold';
    dateLabel1.FontColor = [0.3, 0.3, 0.3];
    dateLabel1.Layout.Row = 4;
    dateLabel1.Layout.Column = 1;
    dateLabel1.HorizontalAlignment = 'left';
    
    dateLabel2 = uilabel(infoGrid);
    %dateLabel2.Text = datestr(now, 'yyyy年mm月dd日');
    dateLabel2.Text = datestr(now, '2025年6月21日');
    dateLabel2.FontSize = 14;
    dateLabel2.FontColor = [0.1, 0.1, 0.1];
    dateLabel2.Layout.Row = 4;
    dateLabel2.Layout.Column = 2;
    
    % ================== 功能区域 ==================
    featuresPanel = uipanel(mainGrid);
    featuresPanel.Layout.Row = 3;
    featuresPanel.BackgroundColor = [1, 1, 1];
    
    featuresGrid = uigridlayout(featuresPanel, [2, 1]);
    featuresGrid.RowHeight = {'fit', '1x'};
    featuresGrid.RowSpacing = 10;
    featuresGrid.Padding = [10, 10, 10, 10];
    
    % 功能标题
    featuresTitle = uilabel(featuresGrid);
    featuresTitle.Text = '系统功能';
    featuresTitle.FontSize = 16;
    featuresTitle.FontWeight = 'bold';
    featuresTitle.FontColor = [0.2, 0.2, 0.6];
    featuresTitle.HorizontalAlignment = 'center';
    featuresTitle.Layout.Row = 1;
    featuresTitle.Layout.Column = 1;
    
    % 功能列表网格 - 使用嵌套网格确保正确布局
    featuresListGrid = uigridlayout(featuresGrid, [4, 2]);
    featuresListGrid.RowHeight = repmat({'1x'}, 1, 4);
    featuresListGrid.ColumnWidth = repmat({'1x'}, 1, 2);
    featuresListGrid.RowSpacing = 12;
    featuresListGrid.ColumnSpacing = 15;
    featuresListGrid.Padding = [15, 10, 15, 10];
    featuresListGrid.Layout.Row = 2;
    featuresListGrid.Layout.Column = 1;
    featuresListGrid.BackgroundColor = [0.95, 0.95, 0.97];
    
    % 功能列表
    featuresList = {
        '多通道脑电信号实时采集', [0.92, 0.96, 1.00];  % 浅蓝色
        '跨设备UDP双向通信',     [0.92, 1.00, 0.96];  % 浅绿色
        '信号预处理与特征提取',   [1.00, 0.98, 0.92];  % 浅黄色
        '机器学习分类器集成',     [1.00, 0.92, 0.92];  % 浅红色
        '特征可视化与参数优化',   [0.96, 0.92, 1.00];  % 浅紫色
        '数据缓存与持久化存储',   [0.96, 1.00, 1.00];  % 浅青色
        '实时状态监控与日志',     [1.00, 0.96, 0.92];  % 浅橙色
        '参数配置管理系统',       [0.94, 0.94, 0.94];  % 浅灰色
    };
  
    for i = 1:size(featuresList, 1)
        row = ceil(i/2);
        col = mod(i-1, 2) + 1;
        
        % 创建功能卡片容器
        cardGrid = uigridlayout(featuresListGrid, [1, 1]);
        cardGrid.BackgroundColor = featuresList{i, 2};
        cardGrid.Layout.Row = row;
        cardGrid.Layout.Column = col;
        cardGrid.Padding = [5, 5, 5, 5];
        
        % 创建功能标签（确保居中）
        featureLabel = uilabel(cardGrid);
        featureLabel.Text = featuresList{i, 1};
        featureLabel.FontSize = 13.5;
        featureLabel.FontWeight = 'bold';
        featureLabel.FontColor = [0.1, 0.1, 0.1];
        featureLabel.HorizontalAlignment = 'center';
        featureLabel.VerticalAlignment = 'center';
        featureLabel.Layout.Row = 1;
        featureLabel.Layout.Column = 1;
        featureLabel.WordWrap = 'on';
    end
    
    % ================== 版权区域 ==================
    copyrightPanel = uipanel(mainGrid);
    copyrightPanel.Layout.Row = 4;
    copyrightPanel.BackgroundColor = [0.95, 0.95, 0.97];
    
    copyrightGrid = uigridlayout(copyrightPanel, [2, 1]);
    copyrightGrid.RowHeight = {'fit', 'fit'};
    copyrightGrid.RowSpacing = 5;
    copyrightGrid.Padding = [15, 15, 15, 15];
    
    % 版权信息
    copyrightLabel = uilabel(copyrightGrid);
    copyrightLabel.Text = '© 2025 天津大学神经工程实验室 | 保留所有权利';
    copyrightLabel.FontSize = 12;
    copyrightLabel.FontAngle = 'italic';
    copyrightLabel.FontColor = [0.4, 0.4, 0.4];
    copyrightLabel.HorizontalAlignment = 'center';
    copyrightLabel.Layout.Row = 1;
    copyrightLabel.Layout.Column = 1;
    
    % 技术支持信息
    supportLabel = uilabel(copyrightGrid);
    supportLabel.Text = '技术支持: panlincong@tju.edu.cn | 网站: https://github.com/PLC-TJU/NeuroStream';
    supportLabel.FontSize = 12;
    supportLabel.FontColor = [0.5, 0.5, 0.5];
    supportLabel.HorizontalAlignment = 'center';
    supportLabel.Layout.Row = 2;
    supportLabel.Layout.Column = 1;
end