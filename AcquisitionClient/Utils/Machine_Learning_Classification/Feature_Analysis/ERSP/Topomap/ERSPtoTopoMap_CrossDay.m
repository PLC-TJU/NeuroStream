%% 根据ERSP绘制脑地形图
% 来源: Pan LC. 2021.3.15
function [pic_topo,plotdata]=ERSPtoTopoMap_CrossDay(ERSP_All,freqs,times,channel,timewindow,freqsband,type,subject)
% 必须输入
% ERSP_All: classnum*daynum cell(freqs*times*channels*samples);
% freqs: ERSP的频率点数，点数越多频率分辨率越高（单位为Hz）
% times: ERSP的时间点数，点数越多时间分辨率越高（单位为ms）
% channel: ERSP的通道信息(长度应与ERSP值中第3维度相同)，应该为包含导联标签的元胞数组，例如{'C1','C3',...}

% 可选输入
% timewindow: 绘制地形图的ERSP时间窗范围，单位为s，例如[0,4]。默认为ERSP包含的全部时间。
% freqsband: 绘制地形图的ERSP频率范围，单位为Hz，例如[8,30]。默认为alpha频带[8,13]。
% type: 绘制的地形图的类型。type=1(默认值)：仅绘制所包含电极范围的地形图；type=2：仅绘制全脑区的地形图。
% subject: 受试者名称（字符串），默认为空。

% 输出
% 地形图: 行数为ClassNum+1（最后一行是前两行地形图差异的显著性P值图），列数为DayNum。

% type 1
% 'interplimits','electrodes'   部分脑区图
% 'hcolor','k'                  大脑轮廓:黑色
% 'numcontour',4                等高线数量:4

% type 2(other/defaults)
% 'interplimits','head'         全部脑区图
% 'hcolor','none'               大脑轮廓:无
% 'numcontour',6                等高线数量:6

if nargin< 8
    subject=[];
end
if nargin< 7
    type=1;
end
if nargin< 6 
    freqsband=[];
end
if nargin< 5 || isempty(timewindow)
    timewindow=[ceil(times(1)),floor(times(end))]./1000;
end
if nargin< 4
    error('输入参数过少！')
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

if length(channel)>=60
    locsfile='channel_location_60_neuroscan.locs';
elseif length(channel)>=28
    locsfile='channel_location_28_Panlincong.locs';
    type=1;
elseif length(channel)>=15
    locsfile='channel_location_15_neuroscan.locs';
    type=1;
else
    error('请重新设置导联信息！');
end
temlocs = readlocs(locsfile);
locs_chan=cell(length(temlocs),1);
for c=1:length(temlocs)
locs_chan{c} = temlocs(c).labels;
end
[checkflag,plotchan_ind]=ismember(locs_chan,channel);
if ismember(0,checkflag)
    warning(['缺少',locs_chan{checkflag==0},'导联信息']);
    error('channel参数中缺少所必须导联，请更正或重设.locs文件！');
end
[~,C3]=ismember('C3',locs_chan);
[~,C4]=ismember('C4',locs_chan);
[~,CZ]=ismember('CZ',locs_chan);
key_chan =[C3,C4,CZ]; %C3、C4、CZ导联索引

if type==1
    interplimits='electrodes'; hcolor='k'; numcontour=4; %画局部图
else
    interplimits='head'; hcolor='none'; numcontour=6;    %画全图
end

DayNum=size(ERSP_All,2);
labelNum=[];
for i=1:size(ERSP_All,1)
    if ~isempty(ERSP_All{i,1})
        labelNum=cat(2,labelNum,i);
    end
end
ClassNum=length(labelNum);
classType={'LH','RH','FT'};
colorSet={[0,0.447,0.741];[0.85,0.325,0.098];[0.929,0.694,0.125]};
Significance=0.05; %显著性 p值

ERSP=cell(size(ERSP_All));
pic_topo=figure('color','w');
for class=1:ClassNum
    for day=1:DayNum
        ERSP_All{labelNum(class),day}=ERSP_All{labelNum(class),day}(freqs>=freqsband(1)&freqs<=freqsband(2),...
                times>=1000*timewindow(1)&times<=1000*timewindow(2),plotchan_ind,:);
        ERSP{class,day}=mean(ERSP_All{labelNum(class),day},4);
        subplot(ClassNum+1,DayNum,(class-1)*DayNum+day);
        temp(:,day,class)=squeeze(mean(mean(ERSP{class,day},1),2));%#ok

        % 删除离群值
        [~,Ind]=rmoutliers(temp(:,day,class),'mean');
        allchan=1:size(temp,1);
        chan=allchan(~Ind);
        ind=find(Ind==1);
        key_chan0=key_chan;
        for i=1:length(ind)
            if ind(i)<key_chan(1)
                key_chan0=key_chan0-1;
            elseif ind(i)>key_chan(1) && ind(i)<key_chan(2)
                key_chan0(2:3)=key_chan0(2:3)-1;
            elseif ind(i)>key_chan(2) && ind(i)<key_chan(3)
                key_chan0(3)=key_chan0(3)-1;
            elseif ismember(ind(i),key_chan)
                chan=sort([chan,ind(i)]);
                temp(ind(i),day,class)=mean(temp(([ind(i)-1,ind(i)+1]),day,class));
                warning('存在重要数据缺失');
            end
        end
        %'interplimits','electrodes','maplimits','maxmin','plotchans',chan
        [ax(class,day),~]=P_topoplot(temp(:,day,class),locsfile,'maplimits','maxmin','whitebk','on',...
            'electrodes','labels','colormap','jet','headrad',0.49,'shading','interp','emarker2',{key_chan0,'.','k',15,0}...
            ,'interplimits',interplimits,'hcolor',hcolor,'numcontour',numcontour,'plotchans',chan); %#ok
        subplot_M_N_p(ClassNum+1,DayNum,(class-1)*DayNum+day);
        title([classType{class},'-Day',num2str(day)],'fontsize',15,'color',colorSet{class},'FontName','微软雅黑','FontWeight','bold');%colorSet{class|day} 不同类或天不同颜色
    end
end
%画显著性图谱
for day=1:DayNum
    subplot(ClassNum+1,DayNum,ClassNum*DayNum+day);
    temp1=squeeze(mean(mean(ERSP_All{1,day},1),2));
    temp2=squeeze(mean(mean(ERSP_All{2,day},1),2));
    [~,temp(:,day,ClassNum+1)]=ttest2(temp1,temp2,'Dim',2,'Tail','both','Alpha',Significance);

    FDR=mafdr(temp(:,day,ClassNum+1));%FDR校正
%     FDR=temp(:,day,ClassNum+1);
    temp(FDR>0.05,day,ClassNum+1)=1;

    [ax(ClassNum+1,day),~]=P_topoplot(temp(:,day,ClassNum+1),locsfile,'maplimits','minmax','whitebk','on',...
            'electrodes','labels','colormap','jet','headrad',0.49,'shading','interp','emarker2',{key_chan,'.','k',15,0}...
            ,'interplimits',interplimits,'hcolor',hcolor,'numcontour',1); %,'interplimits','electrodes','maplimits','maxmin','colormap','jet'
    subplot_M_N_p(ClassNum+1,DayNum,ClassNum*DayNum+day);
    title(ax(ClassNum+1,day),[classType{1},'-',classType{2}],'fontsize',15,'color','black','FontName','微软雅黑','FontWeight','bold')
end

% 调整子图的颜色图尺度一致

Temp=rmoutliers(reshape(temp(:,:,1:ClassNum),[],1),'mean');% 删除离群值
% Clim=[min(Temp,[],"all"),max(Temp,[],"all")];
Clim=[-max(abs(Temp),[],"all"),max(abs(Temp),[],"all")];
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
title(cb1,'PSD(dB)','FontSize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.05,0])

% for class=1:ClassNum
%     Temp=rmoutliers(reshape(temp(:,:,class),[],1),'mean');% 删除离群值
%     Clim(class,:)=[min(Temp,[],"all"),max(Temp,[],"all")];
%     for day=1:DayNum
%         set(handle(class,day),'Clim',Clim(class,:))
%     end
%     cbar('vert',0,Clim(class,:),5);
%     title(['PSD(dB)'],'fontsize',14)
%     set(gca,'FontSize',14,'position',get(handle(class,DayNum),'position').*[0,1,0,0.75]+[0.93,0.025,0.025,0]);
% end

% for day=1:DayNum
%     colormap(handle(ClassNum+1,day),'autumn');
% end

for day=1:DayNum
    set(ax(ClassNum+1,day),'Clim',[0,0.1])
    colormap(ax(ClassNum+1,day),'autumn');
end
cb2=colorbar(ax(ClassNum+1,day),'Ticks',0:0.05:0.1);

pos3=get(ax(ClassNum+1,DayNum),'position');
set(cb2,'FontSize',12,'position',[0.5*(pos1(1)+pos1(3)+1)-width,pos3(2),width,pos3(4)]);
title(cb2,'p值','fontsize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.05,0]);

%设置背景为白色
set(pic_topo,'color','w')
if ~isempty(subject)
    subtitle(['受试者: ',subject,' 脑地形图',TitleSuffix]);
end

plotdata=temp;
end
%print(gcf,'-r330','-dpng','C:\Users\潘林聪\Desktop\2-12x');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-12x.fig')