%% 标准模型训练
% 仅用于二分类
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.5.1

function Model = model_training(data,label,alg,freqs,times,chans)
if ~exist('alg','var') || isempty(alg)
    alg = 'CSP';
end
if ~exist('freqs','var') || isempty(freqs)
    freqs=[8,30];
end
if ~exist('times','var') || isempty(times)
    times=[];
end
if ~exist('chans','var') || isempty(chans)
    chans=[];
end

% 仅保留前两类标签
type=unique(label);
data=data(:,:,label<=type(2));
label=label(label<=type(2));

% 降采样
originalFs=1000;
targetFs=250;
temp=resample(permute(data,[2,1,3]),targetFs,originalFs);
data=permute(temp,[2,1,3]);

%% 对于Stacking集成模型
if strcmpi(alg,'Stacking')
    algs ={'CSP','FgMDM','TSM'};
    Model = stacking_modeling(data, label, algs, targetFs, times(end));
    Model.originalFs=originalFs;
    Model.targetFs=targetFs;
    return;
end

if strcmpi(alg,'RSFDA')
    error('RSFDA算法不适用于非迁移学习分类！')
end

%% 对于单个标准模型或Ensemble模型
% 时频滤波
fs=targetFs;
filterorder=5;
filterflag = 'filtfilt';
fdata=ERPs_Filter(data,freqs,chans,times,fs,filterorder,filterflag);

% 筛选通道
flag = false;
[fdata, selChan] = selectEEGChannels(fdata, label, [], flag);

% 空间滤波
[Wrsf, fdata]=RSF(fdata, label);

% 建模
Model = p_modeling(fdata, label, alg);

% 必须属性
% Model.name=alg;
Model.originalFs=originalFs;
Model.targetFs=targetFs;

% 预处理属性
Model.freqs=freqs;
Model.times=times;
Model.chans=chans;
Model.filterorder=filterorder;
Model.filterflag=filterflag;

% 分类相关属性
Model.selChan=selChan;
Model.Wrsf=Wrsf;

% 修正字段名（如果包含小数点）
if contains(Model.name, '.')
    Model.name = strrep(Model.name, '.', '_');
end

end