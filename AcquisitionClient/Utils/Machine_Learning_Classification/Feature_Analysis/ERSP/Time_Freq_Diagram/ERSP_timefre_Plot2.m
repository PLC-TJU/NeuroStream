%% 时频分析(根据ERSP画C3、C4导联处时频能量图)
% 来源: Pan LC. 2021.3.15
function [ERSP,freqs,times,powbase,ERSP_All]=ERSP_timefre_Plot2(PlotData,Label,channel,pmax,Passband,subject)
% PlotData: 要进行分析的数据：导联*长度*样本
% Label: 对应PlotData的标签，N*1
% channel: 数据所采集的导联
% SJ: 被试名称
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
for ch=1:ChanNum
    for cl=1:ClassNum
        for i=size(SmpData{cl},3)
            temp{cl}(ch,(i-1)*frames+1:i*frames)=SmpData{cl}(ch,:,i);%C3 26
        end
    end
end

%标题列表
for ch=1:ChanNum
    for cl=1:ClassNum
        title_ind{ch,cl}=['类别:',Category{cl},'-通道:',chanSynAmps{chan(ch)}];
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
for num1=1:ClassNum
    for num2=1:ChanNum
        subplot(ClassNum,ChanNum,(num1-1)*ChanNum+num2)
        [ERSP{labelNum(num1)}(:,:,num2),~,powbase(:,num2,num1),times,freqs,~,~,ERSP_All{labelNum(num1)}(:,:,num2,:)]=plc_newtimef(temp{num1}(num2,:),frames,tlimits,fs,cycles,'erspmax',pmax,'freqs',Passband,'plotitc','off','plotersp','on',...
            'timesout',200,'verbose','off','basenorm',basenorm,'baseline',baseline,'padratio',8,'timesout',300); % 'baseline',[-1000 0]
        hold on
        plot([0 0]./1000,[0 Passband(end)],'--k','LineWidth',2); % plot time 0
        hold off
        subplot_M_N_p(ClassNum,ChanNum,(num1-1)*ChanNum+num2);
        title(title_ind{num2,num1},'fontsize',15,'FontName','微软雅黑','FontWeight','bold');
        ax(num1,num2)=gca;
        set(gca,'FontSize',15);

        if num2>1
            set(gca,'YTickLabel',[],'YTick',[])
            ylabel('');
        end
        if num1<ClassNum
            set(gca,'XTickLabel',[],'XTick',[])
            xlabel('');
        end
    end
end

% 添加colorbar
cb1=cbar('vert',0,[-pmax,pmax],5);

pos1=get(ax(1,1),'position');
pos2=get(ax(ClassNum,ChanNum),'position');
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