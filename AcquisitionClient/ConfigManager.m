classdef ConfigManager < handle
    % ConfigManager 用于统一管理 BCI 参数配置，包括：
    %   - 加载 / 保存配置到 .mat 文件
    %   - 保存 / 获取 Subject 与 Session
    %   - 提供获取当前配置的字符串形式
    %   - 弹出“查看当前配置”界面
    %   - 弹出“修改配置”界面，并在界面里保存修改

    % LC.Pan <panlincong@tju.edu.cn>
    % Data: 2025.5.1
    
    properties
        % ------------------------ 基本配置属性 ------------------------ 
        Paradigm       = 'MI';        % 实验范式
        SamplingRate   = 1000;        % 采样率 (Hz)
        TimePoints = [2, 3, 4];       % 标签后的多个反馈时间点（秒）
        BufferDuration = 30;          % 缓存时长 (秒)
        
        EEGChannels    = 28;          % 脑电通道数
        LabelChannel                  % 标签通道索引（自动计算）
        TotalChannels                 % 总通道数 = EEGChannels + 1
        
        % ------------------- Subject / Session 信息 ------------------
        Subject = 'Subject_A';        % 当前受试者名称（可在界面中修改）
        Session = 'Session_1';        % 当前实验 Session（可在界面中修改）
        
        % ------------------------- 文件夹配置 -------------------------
        DataFolder                    % EEG 数据存储根目录
        ConfigFolder                  % 配置文件夹
        
        % -------------------------- 内部使用 --------------------------
        ConfigFile                    % 默认配置文件完整路径
    end
    
    methods
        function obj = ConfigManager()
            % 构造函数：初始化各属性、生成文件夹，并加载默认配置（如存在）
            
            % 1. 更新自动属性
            obj.updateDependentFields();
            
            % 2. 确保文件夹存在
            obj.DataFolder = fullfile(fileparts(mfilename('fullpath')),'EEGData');
            obj.ConfigFolder = fullfile(fileparts(mfilename('fullpath')),'Config');
            obj.ensureDirectory(obj.DataFolder);
            obj.ensureDirectory(obj.ConfigFolder);
            
            % 3. 默认配置文件路径
            obj.ConfigFile = fullfile(obj.ConfigFolder, 'DefaultConfig.mat');
            
            % 4. 如果存在默认配置文件则先删除它
            if exist(obj.ConfigFile, 'file')
                delete(obj.ConfigFile)
            end
            obj.saveConfig(obj.ConfigFile);
        end
        
        % ------------------ 自动更新依赖项 ------------------
        function updateDependentFields(obj)
            obj.TimePoints    = round(obj.TimePoints, 1);
            obj.LabelChannel  = obj.EEGChannels + 1;
            obj.TotalChannels = obj.EEGChannels + 1;
        end
        
        function pts = getFeedbackPoints(obj)
            % 返回所有反馈时间点对应的采样点数
            pts = round(obj.TimePoints * obj.SamplingRate);
        end
        
        function pkt = getBufferPoints(obj)
            % 将 BufferDuration (秒) 转为采样点数
            pkt = round(obj.BufferDuration * obj.SamplingRate);
        end
        
        function ensureDirectory(~, dirPath)
            if ~exist(dirPath, 'dir')
                mkdir(dirPath);
            end
        end
        
        % ------------------ 配置文件的加载与保存 ------------------
        function saveConfig(obj, filename)
            % 将当前属性（含 Subject/Session）打包为 struct 保存到 .mat
            config = struct(                          ...
                'Paradigm',       obj.Paradigm,       ...
                'SamplingRate',   obj.SamplingRate,   ...
                'TimePoints',     obj.TimePoints,     ...
                'BufferDuration', obj.BufferDuration, ...
                'EEGChannels',    obj.EEGChannels,    ...
                'Subject',        obj.Subject,        ...
                'Session',        obj.Session,        ...
                'DataFolder',     obj.DataFolder,     ...
                'ConfigFolder',   obj.ConfigFolder,   ...
                'ConfigFile',     obj.ConfigFile      ...
            );
            save(filename, 'config');
        end
        
        function loadConfig(obj, filename)
            % 从 .mat 加载配置并更新到当前对象（含 Subject/Session）
            tmp = load(filename, 'config');
            c = tmp.config;
            obj.Paradigm       = c.Paradigm;
            obj.SamplingRate   = c.SamplingRate;
            obj.TimePoints     = c.TimePoints;
            obj.BufferDuration = c.BufferDuration;
            obj.EEGChannels    = c.EEGChannels;
            obj.Subject        = c.Subject;
            obj.Session        = c.Session;
            obj.DataFolder     = c.DataFolder;
            obj.ConfigFolder   = c.ConfigFolder;
            obj.ConfigFile     = filename;
            % 更新依赖属性
            obj.updateDependentFields();
        end
        
        function strList = getConfigString(obj)
            % 返回一个 cell array，每行一个参数的字符串描述
            feedbackPoints = obj.getFeedbackPoints();
            feedbackTimes = obj.TimePoints;
            bp = obj.getBufferPoints();

            % 生成反馈时间点的描述
            if isempty(feedbackTimes)
                feedbackDesc = '未设置';
            else
                timeStrs = arrayfun(@(t) sprintf('%.1f秒', t), feedbackTimes, 'UniformOutput', false);
                pointStrs = arrayfun(@(p) sprintf('%d点', p), feedbackPoints, 'UniformOutput', false);
                feedbackDesc = sprintf('[%s] → [%s]', ...
                    strjoin(timeStrs, ', '), strjoin(pointStrs, ', '));
            end

            strList = { ...
                sprintf('当前受试者: %s', obj.Subject), ...
                sprintf('当前Session: %s', obj.Session), ...
                sprintf('实验范式: %s', obj.Paradigm), ...
                sprintf('采样率: %d Hz', obj.SamplingRate), ...
                sprintf('反馈时间点: %s', feedbackDesc), ...
                sprintf('脑电通道数: %d', obj.EEGChannels), ...
                sprintf('标签通道索引: %d', obj.LabelChannel), ...
                sprintf('缓存时长: %.1f 秒 → %d 点', obj.BufferDuration, bp), ...
                sprintf('EEG 数据根目录: %s', obj.DataFolder), ...
                sprintf('配置文件: %s', obj.ConfigFile) ...
                };
        end
        
        % ------------------ 弹出查看界面 ------------------
        function showConfigDialog(obj)
            % 展示一个仅用于“查看”的对话框，显示当前配置字段
            d = uifigure('Name','当前配置查看', ...
                'Position',[500 300 420 350], ...
                'Icon','app_icon_2.png');
            d.Resize = 'off';
            
            uilabel(d, ...
                'Text','当前参数配置：', ...
                'FontWeight','bold', ...
                'Position',[20 310 200 20]);
            
            strs = obj.getConfigString();
            uitextarea(d, ...
                'Value', strs, ...
                'Editable', 'off', ...
                'Position',[20 20 380 280]);
        end
        
        % ------------------ 弹出修改界面 ------------------
        function openEditDialog(obj)
            % 弹出一个带可编辑区域的子界面，用户可修改各项配置（含 Subject/Session），点击“保存”后才写回文件
            d = uifigure('Name','修改配置', ...
                'Position',[400 200 500 560], ...
                'WindowStyle','alwaysontop',...%置顶
                'Icon','app_icon_2.png');
            d.Resize = 'off';
            
            % 标题
            uilabel(d, ...
                'Text','修改参数配置','FontSize',14,'FontWeight','bold', ...
                'Position',[20 520 200 25]);
            
            % ------- 各配置编辑字段 -------
            % 1. 实验范式
            uilabel(d, 'Text','实验范式:','Position',[20 470 80 20]);
            leParadigm = uieditfield(d,'text', ...
                'Value', obj.Paradigm, ...
                'Position',[130 470 100 22], ...
                'HorizontalAlignment','center');
            
            % 2. 采样率
            uilabel(d,'Text','采样率 (Hz):','Position',[20 430 80 20]);
            uilabel(d,'Text','(建议值：1000)','Position',[250 430 150 20]);
            leSampling = uieditfield(d,'numeric', ...
                'Limits',[130 inf], ...
                'Value', obj.SamplingRate, ...
                'Position',[130 430 100 22], ...
                'HorizontalAlignment','center');
                      
            % 3. 反馈时间点
            uilabel(d,'Text','反馈时间点(秒):','Position',[20 390 100 20]);
            leTimePoints = uieditfield(d,'text', ...
                'Value', mat2str(obj.TimePoints), ...
                'Position',[130 390 100 22], ...
                'HorizontalAlignment','center');
            uilabel(d,'Text','(例如 4 或 [2,3])','Position',[250 390 150 20]);
            
            % 4. 缓存时长
            uilabel(d,'Text','缓存时长 (秒):','Position',[20 350 80 20]);
            leBuffer = uieditfield(d,'numeric', ...
                'Limits',[20 inf], ...
                'Value', obj.BufferDuration, ...
                'Position',[130 350 100 22], ...
                'HorizontalAlignment','center');
            
            % 5. 脑电通道数
            uilabel(d,'Text','脑电通道数:','Position',[20 310 80 20]);
            uilabel(d,'Text','(不包含标签通道)','Position',[250 310 150 20]);
            leCh = uieditfield(d,'numeric', ...
                'Limits',[1 inf], ...
                'Value', obj.EEGChannels, ...
                'Position',[130 310 100 22], ...
                'HorizontalAlignment','center');
            
            % 6. 当前 Subject
            uilabel(d,'Text','当前受试者:','Position',[20 270 80 20]);
            leSubject = uieditfield(d,'text', ...
                'Value', obj.Subject, ...
                'Position',[130 270 100 22], ...
                'HorizontalAlignment','center');
            
            % 7. 当前 Session
            uilabel(d,'Text','当前 Session:','Position',[20 230 80 20]);
            leSession = uieditfield(d,'text', ...
                'Value', obj.Session, ...
                'Position',[130 230 100 22], ...
                'HorizontalAlignment','center');
            
            % 8. EEG 数据根目录
            uilabel(d,'Text','EEG 数据目录:','Position',[20 190 90 20]);
            btnBrowse = uibutton(d,'push', ... 
                'Text','浏览…', ...
                'Position',[130 190 100 22], ...
                'ButtonPushedFcn', @(~,~) selectFolder());%#ok <*UNUSEDP>
            leDataFolder = uieditfield(d,'text', ...
                'Value', obj.DataFolder, ...
                'Editable','off', ...
                'Position',[20 160 460 22], ...
                'HorizontalAlignment','left');
            
            function selectFolder()
                sel = uigetdir(obj.DataFolder, '选择 EEG 数据根目录');
                if sel && isfolder(sel)
                    leDataFolder.Value = sel;
                end
            end
            
            % 9. 配置文件夹（只读，通常不让用户改）
            uilabel(d,'Text','配置存储目录（不允许修改）:','Position',[20 120 160 20]);
            teCfgFolder = uieditfield(d,'text', ...
                'Value', obj.ConfigFolder, ...
                'Editable','off', ...
                'Position',[20 90 460 22], ...
                'HorizontalAlignment','left');%#ok <*UNUSEDP>
            
            % ------- 保存 & 另存为 & 取消 按钮 -------
            btnSave = uibutton(d, 'push', ...
                'Text', '保存', ...
                'Position', [80 30 100 30], ...
                'ButtonPushedFcn', @(~, ~) onSave(false));%#ok <*UNUSEDP>
            btnSaveAs = uibutton(d, 'push', ...
                'Text', '另存为...', ...
                'Position', [200 30 100 30], ...
                'ButtonPushedFcn', @(~, ~) onSave(true));%#ok <*UNUSEDP>
            btnCancel = uibutton(d, 'push', ...
                'Text', '取消', ...
                'Position', [320 30 100 30], ...
                'ButtonPushedFcn', @(~, ~) close(d));

            % 保存回调
            function onSave(isSaveAs)
                try
                    % 读取用户输入并校验
                    p_new      = strtrim(leParadigm.Value);
                    sr_new     = leSampling.Value;

                    % 读取时间点参数
                    timePoints = str2num(leTimePoints.Value); %#ok<ST2NM>
                    timePoints = round(timePoints, 1);
                    if isempty(timePoints) || any(timePoints <= 0)
                        uialert(d, '反馈时间点必须为正数', '错误');
                        return;
                    end

                    buf_new    = leBuffer.Value;
                    ch_new     = leCh.Value;
                    subj_new   = strtrim(leSubject.Value);
                    sess_new   = strtrim(leSession.Value);
                    df_new     = strtrim(leDataFolder.Value);

                    % 更新属性
                    obj.Paradigm       = p_new;
                    obj.SamplingRate   = sr_new;
                    obj.TimePoints     = sort(timePoints);% 排序确保递增
                    obj.BufferDuration = buf_new;
                    obj.EEGChannels    = ch_new;
                    obj.Subject        = subj_new;
                    obj.Session        = sess_new;
                    obj.DataFolder     = df_new;

                    % 重新计算依赖字段
                    obj.updateDependentFields();

                    % 确保目录存在
                    obj.ensureDirectory(obj.DataFolder);

                    if isSaveAs
                        % 另存为新配置文件
                        [file, path] = uiputfile('*.mat', '另存为新配置文件', obj.ConfigFile);
                        if isequal(file, 0) || isequal(path, 0)
                            % 用户取消了另存为操作
                            return;
                        end
                        newConfigFile = fullfile(path, file);
                        obj.saveConfig(newConfigFile);
                    else
                        % 写回原配置文件
                        obj.saveConfig(obj.ConfigFile);
                    end

                    % 提示并关闭
                    uialert(d, '配置已保存', '成功');

                    % 改为手动关闭
                    % close(d);
                    btnCancel.Text = '关闭';

                catch ME
                    uialert(d, sprintf('保存过程中出错：\n%s', ME.message), '错误');
                end
            end
        end
    end
end
