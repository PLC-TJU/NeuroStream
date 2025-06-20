%% 时频分析(根据ERSP画C3、C4导联处时频能量图)
% 来源: Pan LC. 2021.3.15
function ERSP_timefre_Plot(PlotData,Label,channel,pmax,Passband,subject)
% PlotData: 要进行分析的数据：导联*长度*样本
% Label: 对应PlotData的标签，N*1
% channel: 数据所采集的导联
% subject: 被试名称
% pmax: 图像颜色对比度范围
% Passband: PlotData的频率范围

%
if nargin< 6
    subject=[];
end

%% 默认降采样为250Hz
fs=250;
frames=size(PlotData,2);%试次样本点数

%% 导联信息
if size(PlotData,1)~=length(channel)
    error('导联信息与数据不符!');
end
persistent chanSynAmps Category
if isempty(chanSynAmps)
    if ~iscell(channel)
        if length(channel)==28
            chanSynAmps={'FC5';'FC3';'FC1';'FCZ';'FC2';'FC4';'FC6';...
                'C5';'C3';'C1';'CZ';'C2';'C4';'C6';...
                'CP5';'CP3';'CP1';'CPZ';'CP2';'CP4';'CP6';...
                'P5';'P3';'P1';'PZ';'P2';'P4';'P6'}; %28导联(Pan.LC MI实验简化版设置)
        elseif length(channel)==60
            chanSynAmps={'FP1','FPZ','FP2','AF3','AF4','F7','F5','F3','F1','FZ','F2','F4','F6','F8','FT7','FC5','FC3',...
                'FC1','FCZ','FC2','FC4','FC6','FT8','T7','C5','C3','C1','CZ','C2','C4','C6','T8','TP7','CP5','CP3',...
                'CP1','CPZ','CP2','CP4','CP6','TP8','P7','P5','P3','P1','PZ','P2','P4','P6','P8','PO7','PO5','PO3',...
                'POZ','PO4','PO6','PO8','O1','OZ','O2'}; %60导联(常用全脑区)
        elseif length(channel)==62
            chanSynAmps={'FP1','FPZ','FP2','AF3','AF4','F7','F5','F3','F1','FZ','F2','F4','F6','F8','FT7','FC5','FC3',...
                'FC1','FCZ','FC2','FC4','FC6','FT8','T7','C5','C3','C1','CZ','C2','C4','C6','T8','TP7','CP5','CP3',...
                'CP1','CPZ','CP2','CP4','CP6','TP8','P7','P5','P3','P1','PZ','P2','P4','P6','P8','PO7','PO5','PO3',...
                'POZ','PO4','PO6','PO8','CB1','O1','OZ','O2','CB2'}; %62导联(常用全脑区)
        elseif length(channel)==68
            chanSynAmps={'FP1','FPZ','FP2','AF3','AF4','F7','F5','F3','F1','FZ','F2','F4','F6','F8','FT7','FC5','FC3',...
                'FC1','FCZ','FC2','FC4','FC6','FT8','T7','C5','C3','C1','CZ','C2','C4','C6','T8','M1','TP7','CP5','CP3',...
                'CP1','CPZ','CP2','CP4','CP6','TP8','M2','P7','P5','P3','P1','PZ','P2','P4','P6','P8','PO7','PO5','PO3',...
                'POZ','PO4','PO6','PO8','CB1','O1','OZ','O2','CB2','HEO','VEO','EKG','EMG'}; %68导联(全导联)
        else
            error('请在“ERSP_timefre_Plot.m”函数中补充导联设置！');
        end
    else
        chanSynAmps=channel;
    end
end
[~,C3]=ismember('C3',chanSynAmps);
[~,C4]=ismember('C4',chanSynAmps);
% [~,CZ]=ismember('CZ',chanSynAmps);
% chan =[C3,C4,CZ]; %C3、C4、CZ导联索引
chan =[C3,C4]; %C3、C4、CZ导联索引
ChanNum=length(chan);

if isempty(Category)
    Category={'LH','RH','FT','4未命名','5未命名','6未命名'};
end

%% 样本整理
labelNum=unique(Label);
ClassNum=length(labelNum);
SmpData=cell(ClassNum,1);
for i=1:ClassNum
    SmpData{i}=PlotData(:,:,Label==labelNum(i));
end
%数据排列
%1:C3-LH;2:C3-RH;3:C3-FT;
%4:C4-LH;5:C4-RH;6:C4-FT;
%7:Cz-LH;8:Cz-RH;9:Cz-FT;
for i=1:size(SmpData{1},3)
    num=1;
    for ch=chan
        for cl=1:ClassNum
            temp(num,(i-1)*frames+1:i*frames)=SmpData{cl}(ch,:,i);%C3 26
            num=num+1;
        end
    end
end
%标题列表
num=1;
for ch=chan
    for cl=1:ClassNum
        title_ind{num}=['类别:',Category{cl},'-通道:',chanSynAmps{ch}];
        num=num+1;
    end
end

%% 确定静息期/任务期
% RestDuration=4;
TaskDuration=4;
RestDuration=frames/fs-TaskDuration;
tlimits=[-1000*RestDuration,TaskDuration*1000-1];%时间范围 0为刺激点
%% 选择基线
basenorm='on';                 %是否去基线（on/off）
baseline=[-1000*RestDuration,0];%默认基线为静息期
if strcmp(basenorm,'on')
    ERSPscale='dB';
else
    ERSPscale='std.';
end

%% ERSP时频图
figure;
cycles=0; %0代表选择stft
for ty=1:ChanNum*ClassNum
    subplot(ChanNum,ClassNum,ty)
    plc_newtimef(temp(ty,:),frames,tlimits,fs,cycles,'erspmax',pmax,'freqs',Passband,'plotitc','off','plotersp','on',...
        'timesout',200,'verbose','off','basenorm',basenorm,'baseline',baseline); % 'baseline',[-1000 0]
    hold on
    plot([0 0]./1000,[0 Passband(end)],'--k','LineWidth',2); % plot time 0
    hold off
    subplot_M_N_p(ChanNum,ClassNum,ty);
    title(title_ind{ty},'fontsize',15,'FontName','微软雅黑','FontWeight','bold');
    ax(ty)=gca;
    set(gca,'FontSize',15);
    if mod(ty,ClassNum)~=1
        set(gca,'YTickLabel',[],'YTick',[])
        ylabel('');
    end
    if ty<=(ChanNum-1)*ClassNum
        set(gca,'XTickLabel',[],'XTick',[])
        xlabel('');
    end
end

% 添加colorbar
cb1=cbar('vert',0,[-pmax,pmax],5);

pos1=get(ax(1),'position');
pos2=get(ax(end),'position');
width=0.1*pos1(3);
set(cb1,'FontSize',12,'position',[0.5*(pos2(1)+pos1(3)+1-width),pos2(2)+0.5*pos2(4),width,pos1(2)-pos2(2)]);

% set(gca,'FontSize',10,'position',[0.94,0.3,0.025,0.45]);
title([' PSD(',ERSPscale,')'],'fontsize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.02,0])

if ~isempty(subject)
    subtitle(['受试者: ',subject,' 时频图']);
end

%% ERSP曲线
% figure;
% alpha_band=[8 13];
% beta_band=[15 26];
% for ty=1:2*ClassNum
%     subplot(2,ClassNum,ty)
%     
%     plot(times/1000,mean(ERSP(freqs>alpha_band(1)&freqs<alpha_band(2),:,ty),1),'r','linewidth',3);
%     title([SJ title_ind{ty} ],'fontsize',16)
%     hold on
%     plot(times/1000,mean(ERSP(freqs>beta_band(1)&freqs<beta_band(2),:,ty),1),'b','linewidth',3);
%     title([SJ title_ind{ty} ],'fontsize',16)
%     if ty==2*ClassNum
%         legend(['alpha(' num2str(alpha_band(1)) '-' num2str(alpha_band(2)) 'Hz)'],['beta(' num2str(beta_band(1)) '-' num2str(beta_band(2)) 'Hz)']);
%     end
%     axis([min(times/1000),max(times/1000),-inf,inf]);
%     xlabel('time(s)')
%     ylabel('ERSP(dB)')
%     set(gca,'fontsize',14,'FontWeight','bold');
% %     set(gca,'ygrid','on');
%     set(get(gca,'Xlabel'),'Fontsize',16,'FontWeight','bold');
%     set(get(gca,'Ylabel'),'Fontsize',16,'FontWeight','bold');
%     
% end