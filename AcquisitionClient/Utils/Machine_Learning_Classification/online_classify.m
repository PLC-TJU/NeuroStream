%% 在线分类预测
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.5.1

function [prediction, dv, acc] = online_classify(model, data, label)
if ~exist('label','var') || isempty(label)
    label=[];
end

% 处理单个样本输入(非必须)
if ismatrix(data)
    data = reshape(data, size(data,1), size(data,2), 1);
end

% 降采样
originalFs=model.originalFs;
targetFs=model.targetFs;
temp=resample(permute(data, [2,1,3]),targetFs,originalFs);
data=permute(temp,[2,1,3]);

%% 对于Stacking集成模型
if strcmpi(model.name,'Stacking')
    [prediction, dv, acc] = stacking_classify(model, data, label);
    return;
elseif strcmpi(model.name,'Stacking_TL')
    [prediction, dv, acc] = stacking_tlclassify(model, data, label);
    return;
elseif strcmpi(model.name,'RSFDA')
    [prediction, dv, acc] = rsfda_classify(model, data, label);
    return;
end

%% 对于单个标准模型或Ensemble模型
% 时频滤波
freqs=model.freqs;
channel=model.chans;
timewindow=model.times;
fs=targetFs;
filterorder=model.filterorder;
filterflag = model.filterflag;
fdata=ERPs_Filter(data,freqs,channel,timewindow,fs,filterorder,filterflag);

% 数据对齐
if isfield(model, 'M') && ~isempty(model.M)
    for i=1:size(fdata,3)
        fdata(:,:,i)=model.M*fdata(:,:,i);
    end
end

% 筛选通道
fdata = fdata(model.selChan,:,:);

% 空间滤波
if isfield(model, 'Wrsf') && ~isempty(model.Wrsf)
    temp=nan(size(model.Wrsf,2),size(fdata,2),size(fdata,3));
    for i=1:size(fdata,3)
        temp(:,:,i)=model.Wrsf'*fdata(:,:,i);
    end
end
fdata=temp;

% 分类预测
[prediction, dv, acc] = p_classify(model, fdata, label);

end