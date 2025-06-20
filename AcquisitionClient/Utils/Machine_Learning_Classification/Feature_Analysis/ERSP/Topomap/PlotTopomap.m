%% 画脑地形图
% 来源: Pan LC. 2021.11.12
function ax = PlotTopomap(val, cmap, type)
if nargin < 3 || isempty(type)
    type = 1;
end
if nargin < 2 || isempty(cmap)
    load('colormap_mne.mat','RdBu_r')
    cmap = RdBu_r;
end

if length(val)>=64
    locsfile='Standard-10-10-for dataset PhysioNet.locs';
elseif length(val)>=60
    locsfile='channel_location_60_neuroscan.locs';
elseif length(val)>=28
    locsfile='channel_location_28_Panlincong.locs';
elseif length(val)>=15
    locsfile='channel_location_15_neuroscan.locs';
else
    error('请重新设置导联信息！');
end

if type==1
    interplimits='electrodes'; hcolor='k'; numcontour=3; %画局部图
else
    interplimits='head'; hcolor='none'; numcontour=6;    %画全图
end

%figure;
ax = topoplot(val, locsfile, ...
    'maplimits','maxmin','electrodes','off','colormap',...
     cmap,'shading','interp','interplimits',interplimits, ...
     'hcolor',hcolor,'numcontour',numcontour,...
    'headrad',0.49,'plotrad',0.54);
% set(ax, 'Clim', [-2, 2]);

end