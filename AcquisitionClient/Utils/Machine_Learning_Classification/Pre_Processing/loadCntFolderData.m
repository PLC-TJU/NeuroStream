function [data, label, Info] = loadCntFolderData(folder, timewindow, chaninfo, fs)
% LOADCNTFOLDERDATA 加载文件夹中所有 CNT 文件并提取脑电数据
%
% 输入:
%   folder      - CNT 文件所在文件夹路径
%   timewindow  - [t1, t2] 时间窗，以事件为0点（秒），默认为 [0, 4]
%   chaninfo    - 要提取的电极名称（cell 数组），默认为 28 导联
%   fs          - 降采样频率（Hz），默认为空（不降采样）
%
% 输出:
%   data        - EEG 数据矩阵（通道 × 时间点 × 试次）
%   label       - 试次标签向量（试次数 × 1）
%   Info        - 数据结构，包含：
%                 .chaninfo : 电极名称
%                 .period   : 时间窗 [t1, t2]
%                 .fs       : 实际采样率
%                 .filelist : 处理的文件列表

% 参数验证与默认值设置
if nargin < 4
    fs = [];
end

if nargin < 3 || isempty(chaninfo)
    chaninfo = getDefaultChannelSet(28);
end

if nargin < 2 || isempty(timewindow)
    timewindow = [0, 4];
end

% 验证时间窗
if numel(timewindow) ~= 2 || timewindow(1) >= timewindow(2)
    error('无效时间窗: 必须为 [t_start, t_end] 且 t_start < t_end');
end

% 获取文件夹中所有 CNT 文件
cntFiles = dir(fullfile(folder, '*.cnt'));
if isempty(cntFiles)
    error('未找到 CNT 文件: %s', folder);
end

% 初始化变量
data = [];
label = [];
fs_temp = [];
fileList = {};

% 处理每个 CNT 文件
for i = 1:length(cntFiles)
    filePath = fullfile(cntFiles(i).folder, cntFiles(i).name);
    fileList{end+1} = filePath; %#ok<AGROW>
    
    try
        % 加载 CNT 文件
        EEG = pop_loadcnt(filePath, 'dataformat', 'int32');
        EEG = eeg_checkset(EEG);
        
        % 通道选择
        allChanLabels = {EEG.chanlocs.labels};
        [validChans, chanIdx] = ismember(chaninfo, allChanLabels);
        
        if any(~validChans)
            missingChans = chaninfo(~validChans);
            warning('文件 %s 缺少电极: %s', cntFiles(i).name, strjoin(missingChans, ', '));
        end
        
        % 提取有效通道数据
        validIdx = chanIdx(validChans);
        eegdata = double(EEG.data(validIdx, :));
        
        % 提取事件信息
        events = EEG.event;
        eventTypes = arrayfun(@(x) x.type, events, 'UniformOutput', false);
        eventLatencies = round([events.latency]);
        
        % 验证事件类型为数值
        if all(cellfun(@isnumeric, eventTypes))
            eventTypes = cell2mat(eventTypes);
        else
            error('文件 %s 包含非数值事件类型', cntFiles(i).name);
        end
        
        % 计算每个试次的时间点范围
        epochDuration = diff(timewindow) * EEG.srate;
        epochStart = eventLatencies + round(timewindow(1) * EEG.srate);
        
        % 验证时间窗有效性
        if any(epochStart < 1) || any(epochStart + epochDuration - 1 > size(eegdata, 2))
            error('文件 %s 的时间窗超出数据范围', cntFiles(i).name);
        end
        
        % 提取试次数据
        samples = zeros(size(eegdata, 1), epochDuration, numel(events));
        for trial = 1:numel(events)
            startIdx = epochStart(trial);
            endIdx = startIdx + epochDuration - 1;
            samples(:, :, trial) = eegdata(:, startIdx:endIdx);
        end
        
        % 降采样处理
        if ~isempty(fs)
            % 使用更高效的 resample 方法
            samples = resampleData(samples, EEG.srate, fs);
            currentFs = fs;
        else
            currentFs = EEG.srate;
        end
        
        % 合并数据
        data = cat(3, data, samples);
        label = [label; eventTypes(:)]; %#ok<AGROW>
        fs_temp(end+1) = currentFs; %#ok<AGROW>
        
    catch ME
        warning('文件 %s 处理失败: %s', cntFiles(i).name, ME.message);
    end
end

% 验证是否有有效数据
if isempty(data)
    error('未成功提取任何有效数据');
end

% 创建信息结构
Info.chaninfo = chaninfo;
Info.period = timewindow;
Info.filelist = fileList;

% 处理采样率信息
if ~isempty(fs)
    Info.fs = fs;
else
    if numel(unique(fs_temp)) > 1
        error('采样率不一致: %s Hz。请设置统一的降采样频率', num2str(unique(fs_temp)));
    end
    Info.fs = fs_temp(1);
end
end
