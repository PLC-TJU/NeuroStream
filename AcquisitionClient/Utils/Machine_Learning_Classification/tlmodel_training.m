%% 迁移学习模型训练
% 仅用于二分类
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.5.1

function Model = tlmodel_training(sdata,slabel,tdata,tlabel,alg,freqs,times,chans)
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
stype=unique(slabel);
ttype=unique(tlabel);
if ~isequal(stype(1:2),ttype(1:2)); error('源域与目标域的样本标签不一致');end:
sdata=sdata(:,:,slabel<=stype(2));
slabel=slabel(slabel<=stype(2));
tdata=tdata(:,:,tlabel<=ttype(2));
tlabel=tlabel(tlabel<=ttype(2));

% 降采样
originalFs=1000;
targetFs=250;
temp=resample(permute(sdata,[2,1,3]),targetFs,originalFs);
sdata=permute(temp,[2,1,3]);
temp=resample(permute(tdata,[2,1,3]),targetFs,originalFs);
tdata=permute(temp,[2,1,3]);

%% 对于RSFDA和Stacking集成模型
if strcmpi(alg,'RSFDA')
    Model = rsfda_modeling(sdata, slabel, tdata, tlabel, targetFs, times(end));
    Model.originalFs=originalFs;
    Model.targetFs=targetFs;
    return;
elseif strcmpi(alg, 'Stacking') %'Stacking_TL'
    algs ={'CSP','FgMDM','TSM','SBLEST'};
    Model = stacking_tlmodeling(sdata, slabel, tdata, tlabel, algs, targetFs, times(end));
    Model.originalFs=originalFs;
    Model.targetFs=targetFs;
    return;
end

%% 对于单个标准模型或Ensemble模型
% 时频滤波
fs=targetFs;
filterorder=5;
filterflag = 'filtfilt';

fsdata=ERPs_Filter(sdata,freqs,chans,times,fs,filterorder,filterflag);
ftdata=ERPs_Filter(tdata,freqs,chans,times,fs,filterorder,filterflag);

% 数据对齐
method_mean = 'euclid';

scov = covariances(fsdata,'scm');
mscov = mean_covariances(scov, method_mean);
Ms = mscov^-0.5;
asdata = zeros(size(fsdata));
for i=1:size(fsdata,3)
    asdata(:,:,i) = Ms*fsdata(:,:,i);
end

tcov = covariances(ftdata,'scm');
mtcov = mean_covariances(tcov, method_mean);
Mt = mtcov^-0.5;
atdata = zeros(size(ftdata));
for i=1:size(ftdata,3)
    atdata(:,:,i) = Mt*ftdata(:,:,i);
end

% 样本混合
fdata=cat(3,asdata,atdata);
label=cat(1,slabel,tlabel);

% 筛选通道
flag=false;
[fdata, selChan] = selectEEGChannels(fdata, label, [], flag);

% 空间滤波
[Wrsf, fdata]=RSF(fdata, label);

% 建模
Model = p_modeling(fdata,label,alg);

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
Model.method_mean=method_mean;
Model.M = Mt;
Model.selChan=selChan;
Model.Wrsf=Wrsf;

% 修正字段名（如果包含小数点）
if contains(Model.name, '.')
    Model.name = strrep(Model.name, '.', '_');
end

end