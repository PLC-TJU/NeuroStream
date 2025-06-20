%% 根据ERSP绘制时频图
% 来源: Pan LC. 2021.11.11
% 输出：每一行表示不同类别，每一列表示不同天,最后一行表示同一天两类的差异性
function f=ERSPtoTimeFre_CrossDay(ERSP_All,freqs,times,channel,timewindow,freqsband,chanselect,subject)
% 必须输入
% ERSP_All: classnum*daynum(2) Cell(ERSP: freqs*times*channels*samples);
% freqs: ERSP的频率点数，点数越多频率分辨率越高（单位为Hz）
% times: ERSP的时间点数，点数越多时间分辨率越高（单位为ms）
% channel: ERSP的通道信息(长度应与ERSP值中第3维度相同)，应该为包含导联标签的元胞数组，例如{'C1','C3',...}

% 可选输入
% timewindow: 绘制时频图的ERSP时间窗范围，单位为s，例如[0,4]。默认为ERSP包含的全部时间。
% freqsband: 绘制时频图的ERSP频率范围，单位为Hz，例如[8,30]。默认为ERSP包含的全部频率。
% chanselect: 选择的通道标签，字符串，默认为'C3'。
% subject: 受试者名称（字符串），默认为空。

% 输出
% 时频图: 行数为ClassNum+1（最后一行是前两行时频图差异的显著性P值图），列数为DayNum。

if nargin< 8
    subject=[];
end
if nargin< 7 || isempty(chanselect)
    chanselect='C3';
end
if nargin< 6 || isempty(freqsband)
    freqsband=[ceil(freqs(1)),floor(freqs(end))];
end
if nargin< 5 || isempty(timewindow)
    timewindow=[ceil(times(1)),floor(times(end))]./1000;
end
if nargin< 4
    error('输入参数过少！')
end

[~,ChanInd]=ismember(chanselect,channel);
TimeInd=find(times>=1000*timewindow(1)&times<=1000*timewindow(2));
freqs=round(freqs,1);
FreqInd=find(freqs>=freqsband(1)&freqs<=freqsband(2));

DayNum=size(ERSP_All,2);
dayNum=1:DayNum;
labelNum=[];
for i=1:size(ERSP_All,1)
    if ~isempty(ERSP_All{i,1})
        labelNum=cat(2,labelNum,i);
    end
end
ClassNum=length(labelNum);
classType={'LH','RH'};
colorSet={[0,0.447,0.741];[0.85,0.325,0.098];[0.929,0.694,0.125]};
Significance=0.05; %显著性 p值

ERSP=cell(size(ERSP_All));
f=figure('color','w');
for class=1:ClassNum
    for day=1:DayNum
        subplot(ClassNum+1,DayNum,(class-1)*DayNum+day);
        ERSP_All{labelNum(class),day}=squeeze(ERSP_All{labelNum(class),day}(FreqInd,TimeInd,ChanInd,:));
        ERSP{class,day}=mean(ERSP_All{labelNum(class),day},3);
        subplot(ClassNum+1,DayNum,(class-1)*DayNum+day);
        %
        hold on
        ax(class,day)=imagesc(times(TimeInd)./1000,freqs(FreqInd),ERSP{class,day}).Parent;%#ok
        xlim([times(TimeInd(1))./1000,times(TimeInd(end))./1000])
        ylim([freqs(FreqInd(1)),freqs(FreqInd(end))])
        colormap(ax(class,day),jet);
        set(ax(class,day),'ydir','normal');
        plot(ax(class,day),[0,0],[freqs(FreqInd(1)),freqs(FreqInd(end))],'--k','linewidth',2);
        hold off
        %
        subplot_M_N_p(ClassNum+1,DayNum,(class-1)*DayNum+day);
        set(gca,'FontSize',12,'FontName','微软雅黑');
        title([classType{class},'-Day',num2str(day)],'fontsize',15,'color',colorSet{class},'FontName','微软雅黑','FontWeight','bold');%colorSet{class|day} 不同类或天不同颜色
        
        %% 去刻度
        if day==dayNum(1)%左上部分
            %去上下刻度
            set(gca,'xtick',[])
            %去除右刻度
            box off
            ax2 = axes('Position',get(gca,'Position'),...
                'YAxisLocation','right',...
                'Color','none',...
                'XColor','k','YColor','k','linewidth',1);
            set(ax2,'YTick', []);
            set(ax2,'XTick', []);
            box on
        else%右上部分
            set(gca,'xtick',[])%去上下刻度
            set(gca,'ytick',[])%去左右刻度
            box off
            ax2 = axes('Position',get(gca,'Position'),...
                'Color','none',...
                'XColor','k','YColor','k','linewidth',1);
            set(ax2,'YTick', []);
            set(ax2,'XTick', []);
            box on
        end
    end
end
%画显著性图谱
for day=1:DayNum
    subplot(ClassNum+1,DayNum,ClassNum*DayNum+day);
    temp1=ERSP_All{1,day};
    temp2=ERSP_All{2,day};
    [~,temp(:,:,day)]=ttest2(temp1,temp2,'Dim',3,'Tail','both','Alpha',Significance);%#ok
    
    temptemp=reshape(temp(:,:,day),[],1);
    FDR=mafdr(temptemp);%FDR校正
    temptemp(FDR>0.05)=1;
    temptemp(FDR<0.05)=0;
    temp(:,:,day)=reshape(temptemp,size(temp(:,:,day)));%#ok
%     temp(:,times(TimeInd)./1000<0,day)=1;%
    hold on
    ax(ClassNum+1,day)=imagesc(times(TimeInd)./1000,freqs(FreqInd),temp(:,:,day),[0,1]).Parent;
    xlim([times(TimeInd(1))./1000,times(TimeInd(end))./1000])
    ylim([freqs(FreqInd(1)),freqs(FreqInd(end))])
%     colormap(handle(ClassNum+1,day),autumn);
    set(ax(ClassNum+1,day),'ydir','normal');
    plot(ax(ClassNum+1,day),[0,0],[freqs(FreqInd(1)),freqs(FreqInd(end))],'--k','linewidth',2);
    hold off
    subplot_M_N_p(ClassNum+1,DayNum,ClassNum*DayNum+day);
    set(gca,'FontSize',12,'FontName','微软雅黑');
    title(ax(ClassNum+1,day),[classType{1},'-',classType{2}],'fontsize',15,'color','black','FontName','微软雅黑','FontWeight','bold')
    
    %% 去刻度
    if day==1%左下
        %去除上、右刻度
        box off
        ax2 = axes('Position',get(gca,'Position'),...
            'XAxisLocation','top',...
            'YAxisLocation','right',...
            'Color','none',...
            'XColor','k','YColor','k','linewidth',1);
        set(ax2,'YTick', []);
        set(ax2,'XTick', []);
        box on
    else%右下
        %去左右刻度
        set(gca,'ytick',[])
        %去除上刻度
        box off
        ax2 = axes('Position',get(gca,'Position'),...
            'XAxisLocation','top',...
            'Color','none',...
            'XColor','k','YColor','k','linewidth',1);
        set(ax2,'YTick', []);
        set(ax2,'XTick', []);
        box on
    end
end

%% 调整子图的颜色图尺度一致
Temp=[];
for class=1:ClassNum
    for day=1:DayNum
        Temp=cat(1,Temp,reshape(ERSP{class,day},[],1));
    end
end
Temp=rmoutliers(Temp,'mean');% 删除离群值
% Clim=[min(Temp),max(Temp)];
if max(abs(Temp))<10
    Clim=[-max(abs(Temp)),max(abs(Temp))];
else
    Clim=[-10,10];
end
for class=1:ClassNum
    for day=1:DayNum
        set(ax(class,day),'Clim',Clim)
    end
end
cb1=cbar('vert',0,Clim,5);

pos1=get(ax(1,DayNum),'position');
pos2=get(ax(ClassNum,DayNum),'position');
width=0.1*pos1(3);
set(cb1,'FontSize',12,'position',[0.5*(pos1(1)+pos1(3)+1)-width,pos2(2)+0.5*pos2(4),width,pos1(2)-pos2(2)+0.5*(pos1(4)-pos2(4))]);
title(cb1,'PSD(dB)','FontSize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.05,0]);
% set(gca,'FontSize',12,'position',get(handle(ClassNum,DayNum),'position').*[0,1,0,0.75]+[0.93,0.025,0.025,0.3]);

for day=1:DayNum
    set(ax(ClassNum+1,day),'Clim',[0,0.1])
    colormap(ax(ClassNum+1,day),'autumn');
end
cb2=colorbar(ax(ClassNum+1,day),'Ticks',0:0.05:0.1);
% cb2=cbar('vert',0,[0,0.1],5);

pos3=get(ax(ClassNum+1,DayNum),'position');
set(cb2,'FontSize',12,'position',[0.5*(pos1(1)+pos1(3)+1)-width,pos3(2),width,pos3(4)]);
title(cb2,'p值','fontsize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.05,0]);
% set(cb2,'fontsize',12,'position',get(cb2,'position').*[1.0684 1.3921 1.4270 0.7469]);

%% 添加横纵轴标签
if ~mod(size(ax,2),2)
    xt=annotation('textbox','String','时间(s)','FitBoxToText','on','EdgeColor','none',...
        'fontsize',15,'FontName','微软雅黑','HorizontalAlignment','center');
    pause(0.01);
    pos0=get(xt,'Position');
    pos1=get(ax(end,1),'Position');
    pos2=get(ax(end,DayNum),'Position');
%     set(xt,'Position',[0.5*(pos1(1)-pos0(3)),0.5*(pos1(2)+pos2(2)-pos0(4)),pos0(3),pos0(4)])
    set(xt,'Position',[0.5*(pos1(1)+pos2(1)+pos2(3)-pos0(3)),0.5*(pos1(2)-pos0(4)),pos0(3),pos0(4)])
else
    xlabel(ax(end,floor(median(1:DayNum))),'时间(s)','fontsize',15,'FontName','微软雅黑');%'Frequency(Hz)'
end
yt=ylabel(ax(floor(median(1:size(ax,1))),1),'频率(Hz)','fontsize',15,'FontName','微软雅黑');%'Power Spectral Density(dB)'
if ~mod(size(ax,1),2)
    set(yt,'Units','normalized','Position',[-0.2,-0.1,0])
end
%% 
% 设置背景为白色
% set(pic_timefre,'color','w')
if ~isempty(subject)
    subtitle(['受试者: ',subject,' 时频图']);
end
end
%print(gcf,'-r330','-dpng','C:\Users\潘林聪\Desktop\2-12x');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-12x.fig')