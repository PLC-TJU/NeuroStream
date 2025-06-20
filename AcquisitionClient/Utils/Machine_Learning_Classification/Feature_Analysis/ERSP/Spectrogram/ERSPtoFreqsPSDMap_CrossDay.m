%% Times-PSD频谱图  Type1
% v2.0c
% 来源: Pan LC. 2021.3.20
% 横轴: 不同类别
% 纵轴: 不同天
function f=ERSPtoFreqsPSDMap_CrossDay(ERSP_All,freqs,times,channel,timewindow,subject)
% 输入
% ERSP: classnum*days cell(freqs*times*channels);
% freqs,times:来自newtimef.m函数的输出
% freqwindow,subject:Too lazy to write!

if nargin< 6
    subject=[];
end
if nargin< 5 || isempty(timewindow)
    timewindow=[ceil(times(1)),floor(times(end))];
end
if nargin< 4
    error('输入参数过少！')
end

DayNum=size(ERSP_All,2);
dayNum=1:DayNum;
labelInd=[];
for i=1:size(ERSP_All,1)
    if ~isempty(ERSP_All{i,1})
        labelInd=[labelInd,i];
    end
end
ClassNum=length(labelInd);
classType={'LH','RH','FT'};
[~,C3]=ismember('C3',channel);
[~,C4]=ismember('C4',channel);
[~,CZ]=ismember('CZ',channel);
if ClassNum==3
    chan =[C3,C4,CZ]; %C3、C4、CZ导联索引
    % chan =[26,30];%chan =[9,13,11];
else
    chan =[C3,C4];
end
ChanNum=length(chan);
chanType={'C3','C4','Cz'};
Significance=0.05; %显著性 p值
ChanColor=[0,0.45,0.74;0.85,0.33,0.10;0.93,0.69,0.13];
IntervalRange=cell(ClassNum,DayNum);
AllPow=cell(ClassNum,DayNum);
Pow=zeros(size(ERSP_All{labelInd(1),1},1),ChanNum,ClassNum,DayNum);
Pow_Std=zeros(size(Pow));
Ylim=zeros(ClassNum,2);
for class=1:ClassNum
    for day=1:DayNum
        AllPow{class,day}=squeeze(mean(ERSP_All{labelInd(class),day}(:,times>1000*timewindow(1)&times<1000*timewindow(2),chan,:),2));
        Pow(:,:,class,day)=squeeze(mean(AllPow{class,day},3));
        %计算标准差
        Pow_Std(:,:,class,day)=squeeze(std(AllPow{class,day},0,3))*0.2;
%         %减小离群值
%         for ch=1:size(Pow_Std,2)
%             [~,Ind]=rmoutliers(Pow_Std(:,ch,class,day),'mean');
%             Pow_Std(Ind,ch,class,day)=mean(Pow_Std(~Ind,ch,class,day));
%         end
    end
    Ylim(class,:)=[min(Pow(:,:,class,:)-Pow_Std(:,:,class,:),[],'all'),max(Pow(:,:,class,:)+Pow_Std(:,:,class,:),[],'all')];
end

f=figure('color','w');
for class=1:ClassNum
    for day=1:DayNum
        subplot(ClassNum,DayNum,(class-1)*DayNum+day);
        allPow=AllPow{class,day};
        hold on
        %寻找ERD对侧占优显著区间
        switch class
            case 1
                XRange=freqs(ttest2(allPow(:,1,:),allPow(:,2,:),'Dim',3,'Tail','right','Alpha',Significance)==1);
            case 2
                XRange=freqs(ttest2(allPow(:,2,:),allPow(:,1,:),'Dim',3,'Tail','right','Alpha',Significance)==1);
            case 3
                XRange=freqs(ttest2(allPow(:,2,:),allPow(:,3,:),'Dim',3,'Tail','right','Alpha',Significance)==1);
        end
        if ~isempty(XRange)
            %分割区间
            SplitPoint=XRange(1);
            for n=1:length(XRange)-1
                if roundn(XRange(n+1)-XRange(n),-3)>roundn((freqs(end)-freqs(1))/(length(freqs)-1),-3)
                    SplitPoint=[SplitPoint,XRange(n),XRange(n+1)];
                end
            end
            SplitPoint(end+1)=XRange(end);
            SplitPoint=sort(SplitPoint);
            for num=1:length(SplitPoint)/2                
                B=BackgroundColor([SplitPoint(2*num-1),SplitPoint(2*num),Ylim(class,1),Ylim(class,2)]);
                IntervalRange{class,day}=[IntervalRange{class,day},SplitPoint(2*num-1):0.001:SplitPoint(2*num)];
            end
        end
        %画PSD曲线
        p{class,day}=plot(freqs,Pow(:,:,class,day),'linewidth',2);
        %画标准差范围
        for ch=1:ChanNum
            y_up=Pow(:,ch,class,day)+Pow_Std(:,ch,class,day);
            y_low=Pow(:,ch,class,day)-Pow_Std(:,ch,class,day);
            fill([freqs,fliplr(freqs)],[y_up',fliplr(y_low')],'c','FaceAlpha',0.2,'EdgeAlpha',0,'FaceColor',ChanColor(ch,:));
        end

        %标记每一列共同x区间
        if class==ClassNum                   
            for c=1:ClassNum-1
                IntervalRange{c+1,day}=intersect(roundn(IntervalRange{c,day},-3),roundn(IntervalRange{c+1,day},-3));
            end
            if ~isempty(IntervalRange{class,day})
                InterXRange=roundn(IntervalRange{class,day}(1):0.001:IntervalRange{class,day}(end),-3);
                [~,ind]=intersect(InterXRange,IntervalRange{c+1,day});
                InterYRange=NaN(length(InterXRange),1);
                InterYRange(ind)=Ylim(class,1)+0.25;
                plot(InterXRange,InterYRange,'linewidth',8,'color',[190 190 190]./256);
            end
        end
        
        hold off
        ax(class,day)=gca;
        subplot_M_N_p(ClassNum,DayNum,(class-1)*DayNum+day);
        if class==1 && day==1
            colorSet=get(p{1},'color');
        end        
        set(gca,'FontSize',12,'FontName','微软雅黑');
        title([classType{class},'-',num2str(day)],'color',colorSet{class},'FontSize',15,'FontName','微软雅黑','FontWeight','bold');%colorSet{class|day} 不同类或天不同颜色
        %% 去刻度
        if class~=labelInd(end) && day==dayNum(1)
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
        elseif class==labelInd(end) && day==dayNum(1)
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
        elseif class==labelInd(end) && day~=dayNum(1)
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

%% 调整每个子图的纵轴刻度一致
for class=1:ClassNum
    for day=1:DayNum
        set(ax(class,day),'ylim',Ylim(class,:))
%         set(ax(class,day),'ylim',[-5,5])
    end
end
%% 添加图例
P=[];
for ch=1:ChanNum
    P=[P,p{1,DayNum}(ch)];
end
% legend(P,chanType(1:ChanNum),'Location','best')
if exist("B","var")
    legend([P,B],[chanType(1:ChanNum),{'p<0.05'}],'FontSize',12,'FontName','微软雅黑','Location','northeast')%'southeast' 'best'
else
    legend(P,chanType(1:ChanNum),'FontSize',12,'FontName','微软雅黑','Location','northeast')
end
%% 添加横纵轴标签
if ~mod(size(ax,2),2)
    xt=annotation('textbox','String','频率(Hz)','FitBoxToText','on','EdgeColor','none',...
        'fontsize',15,'FontName','微软雅黑','HorizontalAlignment','center');
    pause(0.01);
    pos0=get(xt,'Position');
    pos1=get(ax(ClassNum,1),'Position');
    pos2=get(ax(ClassNum,DayNum),'Position');
%     set(xt,'Position',[0.5*(pos1(1)-pos0(3)),0.5*(pos1(2)+pos2(2)-pos0(4)),pos0(3),pos0(4)])
    set(xt,'Position',[0.5*(pos1(1)+pos2(1)+pos2(3)-pos0(3)),0.5*(pos1(2)-pos0(4)),pos0(3),pos0(4)])
else
    xlabel(ax(ClassNum,floor(median(1:DayNum))),'频率(Hz)','fontsize',15,'FontName','微软雅黑');%'Frequency(Hz)'
end
yt=ylabel(ax(floor(median(1:ClassNum)),1),'功率谱(dB)','fontsize',15,'FontName','微软雅黑');%'Power Spectral Density(dB)'
if ~mod(size(ax,1),2)
    set(yt,'Units','normalized','Position',[-0.2,-0.1,0])
end
%%
if ~isempty(subject)
    subtitle(['受试者: ',subject,' 频率-PSD谱']);
end
end
%print(gcf,'-r300','-dpng','C:\Users\潘林聪\Desktop\2-11');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-11.fig')

% 向图中添加文本
% annotation('textbox',[.2 .3 .4 .5],'String','my text','FitBoxToText','on','EdgeColor','none',...
% 'fontsize',15,'FontName','微软雅黑','HorizontalAlignment','center')