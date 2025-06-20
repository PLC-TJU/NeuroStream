function createManualDialog()
    % 创建用户手册对话框
    manualFig = uifigure('Name', '用户手册', ...
        'Position', [100, 100, 800, 600], ...
        'WindowStyle','alwaysontop',...%置顶
        'Color', [1, 1, 1], ...
        'Icon','app_icon_2.png');
    
    % 创建选项卡组
    tabgp = uitabgroup(manualFig, 'Position', [20, 20, 760, 560]);
    
    % 快速入门选项卡
    tab1 = uitab(tabgp, 'Title', '快速入门');
    createQuickStartTab(tab1);
    
    % 配置管理选项卡
    tab2 = uitab(tabgp, 'Title', '配置管理');
    createConfigTab(tab2);
    
    % 实验流程选项卡
    tab3 = uitab(tabgp, 'Title', '实验流程');
    createWorkflowTab(tab3);
    
    % 故障排除选项卡
    tab4 = uitab(tabgp, 'Title', '故障排除');
    createTroubleshootingTab(tab4);
end

%% 子函数 - 快速入门选项卡
function createQuickStartTab(parent)
    grid = uigridlayout(parent, [2, 1]);
    grid.RowHeight = {'fit', '1x'};
    grid.Padding = [10, 10, 10, 10];
    
    % 简介
    introText = {['欢迎使用脑机接口实时处理系统。本指南将帮助您快速开始使用本系统进行脑电信号采集、处理和分析。' ...
        '系统支持多种实验范式，包括事件相关电位(ERP)、运动想象(MI)和稳态视觉诱发电位(SSVEP)等。'], ...
        '要实现跨设备通信，在远程端应搭配UDPComm类使用。'};
    
    introLabel = uilabel(grid);
    introLabel.Text = introText;
    introLabel.WordWrap = 'on';
    introLabel.FontSize = 11;
    introLabel.Layout.Row = 1;
    introLabel.Layout.Column = 1;
    
    % 步骤面板
    stepsPanel = uipanel(grid);
    stepsPanel.Layout.Row = 2;
    stepsPanel.Title = '使用步骤';
    
    stepsGrid = uigridlayout(stepsPanel, [5, 1]);
    stepsGrid.RowHeight = repmat({'fit'}, 1, 5);
    stepsGrid.Padding = [10, 10, 10, 10];
    
    stepContents = {
        {'1. 系统启动', '确保 Scan 软件及其信号传输端口已打开 → 启动MATLAB应用 → 系统自动加载默认配置'}, ...
        {'2. 实验设置', '通过"配置"菜单查看实验参数 → 根据需要调整参数 → 保存当前配置'}, ...
        {'3. 模型训练', '在信号处理面板选择合适的分类模型并调整模型参数 → 加载数据 → 训练模型 → 部署模型'}, ...
        {'4. 脑电采集', '点击信号输入面板的"启动"按钮建立TCP连接 → 状态栏显示"信号采集已开启"'}, ...
        {'5. 设备连接', '点击反馈输出面板的"启动"按钮建立UDP连接 → 状态栏显示"反馈端连接成功"'}, ...
        {'6. 开始实验', '系统自动检测脑电标签 → 分类结果通过UDP发送到接收端 → 状态栏实时监控分类情况'}
    };
    
    for i = 1:numel(stepContents)
        step = stepContents{i};
        stepGrid = uigridlayout(stepsGrid);
        stepGrid.Layout.Row = i;
        stepGrid.RowHeight = {'fit'};
        stepGrid.ColumnWidth = {'fit', '1x'};
        
        % 步骤编号
        numLabel = uilabel(stepGrid);
        numLabel.Text = step{1};
        numLabel.FontWeight = 'bold';
        numLabel.FontSize = 12;
        numLabel.Layout.Row = 1;
        numLabel.Layout.Column = 1;
        
        % 步骤描述
        descLabel = uilabel(stepGrid);
        descLabel.Text = step{2};
        descLabel.FontSize = 11;
        descLabel.Layout.Row = 1;
        descLabel.Layout.Column = 2;
    end
end

%% 子函数 - 配置管理选项卡
function createConfigTab(parent)
    grid = uigridlayout(parent, [1, 2]);
    grid.ColumnWidth = {'1x', '1x'};
    grid.Padding = [10, 10, 10, 10];
    
    % 配置类型
    configPanel = uipanel(grid);
    configPanel.Title = '配置类型';
    configPanel.Layout.Column = 1;
    
    configGrid = uigridlayout(configPanel, [3, 1]);
    configGrid.RowHeight = repmat({'fit'}, 1, 3);
    configGrid.Padding = [10, 10, 10, 10];
    
    configTypes = {
        {'默认配置', '系统内置的基础配置，适用我自己的运动想象实验'}, ...
        {'运动想象配置', '优化的参数设置，用于运动想象范式'}, ...
        {'SSVEP配置', '针对稳态视觉诱发电位的专用配置'}
    };
    
    for i = 1:numel(configTypes)
        config = configTypes{i};
        configGridItem = uigridlayout(configGrid);
        configGridItem.Layout.Row = i;
        configGridItem.RowHeight = {'fit'};
        configGridItem.ColumnWidth = {'fit', '1x'};
        
        % 配置标题
        titleLabel = uilabel(configGridItem);
        titleLabel.Text = [config{1} ':'];
        titleLabel.FontWeight = 'bold';
        titleLabel.Layout.Row = 1;
        titleLabel.Layout.Column = 1;
        
        % 配置描述
        descLabel = uilabel(configGridItem);
        descLabel.Text = config{2};
        descLabel.Layout.Row = 1;
        descLabel.Layout.Column = 2;
    end
    
    % 操作指南
    opsPanel = uipanel(grid);
    opsPanel.Title = '配置操作';
    opsPanel.Layout.Column = 2;
    
    opsGrid = uigridlayout(opsPanel, [3, 1]);
    opsGrid.RowHeight = repmat({'fit'}, 1, 3);
    opsGrid.Padding = [10, 10, 10, 10];
    
    opsList = {
        {'加载配置', '通过"文件→加载配置"选择配置文件'}, ...
        {'保存配置', '通过"文件→保存配置"存储当前设置'}, ...
        {'恢复默认', '通过"配置→默认配置"恢复初始设置'}
    };
    
    for i = 1:numel(opsList)
        op = opsList{i};
        opGridItem = uigridlayout(opsGrid);
        opGridItem.Layout.Row = i;
        opGridItem.RowHeight = {'fit'};
        opGridItem.ColumnWidth = {'fit', '1x'};
        
        % 操作标题
        titleLabel = uilabel(opGridItem);
        titleLabel.Text = op{1};
        titleLabel.FontWeight = 'bold';
        titleLabel.Layout.Row = 1;
        titleLabel.Layout.Column = 1;
        
        % 操作描述
        descLabel = uilabel(opGridItem);
        descLabel.Text = op{2};
        descLabel.Layout.Row = 1;
        descLabel.Layout.Column = 2;
    end
end

%% 子函数 - 实验流程选项卡
function createWorkflowTab(parent)
    grid = uigridlayout(parent, [2, 1]);
    grid.RowHeight = {'fit', '1x'};
    grid.Padding = [10, 10, 10, 10];
    
    % 流程图标题
    flowTitle = uilabel(grid);
    flowTitle.Text = '系统工作流程';
    flowTitle.FontSize = 14;
    flowTitle.FontWeight = 'bold';
    flowTitle.HorizontalAlignment = 'center';
    flowTitle.Layout.Row = 1;
    flowTitle.Layout.Column = 1;
    
    % 流程说明
    descText = ['1. 信号采集: 通过TCP协议从Scan4.5实时获取脑电数据\n' ...
        '2. 数据缓存: 系统维护30秒的环形数据缓冲区\n' ...
        '3. 标签检测: 自动识别脑电信号中的事件标签\n' ...
        '4. 时间窗提取: 根据配置提取标签前后的数据段\n' ...
        '5. 特征提取: 计算时域、频域及时频域特征\n' ...
        '6. 分类处理: 使用预训练模型生成分类结果\n' ...
        '7. 结果发送: 通过UDP将分类标签发送到接收端\n' ...
        '8. 数据存储: 原始数据保存到二进制文件供后续分析\n'...
        '9. 以上都是我瞎写着玩的，毕竟我又懒又爱玩◕‿◕'
        ];
    
    descArea = uitextarea(grid);
    descArea.Value = sprintf(descText);
    descArea.Layout.Row = 2;
    descArea.Layout.Column = 1;
    descArea.FontSize = 12;
    descArea.Editable = 'off';
end

%% 子函数 - 故障排除选项卡 (兼容版本)
function createTroubleshootingTab(parent)
    grid = uigridlayout(parent, [1, 2]);
    grid.ColumnWidth = {'1x', '2x'};
    grid.Padding = [10, 10, 10, 10];
    
    % 问题列表
    problemsPanel = uipanel(grid);
    problemsPanel.Title = '常见问题';
    problemsPanel.Layout.Column = 1;
    
    problemsList = {
        'TCP连接失败'
        '分类结果不准确'
        'UDP通信中断'
        '数据采集不稳定'
        '标签检测失败'
        '其它问题'
    };
    
    listbox = uilistbox(problemsPanel);
    listbox.Items = problemsList;
    listbox.ValueChangedFcn = @(src,event) problemSelected(src,event,grid);
    listbox.Position = [10, 10, 200, 450];
    
    % 问题详情面板
    detailsPanel = uipanel(grid);
    detailsPanel.Title = '问题详情与解决方案';
    detailsPanel.Layout.Column = 2;
    
    % 初始显示空内容
    detailText = uitextarea(detailsPanel);
    detailText.Position = [10, 10, 500, 450];
    detailText.Value = '请从左侧列表中选择一个问题';
    detailText.Editable = 'off';
    
    % 存储详情面板句柄
    grid.UserData.detailsPanel = detailsPanel;
    grid.UserData.detailText = detailText;
    
    % 问题选择回调函数
    function problemSelected(src, ~, parentGrid)
        selectedProblem = src.Value;
        details = getProblemDetails(selectedProblem);
        
        % 更新详情文本
        detailText = parentGrid.UserData.detailText;
        detailText.Value = details;
    end
    
    % 问题详情数据
    function details = getProblemDetails(problem)
        switch problem
            case 'TCP连接失败'
                details = {
                    '可能原因:'
                    '1. Scan4.5软件未运行'
                    '2. IP地址或端口设置错误'
                    '3. 防火墙阻止了连接'
                    ''
                    '解决方案:'
                    '1. 确保Scan4.5已启动并监听端口'
                    '2. 检查本机IP地址设置'
                    '3. 添加MATLAB到防火墙白名单'
                };
                
            case '分类结果不准确'
                details = {
                    '可能原因:'
                    '1. 时间窗设置不匹配实验范式'
                    '2. 分类模型训练不充分'
                    '3. 脑电信号质量差'
                    ''
                    '解决方案:'
                    '1. 检查并调整时间窗参数'
                    '2. 重新训练或优化分类模型'
                    '3. 检查电极接触质量'
                };
                
            case 'UDP通信中断'
                details = {
                    '可能原因:'
                    '1. 接收端未启动'
                    '2. 网络连接问题'
                    '3. IP地址/端口号设置错误'
                    ''
                    '解决方案:'
                    '1. 确认接收端已启动并监听'
                    '2. 检查网络连接状态'
                    '3. 验证接收端IP地址/端口号'
                };
                
            case '数据采集不稳定'
                details = {
                    '可能原因:'
                    '1. 软件设置问题'
                    '2. 实时传输数据量过多'
                    '3. 系统资源紧张'
                    '4. 硬件连接问题'
                    ''
                    '解决方案:'
                    '1. 检查是否开启了Scan/Curry软件的数据传输端口'
                    '2. 调整TCP传输的最大缓存数据量限制'
                    '3. 增加系统内存或关闭后台程序'
                    '4. 检查脑电采集设备连接'
                };
                
            case '标签检测失败'
                details = {
                    '可能原因:'
                    '1. 脑电采集装置故障'
                    '2. 串口/并口选择与设备不匹配'
                    '3. 标签标注程序存在纰漏'
                    ''
                    '解决方案:'
                    '1. 检查标签信号生成设备'
                    '2. 检查串口/并口端口号'
                    '3. Debug实验范式程序，检查标签是否预先置零'
                };
            case '其它问题'
                details = {
                    '可能原因:'
                    '1.你太累了'
                    '2.你太卷了'
                    '3.你太急了'
                    ''
                    '解决方案:'
                    '1.休息一会，做个眼保健操先？'
                    '2.放松一天，如果不行就两天！'
                    '3.别慌，看一集动画片或动物世界压压惊，还不行就再多看一集呢？'
                    };
            otherwise
                details = {'请选择有效的问题'};
        end
    end
end