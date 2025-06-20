%% 根据ERSP绘制时频图
% 来源: Pan LC. 2021.11.11
function f=ERSPtoTimeFre_CrossDay2(ERSP_All,freqs,times,channel,timewindow,freqsband,chanselect,subject)
% 必须输入
% ERSP_All: classnum*daynum(2) Cell(ERSP: freqs*times*channels*samples);
% freqs: ERSP的频率点数，点数越多频率分辨率越高（单位为Hz）
% times: ERSP的时间点数，点数越多时间分辨率越高（单位为ms）
% channel: ERSP的通道信息(长度应与ERSP值中第3维度相同)，应该为包含导联标签的元胞数组，例如{'C1','C3',...}

% 可选输入
% timewindow: 绘制时频图的ERSP时间窗范围，单位为s，例如[0,4]。默认为ERSP包含的全部时间。
% freqsband: 绘制时频图的ERSP频率范围，单位为Hz，例如[8,30]。默认为ERSP包含的全部频率。
% chanselect: 选择绘制的通道（大小为2的元胞数组），默认为{'C3','C4'}
% subject: 受试者名称（字符串），默认为空。

% 输出
% 时频图: 行数为daynum(2)+1（最后一行是前两行时频图差异的显著性P值图），
% 列数为ClassNum*2（2为选择的通道数）。

load('pvalue_colormap.mat','pvalue_colormap');
if nargin< 8
    subject=[];
end
if nargin< 7 || isempty(chanselect)
    chanselect={'C3','C4'};
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
labelNum=[];
for i=1:size(ERSP_All,1)
    if ~isempty(ERSP_All{i,1})
        labelNum=[labelNum,i];
    end
end
ClassNum=length(labelNum);
classNum=1:ClassNum;
classType={'LH','RH','FT'};
Significance=0.05; %显著性 p值

ERSP=cell(size(ERSP_All));
f=figure('color','w');

% t=tiledlayout(DayNum+1,ClassNum*2,'TileSpacing','tight');
%% C3
for day=1:DayNum
    for class=1:ClassNum

        ERSP_All_C3{labelNum(class),day}=squeeze(ERSP_All{labelNum(class),day}(FreqInd,TimeInd,ChanInd(1),:));
        ERSP{class,day}=mean(ERSP_All_C3{labelNum(class),day},3);

        subplot(DayNum+1,ClassNum*2,2*ClassNum*(day-1)+class);
        hold on
        ax(day,class)=imagesc(times(TimeInd)./1000,freqs(FreqInd),ERSP{class,day}).Parent;
        xlim([times(TimeInd(1))./1000,times(TimeInd(end))./1000])
        ylim([freqs(FreqInd(1)),freqs(FreqInd(end))])
        colormap(ax(day,class),jet);
        set(ax(day,class),'ydir','normal');
        plot(ax(day,class),[0,0],[freqs(FreqInd(1)),freqs(FreqInd(end))],'--k','linewidth',2);
        hold off
        subplot_M_N_p(DayNum+1,ClassNum*2,2*ClassNum*(day-1)+class);

        set(gca,'FontSize',13.5,'FontName','Times New Roman');
        title(['C3:',classType{class},'(Day',num2str(day),')'],'fontsize',15,'color','k','FontName','Times New Roman','FontWeight','bold');%colorSet{class|day} 不同类或天不同颜色
        set(gca,'XTick',[-2:1:3],'XTickLabel',{'-2','-1','0','1','2','3'});
        set(gca,'YTick',[1,10:10:40],'YTickLabel',{'1','10','20','30','40'});

        % 去刻度
        if class==classNum(1) 
            set(gca,'xtick',[])%去上下刻度
            box off
            ax2 = axes('Position',get(gca,'Position'),...
                'YAxisLocation','right',...
                'Color','none',...
                'XColor','k','YColor','k','linewidth',1);
            set(ax2,'YTick', []);
            set(ax2,'XTick', []);
            box on
        else 
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
for class=1:ClassNum
    subplot(DayNum+1,ClassNum*2,2*ClassNum*DayNum+class);

    temp1=ERSP_All_C3{class,1};
    temp2=ERSP_All_C3{class,2};
    [~,temp(:,:,day)]=ttest2(temp1,temp2,'Dim',3,'Tail','both','Alpha',Significance);
    
    temptemp=reshape(temp(:,:,day),[],1);
    FDR=mafdr(temptemp);%FDR校正
    temptemp(FDR>0.05)=1;
    temptemp(FDR<0.05)=0;
    temp(:,:,day)=reshape(temptemp,size(temp(:,:,day)));
    temp(:,times(TimeInd)./1000<0,day)=1;%
    hold on
    ax(DayNum+1,class)=imagesc(times(TimeInd)./1000,freqs(FreqInd),temp(:,:,day),[0,1]).Parent;
    xlim([times(TimeInd(1))./1000,times(TimeInd(end))./1000])
    ylim([freqs(FreqInd(1)),freqs(FreqInd(end))])
    colormap(ax(DayNum+1,class),pvalue_colormap);
    set(ax(DayNum+1,class),'ydir','normal');
    plot(ax(DayNum+1,class),[0,0],[freqs(FreqInd(1)),freqs(FreqInd(end))],'--k','linewidth',2);
    hold off
    subplot_M_N_p(DayNum+1,ClassNum*2,2*ClassNum*DayNum+class);
    set(gca,'FontSize',12,'FontName','Times New Roman');
    title(ax(DayNum+1,class),['C3:',classType{class},'(Day1 vs Day2)'],'fontsize',15,'color','black','FontName','Times New Roman','FontWeight','bold')
    
    set(gca,'XTick',[-2:1:3],'XTickLabel',{'-2','-1','0','1','2','3'});
    %% 去刻度
    if class~=ClassNum
        box off
        ax2 = axes('Position',get(gca,'Position'),...
            'Color','none',...
            'XColor','k','YColor','k','linewidth',1);
        set(ax2,'YTick', []);
        set(ax2,'XTick', []);
        box on
    else
        %去左右刻度
        set(gca,'ytick',[])
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

%% C4
for day=1:DayNum
    for class=1:ClassNum

        ERSP_All_C4{labelNum(class),day}=squeeze(ERSP_All{labelNum(class),day}(FreqInd,TimeInd,ChanInd(2),:));
        ERSP{class,day}=mean(ERSP_All_C4{labelNum(class),day},3);

        subplot(DayNum+1,ClassNum*2,2*ClassNum*(day-1)+class+2);
        hold on
        ax(day,class+2)=imagesc(times(TimeInd)./1000,freqs(FreqInd),ERSP{class,day}).Parent;
        xlim([times(TimeInd(1))./1000,times(TimeInd(end))./1000])
        ylim([freqs(FreqInd(1)),freqs(FreqInd(end))])
        colormap(ax(day,class+2),jet);
        set(ax(day,class+2),'ydir','normal');
        plot(ax(day,class+2),[0,0],[freqs(FreqInd(1)),freqs(FreqInd(end))],'--k','linewidth',2);
        hold off
        subplot_M_N_p(DayNum+1,ClassNum*2,2*ClassNum*(day-1)+class+2);

        set(gca,'FontSize',13.5,'FontName','Times New Roman');
        title(['C4:',classType{class},'(Day',num2str(day),')'],'fontsize',15,'color','k','FontName','Times New Roman','FontWeight','bold');%colorSet{class|day} 不同类或天不同颜色
        set(gca,'XTick',[-2:1:3],'XTickLabel',{'-2','-1','0','1','2','3'});
        set(gca,'YTick',[1,10:10:40],'YTickLabel',{'1','10','20','30','40'});

        % 去刻度
        set(gca,'xtick',[])%去上下刻度
        set(gca,'ytick',[])%去左右刻度
        box off
        ax2 = axes('Position',get(gca,'Position'),...
            'YAxisLocation','right',...
            'Color','none',...
            'XColor','k','YColor','k','linewidth',1);
        set(ax2,'YTick', []);
        set(ax2,'XTick', []);
        box on

    end
end

%画显著性图谱
for class=1:ClassNum
    subplot(DayNum+1,ClassNum*2,2*ClassNum*DayNum+class+2);

    temp1=ERSP_All_C4{class,1};
    temp2=ERSP_All_C4{class,2};
    [~,temp(:,:,day)]=ttest2(temp1,temp2,'Dim',3,'Tail','both','Alpha',Significance);
    
    temptemp=reshape(temp(:,:,day),[],1);
    FDR=mafdr(temptemp);%FDR校正
    temptemp(FDR>0.05)=1;
    temptemp(FDR<0.05)=0;
    temp(:,:,day)=reshape(temptemp,size(temp(:,:,day)));
    temp(:,times(TimeInd)./1000<0,day)=1;%
    hold on
    ax(DayNum+1,class+2)=imagesc(times(TimeInd)./1000,freqs(FreqInd),temp(:,:,day),[0,1]).Parent;
    xlim([times(TimeInd(1))./1000,times(TimeInd(end))./1000])
    ylim([freqs(FreqInd(1)),freqs(FreqInd(end))])
    colormap(ax(DayNum+1,class+2),pvalue_colormap);
    set(ax(DayNum+1,class+2),'ydir','normal');
    plot(ax(DayNum+1,class+2),[0,0],[freqs(FreqInd(1)),freqs(FreqInd(end))],'--k','linewidth',2);
    hold off
    subplot_M_N_p(DayNum+1,ClassNum*2,2*ClassNum*DayNum+class+2);
    set(gca,'FontSize',12,'FontName','Times New Roman');
    title(ax(DayNum+1,class+2),['C4:',classType{class},'(Day1 vs Day2)'],'fontsize',15,'color','black','FontName','Times New Roman','FontWeight','bold')
    
    set(gca,'XTick',[-2:1:3],'XTickLabel',{'-2','-1','0','1','2','3'});
    %% 去刻度        
    set(gca,'ytick',[])%去左右刻度
    box off
    ax2 = axes('Position',get(gca,'Position'),...
        'XAxisLocation','top',...
        'Color','none',...
        'XColor','k','YColor','k','linewidth',1);
    set(ax2,'YTick', []);
    set(ax2,'XTick', []);
    box on

end


%% 调整子图的颜色图尺度一致
Clim=[-5,5];
for class=1:ClassNum*2
    for day=1:DayNum
        set(ax(day,class),'Clim',Clim)
    end
end
% cb1=cbar('vert',0,Clim,5);
cb1=colorbar(ax(day,class),'Ticks',-5:5:5);

pos1=get(ax(1,ClassNum*2),'position');
pos2=get(ax(DayNum,ClassNum*2),'position');
width=0.1*pos1(3);
set(cb1,'FontSize',12,'position',[0.5*(pos1(1)+pos1(3)+1)-width,pos2(2)+0.5*pos2(4),width,pos1(2)-pos2(2)+0.5*(pos1(4)-pos2(4))]);
title(cb1,'PSD(dB)','FontSize',12,'FontName','Times New Roman','Units','normalized','Position',[0.5,1.05,0]);

for class=1:ClassNum*2
    set(ax(DayNum+1,class),'Clim',[0,0.1])
%     colormap(ax(DayNum+1,class),pvalue_colormap);
end
cb2=colorbar(ax(DayNum+1,ClassNum*2),'Ticks',0:0.05:0.1);


pos3=get(ax(DayNum+1,ClassNum*2),'position');
set(cb2,'FontSize',12,'position',[0.5*(pos1(1)+pos1(3)+1)-width,pos3(2),width,pos3(4)]);
title(cb2,'p value','fontsize',12,'FontName','Times New Roman','Units','normalized','Position',[0.5,1.05,0]);

%% 添加横纵轴标签
if ~mod(size(ax,2),2)
    xt=annotation('textbox','String','Time(s)','FitBoxToText','on','EdgeColor','none',...
        'fontsize',15,'FontName','Times New Roman','HorizontalAlignment','center','FontWeight','bold');
    pause(0.01);
    pos0=get(xt,'Position');
    pos1=get(ax(end,1),'Position');
    pos2=get(ax(end,end),'Position');
%     set(xt,'Position',[0.5*(pos1(1)-pos0(3)),0.5*(pos1(2)+pos2(2)-pos0(4)),pos0(3),pos0(4)])
    set(xt,'Position',[0.5*(pos1(1)+pos2(1)+pos2(3)-pos0(3)),0.5*(pos1(2)-pos0(4)),pos0(3),pos0(4)])
else
    xlabel(ax(end,floor(median(1:ClassNum+1))),'Time(s)','fontsize',15,'FontName','Times New Roman','FontWeight','bold');%'Frequency(Hz)'
end
yt=ylabel(ax(floor(median(1:size(ax,1))),1),'Frequency(Hz)','fontsize',15,'FontName','Times New Roman','FontWeight','bold');%'Power Spectral Density(dB)'
if ~mod(size(ax,1),2)
    set(yt,'Units','normalized','Position',[-0.2,-0.1,0])
end
%% 
% 设置背景为白色
% set(pic_timefre,'color','w')
if ~isempty(subject)
    subtitle(['Subject: ',subject,' Time-Frequency Spectrum']);
end
end
%print(gcf,'-r330','-dpng','C:\Users\潘林聪\Desktop\2-12x');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-12x.fig')