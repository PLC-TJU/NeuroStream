%% 画脑地形图
AAA=rand(100,1);
load('colormap_mne.mat','RdBu_r')
%画全脑区范围
figure(1);
topoplot(AAA,'channel_location_28_Panlincong.locs','maplimits','maxmin','electrodes','off','colormap',...
    'jet','hcolor','none','shading','interp');

%只画部分电极范围
figure(2);
topoplot(AAA,'channel_location_28_Panlincong.locs','maplimits','maxmin','electrodes','off','colormap',...
    'jet','shading','interp','interplimits','electrodes','headrad',0.5,'plotrad',0.54);
colormap(RdBu_r)

figure(3);
P_topoplot(AAA,'channel_location_28_Panlincong.locs','maplimits','maxmin','electrodes','off','colormap',...
    'jet','shading','interp','interplimits','electrodes');
colormap(RdBu_r)
