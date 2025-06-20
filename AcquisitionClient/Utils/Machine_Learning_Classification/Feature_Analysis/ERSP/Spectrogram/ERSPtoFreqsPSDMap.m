%% Freqs-PSD频谱图(正式版) Type1
%v2.0a 来源: Pan LC. 2021.11.3
function ERSPtoFreqsPSDMap(ERSP_All,freqs,times,channel,timewindow,subject)
% 输入
% ERSP: classnum*1 cell(freqs*times*channels);
% freqs,times:来自newtimef.m函数的输出
% timewindow,subject:Too lazy to write!

if nargin< 6
    subject=[];
end
if nargin< 5 || isempty(timewindow)
    timewindow=[0,ceil(times(end)/100)/10];
end

labelInd=[];
for i=1:length(ERSP_All)
    if ~isempty(ERSP_All{i})
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

AllPow=zeros(size(ERSP_All{labelInd(1)},1),ChanNum,size(ERSP_All{labelInd(1)},4),ClassNum);
Pow=zeros(size(ERSP_All{labelInd(1)},1),ChanNum,ClassNum);
Pow_Std=zeros(size(Pow));
for class=1:ClassNum
    AllPow(:,:,:,class)=squeeze(mean(ERSP_All{labelInd(class)}(:,times>1000*timewindow(1)&times<1000*timewindow(2),chan,:),2));
    Pow(:,:,class)=squeeze(mean(AllPow(:,:,:,class),3));
    %计算标准差
    Pow_Std(:,:,class)=squeeze(std(AllPow(:,:,:,class),0,3))*0.1;
%     %减小离群值
%     for ch=1:size(Pow_Std,2)
%         [~,Ind]=rmoutliers(Pow_Std(:,ch,class),'mean');
%         Pow_Std(Ind,ch,class)=mean(Pow_Std(~Ind,ch,class));
%     end
end
Ylim=[min(Pow-Pow_Std,[],'all'),max(Pow+Pow_Std,[],'all')];
% Ylim=[min(1.25*Pow,[],'all'),max(1.25*Pow,[],'all')];
figure;
for class=1:ClassNum
    subplot(1,ClassNum,class);
    allPow=AllPow(:,:,:,class);    
    hold on
%     % alpha/beta频段 添加背景色
%     BackgroundColor([8,13,Ylim(1),Ylim(2)],[240 255 240]);
%     BackgroundColor([14,30,Ylim(1),Ylim(2)],[255 250 240]);
    
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
             B=BackgroundColor([SplitPoint(2*num-1),SplitPoint(2*num),Ylim(1),Ylim(2)]);
         end
     end
    
    p{class}=plot(freqs,Pow(:,:,class),'linewidth',3);
    %画标准差范围
    for ch=1:ChanNum
        y_up=Pow(:,ch,class)+Pow_Std(:,ch,class);
        y_low=Pow(:,ch,class)-Pow_Std(:,ch,class);
        fill([freqs,fliplr(freqs)],[y_up',fliplr(y_low')],'c','FaceAlpha',0.2,'EdgeAlpha',0,'FaceColor',ChanColor(ch,:));
    end
    
    hold off
    ax{class}=gca;
    subplot_M_N_p(1,ClassNum,class);
    set(gca,'FontSize',12,'FontName','微软雅黑');
    title(classType(class),'FontSize',15,'FontName','微软雅黑','FontWeight','bold');
    xlabel('频率(Hz)','FontSize',15,'FontName','微软雅黑');
    if class==labelInd(1)
        ylabel('功率谱(dB)','FontSize',15,'FontName','微软雅黑') %Log Power Spectral Density 10*log_{10} (uV^2/Hz)
        %去除上、右刻度
        box off
        ax2 = axes('Position',get(gca,'Position'),...
            'XAxisLocation','top',...
            'YAxisLocation','right',...
            'Color','none',...
            'XColor','k','YColor','k','linewidth',1.5);
        set(ax2,'YTick', []);
        set(ax2,'XTick', []);
        box on
    else
        set(gca,'ytick',[])
        %去除上刻度
        box off
        ax2 = axes('Position',get(gca,'Position'),...
            'XAxisLocation','top',...
            'Color','none',...
            'XColor','k','YColor','k','linewidth',1.5);
        set(ax2,'YTick', []);
        set(ax2,'XTick', []);
        box on
    end
end
% 调整每个子图的纵轴刻度一致
% for class=1:ClassNum
%     allYlim(1,2*class-1:2*class)=get(ax{class},'ylim');
% end
% Ylim=[min(allYlim),max(allYlim)];
for class=1:ClassNum
    set(ax{class},'ylim',Ylim)
end

% 添加图例
P=[];
for ch=1:ChanNum
    P=[P,p{ClassNum}(ch)];
end
if exist("B","var")
    legend([P,B],[chanType(1:ChanNum),{'p<0.05'}],'FontSize',12,'FontName','微软雅黑','Location','northeast')%'southeast' 'best'
else
    legend(P,chanType(1:ChanNum),'FontSize',12,'FontName','微软雅黑','Location','northeast')
end
if ~isempty(subject)
    subtitle(['受试者: ',subject,' 频率-PSD谱']);
end
end
%print(gcf,'-r330','-dpng','C:\Users\潘林聪\Desktop\2-8x');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-8x.fig')