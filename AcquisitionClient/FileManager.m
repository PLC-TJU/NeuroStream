classdef FileManager < handle
    % FileManager 管理 EEGData 目录下的二进制数据文件（在线保存的EEG数据）,
    %             以及离线模型训练和评估过程中产生的数据文件。
    % 功能包括：
    %   - 按 Subject/Session 组织文件存储
    %   - 创建带Header的二进制文件
    %   - 写入/关闭数据文件
    %   - 维护元数据表 (EEGFileMetadata.mat)
    %   - 提供UI界面管理数据列表
    %   - 批量合并指定时间段的数据
    %   - 保存分类模型、评估结果等

    % LC.Pan <panlincong@tju.edu.cn>
    % Data: 2025.5.1
    
    properties
        % ----------------- 数据存储路径 -----------------
        RootFolder       % EEGData根目录 (ConfigMgr.DataFolder)
        MetadataFile     % 元数据文件路径 (EEGFileMetadata.mat)
        
        % ----------------- 数据基本信息 -----------------
        Subject         % 受试者ID (字符串)
        Session         % 会话ID (字符串)
        SamplingRate    % 采样率 (Hz)
        TimePoints      % 标签后的多个反馈时间点（秒）
        TotalChannels   % 总通道数
        EEGChannels     % EEG通道数
        LabelChannel    % 标签通道索引
        Paradigm        % 实验范式
        
        % ----------------- 数据缓存管理 -----------------
        DataBuf             % 数据缓存 (channels x bufferPoints)
        writeIndex          % 当前写入位置
        samplesCollected    % 累计采集样本点数
    end
    
    properties (Access = private)
        DataTable            % 元数据表 (FilePath, Subject, Session, ...)
        dataFileID           % 当前.bin文件ID
        CurrentFile          % 当前.bin文件完整路径
        CurrentFold          % 当前受试者和Session对应的文件夹
        period = [-1.5, 4.5] % 存储样本数据时截取EEG信号的时间窗
    end
    
    methods
        function obj = FileManager(configMgr)
            % 构造函数初始化
            obj.dataFileID  = -1;        % -1表示无打开文件
            obj.CurrentFile = ''; 
            
            % 更新参数配置并初始化数据缓存
            obj.initDataBuffer(configMgr);
        end
        
        function initDataBuffer(obj, configMgr)
            % 根据ConfigManager初始化数据缓存和配置
            % 输入验证
            if nargin < 2 || isempty(configMgr) || ~isa(configMgr, 'ConfigManager')
                error('FileManager:InvalidInput', '必须传入有效的ConfigManager对象');
            end
            
            % 从ConfigManager加载参数配置
            obj.Paradigm      = string(configMgr.Paradigm);
            obj.Subject       = string(configMgr.Subject);
            obj.Session       = string(configMgr.Session);
            obj.SamplingRate  = configMgr.SamplingRate;
            obj.TimePoints    = configMgr.TimePoints;
            obj.TotalChannels = configMgr.TotalChannels;
            obj.EEGChannels   = configMgr.EEGChannels;
            obj.LabelChannel  = configMgr.LabelChannel;
            
            % 初始化数据缓存
            bufferPoints = configMgr.getBufferPoints();
            obj.DataBuf  = zeros(obj.TotalChannels, bufferPoints, 'single');
            obj.writeIndex = 1;
            obj.samplesCollected = 0;
            
            % 设置根目录并确保存在
            obj.RootFolder = configMgr.DataFolder;
            if ~isfolder(obj.RootFolder)
                mkdir(obj.RootFolder);
            end
            
            % 设置当前受试者和Session对应的文件夹并确保存在
            relPath = fullfile(obj.Subject, obj.Session);
            obj.CurrentFold = fullfile(obj.RootFolder, relPath);
            if ~isfolder(obj.CurrentFold)
                mkdir(obj.CurrentFold);
            end
            
            % 初始化元数据文件
            obj.MetadataFile = fullfile(obj.CurrentFold, 'EEGFileMetadata.mat');
            obj.loadOrCreateMetadata();
        end
        
        function createDataFile(obj)
            % 创建新的二进制数据文件并写入Header
            % 构建存储路径 (Subject/Session/Online_Data)
            fullDir = fullfile(obj.CurrentFold, 'Online_Data');
            if ~isfolder(fullDir)
                mkdir(fullDir);
            end
            
            % 生成带时间戳的文件名
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            fileName  = sprintf('eeg_%s.bin', timestamp);
            fullPath  = fullfile(fullDir, fileName);
            
            % 打开文件并写入Header
            [fid, errMsg] = fopen(fullPath, 'wb');
            if fid == -1
                error('FileManager:FileCreateError', '文件创建失败: %s\n错误信息: %s', fullPath, errMsg);
            end
            
            % 写入Header (单精度浮点数)
            fwrite(fid, obj.SamplingRate,  'uint16');   % 采样率 (2字节)
            fwrite(fid, obj.TotalChannels,  'uint8');   % 总通道数 (1字节)
            fwrite(fid, obj.EEGChannels,    'uint8');   % EEG通道数 (1字节)
            fwrite(fid, obj.LabelChannel,   'uint8');   % 标签通道索引 (1字节)
            
            % 更新对象状态
            obj.dataFileID  = fid;
            obj.CurrentFile = fullPath;
            
            % 添加新条目到元数据表
            newEntry = {fullPath, obj.Subject, obj.Session, ...
                        obj.SamplingRate, obj.EEGChannels, obj.Paradigm};
            obj.DataTable = [obj.DataTable; newEntry];
            obj.saveMetadata();
        end
        
        function saveData(obj, dataChunk)
            % 将数据块写入当前打开的.bin文件
            % 输入验证
            if obj.dataFileID == -1
                error('FileManager:NoOpenFile', '无打开的数据文件，请先调用createDataFile');
            end
            if isempty(dataChunk) || ~ismatrix(dataChunk)
                error('FileManager:InvalidData', '输入数据必须是非空矩阵');
            end
            
            % 写入单精度浮点数据
            fwrite(obj.dataFileID, single(dataChunk), 'single');
        end
        
        function closeDataFile(obj)
            % 关闭当前数据文件
            if obj.dataFileID ~= -1
                fclose(obj.dataFileID);
                obj.dataFileID = -1;
                obj.CurrentFile = '';
            end
        end
        
        function tbl = listAllData(obj)
            % 返回元数据表副本
            tbl = obj.DataTable;
        end
        
        function eegData = mergeDataFiles(obj, filePaths)
            % 合并多个.bin文件 (按文件名时间戳排序)
            % 输入验证
            if isempty(filePaths) || ~iscellstr(filePaths) %#ok <ISCLSTR>
                error('FileManager:InvalidInput', 'filePaths必须是非空字符串元胞数组');
            end
            
            % 按文件名时间戳排序
            try
                timestamps = cellfun(@(f) extractTimestamp(f), filePaths);
                [~, sortIdx] = sort(timestamps);
                filePaths = filePaths(sortIdx);
            catch ME
                error('FileManager:TimestampError', '时间戳排序失败: %s', ME.message);
            end
            
            % 预分配合并数据
            mergedData = [];
            refHeader = [];  % 参考头信息 (用于一致性检查)
            
            for i = 1:numel(filePaths)
                filePath = filePaths{i};
                [fid, errMsg] = fopen(filePath, 'rb');
                if fid == -1
                    warning('FileManager:FileOpenSkip', '文件打开失败: %s\n错误: %s', filePath, errMsg);
                    continue;
                end
                
                % 读取Header
                hdr = struct();
                hdr.SamplingRate  = fread(fid, 1, 'uint16=>double');
                hdr.TotalChannels = fread(fid, 1, 'uint8=>double');
                hdr.EEGChannels   = fread(fid, 1, 'uint8=>double');
                hdr.LabelChannel  = fread(fid, 1, 'uint8=>double');
                
                % 头信息一致性检查
                if isempty(refHeader)
                    refHeader = hdr;
                elseif ~isequal(hdr, refHeader)
                    fclose(fid);
                    warning('FileManager:HeaderMismatch', ...
                        '文件头不一致: %s\n跳过此文件', filePath);
                    continue;
                end
                
                % 读取数据
                data = fread(fid, [hdr.TotalChannels, inf], 'single=>single');
                fclose(fid);
                
                % 数据完整性检查
                if isempty(data)
                    warning('FileManager:EmptyData', '无有效数据: %s', filePath);
                    continue;
                end
                
                % 拼接数据
                mergedData = [mergedData, data]; %#ok<AGROW>

                % 创建信息结构
                Info.chaninfo = 1:hdr.EEGChannels;
                Info.period = obj.period;
                Info.filelist = filePaths';
                Info.fs = hdr.SamplingRate;

                taskwin = [abs(Info.period(1)),diff(Info.period)];
                taskpoints=taskwin(1)*Info.fs+1:taskwin(2)*Info.fs;
                Info.taskpoints=taskpoints;

                % 根据标签分段
                eegdata = mergedData(1:hdr.EEGChannels,:);
                labeldata = mergedData(hdr.LabelChannel,:);
                labelsind = find(labeldata~=0);
                labels = double(labeldata(labelsind));
                epochDuration = diff(Info.period) * Info.fs;
                samples = nan(hdr.EEGChannels,epochDuration,length(labels));
                for s=1:length(labels)
                    startIdx = labelsind(s) + round(Info.period(1)*Info.fs);
                    endIdx = startIdx + epochDuration - 1;
                    samples(:,:,s)=eegdata(:, startIdx:endIdx);
                end

                eegData.data=samples;
                eegData.label=labels(:);
                eegData.Info=Info;
            end

            
            % 嵌套函数：从路径提取时间戳
            function ts = extractTimestamp(f)
                [~, fname] = fileparts(f);
                tsStr = regexp(fname, 'eeg_(\d{8}_\d{6})', 'tokens', 'once');
                if isempty(tsStr)
                    error('无效文件名格式: %s', fname);
                end
                ts = datetime(tsStr{1}, 'InputFormat', 'yyyyMMdd_HHmmss');
            end
        end
        
        function saveMergedData(~, mergedData, savePath)
            % 保存合并后的数据到.mat文件
            if isempty(mergedData)
                warning('FileManager:EmptyData', '合并数据为空，未保存');
                return;
            end
            
            % 构建存储路径
            [saveDir, ~, ~] = fileparts(savePath);
            if ~isfolder(saveDir)
                mkdir(saveDir);
            end
            
            % 解构数据
            data=mergedData.data;
            label=mergedData.label;
            Info=mergedData.Info;
 
            try
                save(savePath, 'data', 'label', 'Info', '-v7');
            catch ME
                error('FileManager:SaveError', '数据保存失败: %s', ME.message);
            end
        end

        function modelInfo = saveModel(obj, models) 
            % 检查输入是否为结构体
            if ~isstruct(models)
                error('输入必须是包含多个模型的结构体');
            end
            
            % 验证模型集合中的每个模型
            feedbackTimes = obj.TimePoints;
            model_fs = nan(1,numel(feedbackTimes));
            for i = 1:numel(feedbackTimes)
                timePoint = feedbackTimes(i);
                fieldName = sprintf('model_%.1fs', timePoint);
                fieldName = strrep(fieldName, '.', '_');
                
                if ~isfield(models, fieldName)
                    error('模型集合缺少%.1fs模型', timePoint);
                end
                
                model = models.(fieldName);
                
                % 检查模型必需字段
                requiredFields = {'name', 'originalFs'};
                if ~all(isfield(model, requiredFields))
                    missing = setdiff(requiredFields, fieldnames(model));
                    error('%.1fs模型缺少字段: %s', timePoint, strjoin(missing, ', '));
                end

                model_fs(i) = model.originalFs;
            end

            if length(unique(model_fs))~=1
                error('各个反馈时间点的分类模型的原始采样率不一致！');
            end
        
            % 构建存储路径
            fullDir = fullfile(obj.CurrentFold, 'Models');
            if ~isfolder(fullDir)
                mkdir(fullDir);
            end
            
            % 生成带分类方法和时间戳的文件名
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            fileName  = sprintf('model_%s_%s.mat', model.name, timestamp);
            fullPath  = fullfile(fullDir, fileName);
            
            % 添加元数据
            modelInfo = struct();
            modelInfo.SamplingRate = model_fs(1);
            modelInfo.FeedbackTimes = feedbackTimes;
            modelInfo.Subject = obj.Subject;
            modelInfo.Session = obj.Session;
            modelInfo.Paradigm = obj.Paradigm;
            modelInfo.Timestamp = char(datetime('now'));
            modelInfo.ModelCount = numel(feedbackTimes);
            modelInfo.filePath = fullPath;
        
            % 保存模型集合和元数据
            save(fullPath, "models", "modelInfo");
        end

        function fullPath  = saveAnalysisResult(obj, results)
            % 构建存储路径
            fullDir = fullfile(obj.CurrentFold, 'AnalysisResults');
            if ~isfolder(fullDir)
                mkdir(fullDir);
            end

            % 生成带分类方法和时间戳的文件名
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            fileName = sprintf('分析结果_%s_%s.mat', ...
                    results.analysisType, timestamp);
            fullPath  = fullfile(fullDir, fileName);      
            
            % 添加元数据
            results.metadata = struct(...
                'saveTime', datetime('now'), ...
                'subject', obj.Subject, ...
                'session', obj.Session, ...
                'paradigm', obj.Paradigm);
            
            % 保存结果
            AnalysisResults = results;
            save(fullPath, 'AnalysisResults');
        end

        function fullPath  = saveEvaluationResult(obj, results)
            % 构建存储路径
            fullDir = fullfile(obj.CurrentFold, 'EvaluationResults');
            if ~isfolder(fullDir)
                mkdir(fullDir);
            end

            % 生成带分类方法和时间戳的文件名
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            fileName = sprintf('评估结果_%s_%s_%s.mat', ...
                    results.evaluationType, results.algorithm, timestamp);
            fullPath  = fullfile(fullDir, fileName);      
            
            % 添加元数据
            results.metadata = struct(...
                'saveTime', datetime('now'), ...
                'subject', obj.Subject, ...
                'session', obj.Session, ...
                'paradigm', obj.Paradigm);
            
            % 保存结果
            EvaluationResults = results;
            save(fullPath, 'EvaluationResults', '-v7.3');
        end

        function fullPath = saveResult(obj, labelTable, finalAccuracies)
            if isempty(labelTable)
                return;
            end
        
            % 构建存储路径
            fullDir = fullfile(obj.CurrentFold, 'Results');
            if ~isfolder(fullDir)
                mkdir(fullDir);
            end
        
            % 生成文件名
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            fileName = sprintf('result_online_%s.mat', timestamp);
            fullPath = fullfile(fullDir, fileName);
            
            % 创建结果结构
            Results = struct();
            
            % 1. 样本级结果
            numFeedbacks = size(labelTable, 2) - 1;
            feedbackTimes = obj.TimePoints(1:numFeedbacks);
            
            % 创建列名
            colNames = cell(1, size(labelTable, 2));
            colNames{1} = 'TrueLabel';
            for i = 1:numFeedbacks
                colNames{i+1} = sprintf('Pred_%.1fs', feedbackTimes(i));
            end
            
            % 创建样本结果表格
            sampleTable = array2table(labelTable, 'VariableNames', colNames);
            
            % 2. 反馈点准确率
            accTable = table();
            accTable.FeedbackTime = feedbackTimes';
            accTable.FinalAccuracy = finalAccuracies';
            
            % 3. 完整结果
            Results.SampleResults = sampleTable;
            Results.AccuracyResults = accTable;
            Results.Timestamp = datetime('now');
            Results.Subject = obj.Subject;
            Results.Session = obj.Session;
            Results.Paradigm = obj.Paradigm;
            
            % 保存结果
            save(fullPath, "Results");
        end
        
        function showDataListDialog(obj)
            % 创建主图窗
            fig = uifigure('Name', 'EEG 数据文件列表', ...
                'Position', [100 100 900 500], ...
                'WindowStyle','alwaysontop',...%置顶
                'Icon','app_icon_2.png');

            % 检查元数据表是否为空
            if isempty(obj.DataTable) || height(obj.DataTable) == 0
                % 使用已创建的图窗作为父对象
                uialert(fig, '元数据表为空，请先采集数据', '无数据', 'Icon', 'warning');
                createDisabledTables(fig);
                return;
            end

            % 创建表格数据副本（防止直接修改原始数据）
            displayTable = obj.DataTable;

            % 创建表格控件
            tbl = uitable(fig, ...
                'Data', displayTable, ...
                'Position', [20 60 860 420], ...
                'ColumnEditable', true, ...
                'ColumnSortable', true, ...
                'CellEditCallback', @onCellEdit); % 添加单元格编辑回调
            
            % 添加保存按钮
            uibutton(fig, 'push', ...
                'Text', '保存修改', ...
                'Position', [400 20 100 30], ...
                'ButtonPushedFcn', @(src,evt) onSave());

            % 单元格编辑回调函数
            function onCellEdit(src, event)
                % 获取编辑的索引
                row = event.Indices(1);
                col = event.Indices(2);
                colName = src.Data.Properties.VariableNames{col};
                
                % 如果尝试编辑文件路径列，则恢复原值
                if strcmp(colName, 'FilePath')
                    src.Data{row, col} = obj.DataTable{row, col}; % 恢复原始值
                    uialert(fig, '文件路径不可修改', '禁止操作', 'Icon', 'warning');
                end
            end
            
            % 保存回调函数
            function onSave()
                try
                    % 验证并更新元数据
                    newTable = tbl.Data;
                    if ~istable(newTable) || ~all(ismember(obj.DataTable.Properties.VariableNames, newTable.Properties.VariableNames))
                        error('无效表格格式');
                    end

                    % 确保文件路径未被修改
                    for i = 1:height(newTable)
                        if ~strcmp(newTable.FilePath{i}, obj.DataTable.FilePath{i})
                            newTable.FilePath{i} = obj.DataTable.FilePath{i};
                        end
                    end
                    
                    % 更新并保存元信息
                    obj.DataTable = newTable;
                    obj.saveMetadata();
                    uialert(fig, '元数据已更新', '成功');
                catch ME
                    uialert(fig, sprintf('保存失败: %s', ME.message), '错误');
                end
            end

            % 当没有有效文件时创建禁用状态的控件
            function createDisabledTables(fig)
                tbl = uitable(fig, 'Data', obj.DataTable, ...
                    'Position', [20 60 860 420], ...
                    'ColumnEditable', true, ...
                    'ColumnSortable', true, ...
                    'Enable', 'off');

                uibutton(fig, 'push', ...
                    'Text', '保存修改', ...
                    'Position', [400 20 100 30], ...
                    'Enable', 'off');
            end
        end
        
        function showMergeDialog(obj)
            % 创建主图窗
            fig = uifigure('Name', '批量合并 EEG 数据', ...
                'Position', [200 200 500 400], ... % 增加高度以容纳更大的列表框
                'WindowStyle','alwaysontop',...%置顶
                'Icon', 'app_icon_2.png');
        
            % 检查元数据表是否为空
            if isempty(obj.DataTable) || height(obj.DataTable) == 0
                uialert(fig, '当前没有可合并的 .bin 文件', '提示', 'Icon', 'warning');
                createDisabledControls(fig);
                return;
            end
            
            % 获取有效文件路径（只保留实际存在的文件）
            fileList = obj.DataTable.FilePath;
            fileExists = cellfun(@(f) exist(f, 'file') == 2, fileList);
            
            if ~any(fileExists)
                uialert(fig, '没有有效的 .bin 文件路径', '提示', 'Icon', 'warning');
                createDisabledControls(fig);
                return;
            end
            
            validFiles = fileList(fileExists);
            
            % 文件选择控件 - 使用 uilistbox 替代 uidropdown
            uilabel(fig, 'Text', '选择文件 (按住Ctrl多选):', ...
                'Position', [20 350 150 22], ...
                'FontWeight', 'bold');
            
            % 创建多选列表框
            listbox = uilistbox(fig, ...
                'Items', validFiles, ...
                'Position', [20 150 460 200], ... % 更大的空间显示多个文件
                'Multiselect', 'on', ...
                'Value', validFiles(1)); % 默认选择第一个
            
            % 保存路径控件
            uilabel(fig, 'Text', '保存路径:', ...
                'Position', [20 120 100 22], ...
                'FontWeight', 'bold');
            
            edtPath = uieditfield(fig, 'text', ...
                'Position', [20 90 350 22], ...
                'Editable', 'off');

            % 设置默认存储路径
            edtPath.Value = fullfile(obj.CurrentFold, 'eegdata.mat');
            
            uibutton(fig, 'push', ...
                'Text', '浏览...', ...
                'Position', [380 90 100 22], ...
                'ButtonPushedFcn', @(src,evt) selectPath());
            
            % 操作按钮
            uibutton(fig, 'push', ...
                'Text', '开始合并', ...
                'Position', [150 20 100 30], ...
                'ButtonPushedFcn', @(src,evt) mergeFiles());
            
            uibutton(fig, 'push', ...
                'Text', '关闭', ...
                'Position', [270 20 100 30], ...
                'ButtonPushedFcn', @(src,evt) delete(fig));
            
            function selectPath()
                [file, path] = uiputfile('*.mat', '保存合并数据');
                if isequal(file, 0), return; end
                edtPath.Value = fullfile(path, file);
            end
            
            function mergeFiles()
                selFiles = listbox.Value; % 获取列表框的选中项
                
                if isempty(selFiles)
                    uialert(fig, '请选择至少一个文件', '输入错误', 'Icon', 'error');
                    return;
                end
                
                savePath = edtPath.Value;
                if isempty(savePath)
                    uialert(fig, '请指定保存路径', '输入错误', 'Icon', 'error');
                    return;
                end
                
                try
                    % 显示处理中的提示
                    progressDlg = uiprogressdlg(fig, 'Title', '处理中', ...
                        'Message', '正在合并文件...', 'Indeterminate', 'on');
                    
                    merged = obj.mergeDataFiles(selFiles);
                    obj.saveMergedData(merged, savePath);
                    
                    close(progressDlg);
                    uialert(fig, sprintf('成功保存到:\n%s', savePath), '完成', 'Icon', 'success');
                    %delete(fig);
                catch ME
                    if exist('progressDlg', 'var') && isvalid(progressDlg)
                        close(progressDlg);
                    end
                    uialert(fig, sprintf('合并失败:\n%s', ME.message), '错误', 'Icon', 'error');
                end
            end

            % 当没有有效文件时创建禁用状态的控件
            function createDisabledControls(fig)
                uilabel(fig, 'Text', '选择文件:', ...
                    'Position', [20 350 100 22], ...
                    'Enable', 'off');

                uilistbox(fig, ...
                    'Items', {'无可用文件'}, ...
                    'Position', [20 150 460 200], ...
                    'Enable', 'off');

                uilabel(fig, 'Text', '保存路径:', ...
                    'Position', [20 120 100 22], ...
                    'Enable', 'off');

                uieditfield(fig, 'text', ...
                    'Value', fullfile(obj.CurrentFold, 'eegdata.mat'), ...
                    'Position', [20 90 350 22], ...
                    'Enable', 'off');

                uibutton(fig, 'push', ...
                    'Text', '浏览...', ...
                    'Position', [380 90 100 22], ...
                    'Enable', 'off');

                uibutton(fig, 'push', ...
                    'Text', '开始合并', ...
                    'Position', [150 20 100 30], ...
                    'Enable', 'off');

                uibutton(fig, 'push', ...
                    'Text', '取消', ...
                    'Position', [270 20 100 30], ...
                    'ButtonPushedFcn', @(src,evt) delete(fig));
            end
        end
    end
    
    methods (Access = private)
        function loadOrCreateMetadata(obj)
            % 加载或创建元数据表
            if exist(obj.MetadataFile, 'file') == 2
                tmp = load(obj.MetadataFile);
                obj.DataTable = tmp.DataTable;
            else
                % 创建空表 (指定列数据类型)
                obj.DataTable = table(...
                    cell(0,1), cell(0,1), cell(0,1), [], [], cell(0,1), ...
                    'VariableNames', {'FilePath','Subject','Session','SamplingRate','EEGChannels','Paradigm'});
                obj.saveMetadata();
            end
        end
        
        function saveMetadata(obj)
            % 保存元数据表到文件
            DataTable = obj.DataTable; %#ok <PROPLC>
            save(obj.MetadataFile, 'DataTable');
        end
    end
end