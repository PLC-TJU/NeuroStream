%% (TASK-3)根据ERSP画出脑地形图
% 来源: Pan LC. 2021.3.15
function allClim=ERSPtoTopoMap(ERSP_All,freqs,times,channel,timewindow,alpha_band,beta_band,type,subject,allClim)
% 输入
% ERSP: classnum*1 cell(freqs*times*channels);
% freqs,times:时频尺度信息,来自newtimef.m函数的输出
% channel:channels' labels*1 cell(channels*1)
% timewindow,alpha_band,beta_band,subject:Optional input parameters.
% The specific meaning is very simple, so I am too lazy to explain!

% type 1
% 'interplimits','electrodes'   部分脑区图
% 'hcolor','k'                  大脑轮廓:黑色
% 'numcontour',4                等高线数量:4

% type 2(other/defaults)
% 'interplimits','head'         全部脑区图
% 'hcolor','none'               大脑轮廓:无
% 'numcontour',6                等高线数量:6

if nargin< 10
    allClim=[];
end
if nargin< 9
    subject=[];
end
if nargin< 8
    type=2;
end
if nargin< 7
    beta_band=[14,26];
end
if nargin< 6
    alpha_band=[8,13];
end
if nargin< 5
    error('输入参数过少！')
end

if length(channel)>=64
    locsfile='Standard-10-10-for dataset PhysioNet.locs';
elseif length(channel)>=60
    locsfile='channel_location_60_neuroscan.locs';
elseif length(channel)>=28
    locsfile='channel_location_28_Panlincong.locs';
elseif length(channel)>=15
    locsfile='channel_location_15_neuroscan.locs';
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

if isempty(alpha_band)
    alpha_band=[8,13];
end
if isempty(beta_band)
    beta_band=[14,26];
end
if type==1
    interplimits='electrodes'; hcolor='k'; numcontour=4;%4
else
    interplimits='head'; hcolor='none'; numcontour=6;%6
end


labelNum=[];
for i=1:size(ERSP_All,1)
    if ~isempty(ERSP_All{i,1})
        labelNum=[labelNum,i];
    end
end
ClassNum=length(labelNum);
classType={'LH','RH','FT'};
colorSet={[0,0.447,0.741];[0.85,0.325,0.098];[0.929,0.694,0.125]};
Significance=0.05; %显著性 p值

ERSP=cell(size(ERSP_All));
pic_topo=figure('Position',[0,0,1,1]);
for num=1:2
    for class=1:ClassNum
        subplot(2,ClassNum+1,(num-1)*(ClassNum+1)+class);
        if num==1
            ERSP_All_temp{labelNum(class)}=ERSP_All{labelNum(class)}(freqs>alpha_band(1)&freqs<alpha_band(2),...
                times>1000*timewindow(1)&times<1000*timewindow(2),plotchan_ind,:);
            ERSP{class}=mean(ERSP_All_temp{labelNum(class)},4);
            temp=squeeze(mean(mean(ERSP{class},1),2));
            title_=['alpha ' num2str(alpha_band(1)) '~' num2str(alpha_band(2)) 'Hz'];
        else
            ERSP_All_temp{labelNum(class)}=ERSP_All{labelNum(class)}(freqs>beta_band(1)&freqs<beta_band(2),...
                times>1000*timewindow(1)&times<1000*timewindow(2),plotchan_ind,:);
            ERSP{class}=mean(ERSP_All_temp{labelNum(class)},4);
            temp=squeeze(mean(mean(ERSP{class},1),2));
            title_=['beta ' num2str(beta_band(1)) '~' num2str(beta_band(2)) 'Hz'];
        end

        % 删除离群值
        [~,Ind]=rmoutliers(temp,'mean');
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
                temp(ind(i))=mean(temp([ind(i)-1,ind(i)+1]));
%                 error('存在重要数据缺失');
            end
        end
        
        [ax(num,class),z]=P_topoplot(temp,locsfile,'maplimits','minmax','whitebk','on',...
            'electrodes','labels','colormap','jet','headrad',0.47,'plotrad',0.5,'shading','interp','emarker2',{key_chan0,'.','k',15,0}...
            ,'hcolor',hcolor,'numcontour',numcontour,'plotchans',chan); %,'interplimits','electrodes','maplimits','maxmin','colormap','jet'
        subplot_M_N_p(2,ClassNum+1,(num-1)*(ClassNum+1)+class);
        title(ax(num,class),[classType(class),title_],'fontsize',15,'color',colorSet{class},'FontName','微软雅黑','FontWeight','bold')
%         colormap winter
    end

    subplot(2,ClassNum+1,num*(ClassNum+1));
    if num==1
        temp1=squeeze(mean(mean(ERSP_All_temp{1},1),2));
        temp2=squeeze(mean(mean(ERSP_All_temp{2},1),2));
    else
        temp1=squeeze(mean(mean(ERSP_All_temp{1},1),2));
        temp2=squeeze(mean(mean(ERSP_All_temp{2},1),2));
    end
    [~,temp]=ttest2(temp1,temp2,'Dim',2,'Tail','both','Alpha',Significance);
    FDR=mafdr(temp);%FDR校正
    temp(FDR>0.5)=1;
    [ax(num,ClassNum+1),z]=P_topoplot(temp,locsfile,'maplimits','minmax','whitebk','on',...
            'electrodes','labels','colormap','jet','headrad',0.49,'shading','interp','emarker2',{key_chan,'.','k',15,0}...
            ,'interplimits',interplimits,'hcolor',hcolor,'numcontour',1); %,'interplimits','electrodes','maplimits','maxmin','colormap','jet'
    subplot_M_N_p(2,ClassNum+1,num*(ClassNum+1));
    title(ax(num,ClassNum+1),[classType{1},'-',classType{2}],'fontsize',15,'color','black','FontName','微软雅黑','FontWeight','bold')
%     set(handle(num,ClassNum+1),'colormap',winter)
end
% 调整每行子图的颜色图尺度一致
if isempty(allClim)
    for num=1:2
        for class=1:ClassNum
            allClim(num,2*class-1:2*class)=get(ax(num,class),'Clim');
        end
    end
end

for num=1:2
    Clim(num,:)=[min(allClim(num,:)),max(allClim(num,:))];
end

for num=1:2
    for class=1:ClassNum
%         set(ax(num,class),'Clim',[-max(abs(Clim),[],'all'),max(abs(Clim),[],'all')])
        set(ax(num,class),'Clim',[-0.5,2])
    end
    set(ax(num,ClassNum+1),'Clim',[0,0.1])
    colormap(ax(num,ClassNum+1),'autumn');
end
% cbar('vert',0,mean(Clim),5);
% title(['PSD(dB)'],'fontsize',12,'FontName','微软雅黑')
% set(gca,'fontsize',12,'position',get(handle(num,ClassNum),'position').*[1.68 3.02 0.10 0.75]);
% cb1=colorbar(handle(2,ClassNum),'Ticks',mean(Clim));
if ~isempty(subject)
    subtitle(['受试者: ',subject,' 脑地形图']);
end
cb1=colorbar(ax(2,ClassNum));
set(cb1,'fontsize',12,'position',get(cb1,'position').*[1.0671 2.2821 1.3708 0.9637]);
title(cb1,'PSD(dB)','fontsize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.05,0])
% title(handle(num,ClassNum+1),[classType{1},'-',classType{2}],'fontsize',15,'color','black','FontName','微软雅黑','FontWeight','bold')

cb2=colorbar(ax(2,ClassNum+1),'Ticks',0:0.05:0.1);
set(cb2,'fontsize',12,'position',get(cb2,'position').*[1.0671 2.2821 1.3708 0.9637]);
title(cb2,'p值','fontsize',12,'FontName','微软雅黑','Units','normalized','Position',[0.5,1.05,0])

title(ax(2,ClassNum+1),[classType{1},'-',classType{2}],'fontsize',15);
set(pic_topo,'color','w')

end
%print(gcf,'-r330','-dpng','C:\Users\潘林聪\Desktop\2-9x');
%saveas(gcf,'C:\Users\潘林聪\Desktop\2-9x.fig')