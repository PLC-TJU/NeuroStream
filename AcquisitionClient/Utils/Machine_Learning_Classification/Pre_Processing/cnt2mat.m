%% 数据整理 cnt2mat
% 输入
% folder为.cnt文件所在文件夹的地址，返回该文件夹下所有.cnt文件中脑电样本的合集
% timewindow=[t1,t2]:以标签时刻为0点，提取相对标签[t1,t2]范围类的数据点
% chaninfo:提取的脑电电极名称信息，cell，例如：{'FP1','FPZ','FP2',...}
% fs:降采样频率，默认为空，表示不进行降采样
% 输出
% data:n_channels * n_points * n_trials
% label:n_trials*1
% Info:数据信息，包含导联信息（Info.chaninfo），时间窗信息（Info.period）和采样率信息（Info.fs）
function [data,label,Info]=cnt2mat(folder,timewindow,chaninfo,fs)
if nargin<4
    fs=[];
end
if nargin<3 || isempty(chaninfo)
    chaninfo=chansel(28);
end
if nargin<2 || isempty(timewindow)
    timewindow=[0,4];
end

data=[];
label=[];
cntFiles=dir(fullfile(folder, '*.cnt'));
if isempty(cntFiles)
    error('未找到CNT文件');
end
fs_temp=zeros(length(cntFiles),1);
for i=1:length(cntFiles)
    EEG = pop_loadcnt([cntFiles(i).folder,'\',cntFiles(i).name], 'dataformat', 'int32');
    EEG = eeg_checkset(EEG);
%     %不建议使用以下几项pop_功能，除非你在在线分类识别过程中也一致应用这些pop_函数
%     EEG = pop_select(EEG,'channel',chanSynAmps);%通道选择
%     EEG = pop_reref(EEG,[]);%共平均
%     EEG = pop_rmbase(EEG,[]);%去基线
%     EEG = pop_resample(EEG,fs);%降采样
%     eegdata=double(EEG.data);

    % 通道选择
    AllChanInfo=cell(length(EEG.chanlocs),1);
    for c=1:length(EEG.chanlocs)
        AllChanInfo{c}=EEG.chanlocs(c).labels;
    end
    [~,ChanInd]=ismember(chaninfo,AllChanInfo);
    eegdata=double(EEG.data(ChanInd,:));

    % 提取出相应的样本及其标签
    event=EEG.event;
    type=zeros(length(EEG.event),1);
    latency=zeros(length(EEG.event),1);
    for m=1:length(EEG.event)
        type(m,1)=event(m).type;
        latency(m,1)=round(event(m).latency);
    end
    samples=zeros(size(eegdata,1),(timewindow(2)-timewindow(1))*EEG.srate,length(type));
    for trial=1:length(type)
        samples(:,:,trial)=eegdata(:,latency(trial)+timewindow(1)*EEG.srate:latency(trial)+timewindow(2)*EEG.srate-1);
    end

    %降采样
    if ~isempty(fs)
        temp=resample(permute(samples, [2,1,3]), fs, EEG.srate);
        samples=permute(temp,[2,1,3]);
    else
        fs_temp(i)=EEG.srate;
    end

    data=cat(3,data,samples);
    label=cat(1,label,type);
end

Info.chaninfo=chaninfo;
Info.period=timewindow;%相对标签的时刻
if ~isempty(fs)
    Info.fs=fs;
else
    if all(fs_temp == fs_temp(1))
        Info.fs=fs_temp(1);
    else
        error('各个.cnt文件的采样率不一致，请统一设置fs值！');
    end
end
end

function chan = chansel(num)
switch num
    case 28
        %28导联(PLC常用导联)
        chanSynAmps={'FC5';'FC3';'FC1';'FCZ';'FC2';'FC4';'FC6';...
            'C5';'C3';'C1';'CZ';'C2';'C4';'C6';...
            'CP5';'CP3';'CP1';'CPZ';'CP2';'CP4';'CP6';...
            'P5';'P3';'P1';'PZ';'P2';'P4';'P6'}; 
    case 60
        %60导联(常用全脑区)
        chanSynAmps={'FP1','FPZ','FP2','AF3','AF4',...
            'F7','F5','F3','F1','FZ','F2','F4','F6','F8',...
            'FT7','FC5','FC3','FC1','FCZ','FC2','FC4','FC6','FT8',...
            'T7','C5','C3','C1','CZ','C2','C4','C6','T8',...
            'TP7','CP5','CP3','CP1','CPZ','CP2','CP4','CP6','TP8',...
            'P7','P5','P3','P1','PZ','P2','P4','P6','P8',...
            'PO7','PO5','PO3','POZ','PO4','PO6','PO8',...
            'O1','OZ','O2'}; 
end
chan = chanSynAmps;
end

