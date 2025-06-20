function [data, label, Info] = loadCntFiles(files, timewindow, chaninfo, fs, runclean)
% LOADCNTFILES 加载 CNT 文件并提取清洗后 EEG 试次数据
%   支持从原始 .cnt 文件读取、ICA+ICLabel 清洗、剔除坏试次、提取指定通道和时间窗。

% 输入:
%   files       - 单个或多个 .cnt 文件路径 (字符串或 cell 数组)
%   timewindow  - 试次时间窗 [t1, t2] 秒，相对于事件起始(默认 [-1.5, 4.5])
%   chaninfo    - 通道名称 cell 数组 (默认获取 28 导联)
%   fs          - 目标采样率 (Hz)，不指定则不降采样
%   runclean    - 是否进行数据清洗，逻辑标量(默认为flase)

% 输出:
%   data        - 清洗后的 EEG 数据 [通道×时间×试次]
%   label       - 试次标签向量 [试次数×1]
%   Info        - 结构体，包含 chaninfo、period、filelist、fs、icaInfo、removedInfo

%% 参数验证与默认值
if nargin<5, runclean = false; end
if nargin<4, fs = []; end
if nargin<3 || isempty(chaninfo), chaninfo = getDefaultChannelSet(28); end
if nargin<2 || isempty(timewindow), timewindow = [-1.5, 4.5]; end
if ischar(files), files = {files}; end

%% 初始化输出
data = [];
label = [];
Info.filelist = files;
fs_list = [];
allRemoved = table();

%% 处理每个文件
for idxF = 1:numel(files)
    filePath = files{idxF};
    [~,fname,ext] = fileparts(filePath);
    if ~strcmpi(ext, '.cnt')
        warning('跳过非 CNT 文件: %s', fname); continue;
    end
    try
        % --- 1. 原始数据加载 ---
        EEG = pop_loadcnt(filePath, 'dataformat', 'int32');
        EEG = eeg_checkset(EEG);

        
        EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');
        EEG = eeg_checkset(EEG);
        EEG = pop_select(EEG, 'nochannel', {'M1','M2','HEO','VEO','EKG','EMG'});

        % --- 2. ICA+ICLabel 清洗及坏试次剔除 ---
        if runclean
            [EEG, removedInfo, icaInfo] = cleanEegSamples(EEG, [0, timewindow(2)]);
            % 记录所有文件的删除日志，保留文件索引
            removedInfo.FileIndex(1:height(removedInfo),1) = idxF;
            allRemoved = cat(1, allRemoved, removedInfo);
            Info.icaInfo{idxF} = icaInfo; % 存储每文件 ICA 信息
        end

        % --- 3. 提取通道数据 ---
        allCh = {EEG.chanlocs.labels};
        [isValid, chIdx] = ismember(chaninfo, allCh);
        if any(~isValid)
            warning('文件 %s 缺少通道: %s', fname, strjoin(chaninfo(~isValid),','));
        end
        eegData = double(EEG.data(chIdx(isValid), :));

        % --- 4. 提取有效事件（跳过 boundary） ---
        ev = EEG.event;
        % 筛选数值类型事件
        types = [];   % 存储数值型事件类型
        lat = [];     % 存储事件延迟
        
        % 遍历所有事件
        for i = 1:numel(ev)
            % 跳过边界事件
            if strcmpi(ev(i).type, 'boundary')
                continue;
            end
            
            % 处理不同类型的事件值
            eventType = ev(i).type;
            eventValue = NaN;
            
            if isnumeric(eventType)
                % 数值型事件直接使用
                eventValue = eventType;
            elseif ischar(eventType)
                % 尝试将字符串转换为数值
                eventValue = str2double(eventType);
            end
            
            % 如果是有效数值，则添加到结果
            if ~isnan(eventValue)
                types=cat(1,types,eventValue);
                lat=cat(1,lat,ev(i).latency);
            end
        end

        % --- 5. 按 timewindow 切 epoch ---
        sampWin = round(diff(timewindow) * EEG.srate);
        offset  = round(timewindow(1) * EEG.srate);
        nTrials = numel(types);
        samples = nan(size(eegData,1), sampWin, nTrials);
        for t = 1:nTrials
            st = lat(t) + offset;
            ed = st + sampWin -1;
            samples(:,:,t) = eegData(:, st:ed);
        end

        % --- 6. 可选降采样 ---
        if ~isempty(fs)
            samples = resampleData(samples, EEG.srate, fs);
            thisFs = fs;
        else
            thisFs = EEG.srate;
        end
        fs_list = cat(1, fs_list, thisFs);

        % --- 7. 合并输出 ---
        data = cat(3, data, samples);
        label = cat(1, label, types(:));

    catch ME
        warning('处理文件 %s 时出错: %s', fname, ME.message);
    end
end

% 验证输出
if isempty(data)
    error('未提取到任何有效数据');
end
Info.chaninfo = chaninfo;
Info.period = timewindow;
Info.removedInfo = allRemoved;

% 统一采样率
if isempty(fs)
    if numel(unique(fs_list))>1
        error('各文件采样率不一致: %s', mat2str(unique(fs_list))); end
    Info.fs = fs_list(1);
else
    Info.fs = fs;
end

taskwin = [abs(timewindow(1)),diff(timewindow)];
taskpoints=taskwin(1)*Info.fs+1:taskwin(2)*Info.fs;
Info.taskpoints=taskpoints;

end
