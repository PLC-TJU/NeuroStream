%% 时频分析(计算各类样本平均的各导联ERSP)
% 来源: Pan LC. 2021.3.15
function [ERSP,freqs,times,powbase,ERSP_All]=ERSP_timefre_Calcu(PlotData,Label,passband,timewindow,fs)
% 输入：
% PlotData: 要进行分析的数据：导联C*长度T*样本N
% Label: 对应PlotData的标签，N*1
% timewindow: 数据的时间窗范围
% passband: 返回的ERSP值的频率范围
% fs: 信号采样率

% 输出：
% ERSP: 元胞数组（大小为类别数*1），每一个元胞包含三维（频率*时间*导联）的ERSP值矩阵。
% ERSP_All: 元胞数组（大小为类别数*1），每一个元胞包含四维（频率*时间*导联*样本）的ERSP值矩阵。
% ERSP即是ERSP_All中相应类别的样本的平均值，即ERSP=mean(ERSP_All,4);
% freqs: ERSP的频率点数，点数越多频率分辨率越高（单位为Hz）
% times: ERSP的时间点数，点数越多时间分辨率越高（单位为ms）
% powbase: 基线的ERSP值，大小为三维（频率*时间*导联）矩阵。

%% 默认降采样为250Hz
if nargin< 6
    fs=250;
end
frames=size(PlotData,2);%试次样本点数

%% 样本整理
labelNum=unique(Label);
ClassNum=length(labelNum);
channel=1:size(PlotData,1);
SmpData=cell(ClassNum,1);
for i=1:ClassNum
    SmpData{i}=PlotData(:,:,Label==labelNum(i));
end

% 数据排列
%1:C3-LH;2:C3-RH;3:C3-FT;
%4:C4-LH;5:C4-RH;6:C4-FT;
temp=cell(ClassNum,1);
for cl=1:ClassNum
    for i=1:size(SmpData{cl},3)
        for ch=1:length(channel)
            temp{cl}(ch,(i-1)*frames+1:i*frames)=SmpData{cl}(ch,:,i);%C3 26
        end
    end
end

%% 确定静息期/任务期
% TaskDuration=4;
% RestDuration=frames/fs-TaskDuration;
% tlimits=[-1000*RestDuration,TaskDuration*1000-1];%时间范围 0为刺激点
tlimits=timewindow*1000;
% 选择基线
basenorm='off';                  %是否使用归一化去基线
baseline=[1000*timewindow(1),0];%默认基线为静息期
% baseline=NaN;
%% ERSP计算
cycles=0; %0代表选择stft
ERSP=cell(labelNum(end),1);
ERSP_All=cell(labelNum(end),1);
for num1=1:ClassNum
    for num2=1:length(channel)
        % ,'padratio',8,'timesout',200,'nfreqs',150
        [~,~,powbase(:,num2,num1),times,freqs, ...
            ~,~,~,PA]=newtimef(temp{num1}(num2,:),frames,tlimits,fs,cycles, ...
            'freqs',passband,'plotitc','off','plotersp','off','verbose','off', ...
            'baseline',baseline,'basenorm',basenorm,'detrend','on','rmerp','on'); %#ok
        ERSP_All{num1}(:,:,num2,:)=PA;
    end
end

%% 剔除离群值
for c=1:ClassNum
    P=squeeze(mean(ERSP_All{c}(:,times>0,:,:),[1,2,3]));
    [~,ind] = rmoutliers(P,'ThresholdFactor',4);
    P_opt = ERSP_All{c}(:,:,:,~ind);
    basePower = squeeze(mean(P_opt(:,times<=0,:,:), [2, 4]));%f*ch
    PP=nan(size(P_opt));
    for s=1:size(PP,4)
        for n=1:size(PP,3)
            PP(:,:,n,s)=bsxfun(@rdivide, P_opt(:,:,n,s), basePower(:,n));
        end
    end
    PP = single(PP);
    ERSP_All{c} = PP;
    meanERSP = mean(PP,4);
    ERSP{c} = real(10*log10(meanERSP));
end

end

