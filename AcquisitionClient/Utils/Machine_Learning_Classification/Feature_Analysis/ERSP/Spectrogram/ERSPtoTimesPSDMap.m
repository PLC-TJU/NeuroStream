%% Times-PSD频谱图(正式版)  Type1
% 来源: Pan LC. 2021.11.3
function ERSPtoTimesPSDMap(ERSP_All,freqs,times,channel,freqsband,subject)
% 输入
% ERSP: classnum*1 cell(freqs*times*channels);
% freqs,times:来自newtimef.m函数的输出
% freqwindow,subject:Too lazy to write!

if nargin< 6
    subject=[];
end
if nargin< 5
    freqsband=[];
end
if strcmp(freqsband,'alpha')||strcmp(freqsband,'a')||strcmp(freqsband,'A')||isequal(freqsband,[8,13])||isempty(freqsband)
    freqsband=[8,13];
    TitleSuffix='alpha 8-13Hz';
elseif strcmp(freqsband,'beta')||strcmp(freqsband,'b')||strcmp(freqsband,'B')||isequal(freqsband,[14,30])
    freqsband=[14,30];
    TitleSuffix='beta 14-30Hz';
else
    TitleSuffix=['',num2str(freqsband(1)),'-',num2str(freqsband(2)),'Hz'];
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
MItimes=times(times>0);
Significance=0.05; %显著性 p值
ChanColor=[0,0.45,0.74;0.85,0.33,0.10;0.93,0.69,0.13];

AllPow=zeros(size(ERSP_All{labelInd(1)},2),ChanNum,size(ERSP_All{labelInd(1)},4),ClassNum);
Pow=zeros(size(ERSP_All{labelInd(1)},2),ChanNum,ClassNum);
Pow_Std=zeros(size(Pow));
for class=1:ClassNum
    AllPow(:,:,:,class)=squeeze(mean(ERSP_All{labelInd(class)}(freqs>freqsband(1)&freqs<freqsband(2),:,chan,:),1)); 
    Pow(:,:,class)=squeeze(mean(AllPow(:,:,:,class),3));
    %计算标准差
    Pow_Std(:,:,class)=squeeze(std(AllPow(:,:,:,class),0,3))*0.1;
    %减小离群值
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
    allMIPow=AllPow(times>0,:,:,class);
    %寻找ERD对侧占优显著区间
    switch class
        case 1
            XRange=MItimes(ttest2(allMIPow(:,1,:),allMIPow(:,2,:),'Dim',3,'Tail','right','Alpha',Significance)==1)./1000;
        case 2
            XRange=MItimes(ttest2(allMIPow(:,2,:),allMIPow(:,1,:),'Dim',3,'Tail','right','Alpha',Significance)==1)./1000;
        case 3
            XRange=MItimes(ttest2(allMIPow(:,2,:),allMIPow(:,3,:),'Dim',3,'Tail','right','Alpha',Significance)==1)./1000;
    end
    if ~isempty(XRange)
        %分割区间
        SplitPoint=XRange(1);
        for n=1:length(XRange)-1
            if roundn(XRange(n+1)-XRange(n),-4)>roundn(max(times(2)-times(1),times(3)-times(2))/1000,-4)
                %                     SplitPoint=[SplitPoint,XRange(n)-(times(end)-times(1))/(length(times)-1),XRange(n+1)];
                SplitPoint=[SplitPoint,XRange(n),XRange(n+1)];
            end
        end
        SplitPoint(end+1)=XRange(end);
        SplitPoint=sort(SplitPoint);
        for num=1:length(SplitPoint)/2
            B=BackgroundColor([SplitPoint(2*num-1),SplitPoint(2*num),Ylim(1),Ylim(2)]);
        end
    end
    hold on        
    p{class}=plot(times./1000,Pow(:,:,class),'linewidth',3);
    %画标准差范围
    for ch=1:ChanNum
        y_up=Pow(:,ch,class)+Pow_Std(:,ch,class);
        y_low=Pow(:,ch,class)-Pow_Std(:,ch,class);
        fill([times./1000,fliplr(times./1000)],[y_up',fliplr(y_low')],'c','FaceAlpha',0.2,'EdgeAlpha',0,'FaceColor',ChanColor(ch,:));
    end
    hold off
    ax{class}=gca;
%     set(gca,'XLim',[floor(times(1)/100)/10,ceil(times(end)/100)/10],'xtick',floor(times(1)/1000):1:ceil(times(end)/1000));
    subplot_M_N_p(1,ClassNum,class);
%     title([classType(class),TitleSuffix]); 
    set(gca,'FontSize',12,'FontName','微软雅黑');
    title(classType(class),'FontSize',15,'FontName','微软雅黑','FontWeight','bold');
    xlabel('时间(s)','FontSize',15,'FontName','微软雅黑');
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
    set(ax{class},'ylim',Ylim,'xlim',[floor(times(1)./100)/10,ceil(times(end)./100)/10])% 调整每个子图的横纵轴刻度一致
    %添加0时刻分割线
    hold(ax{class},'on')
    plot(ax{class},[0,0],Ylim,'--k','linewidth',2);
    hold(ax{class},'off')
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
    subtitle(['受试者: ',subject,' 时间-PSD谱']);
end
% set(gcf,'position',[1365,69,2322,896]);
end

%print(gcf,'-r330','-dpng','C:\Users\潘林聪\Desktop\2-7x');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-7x.fig')