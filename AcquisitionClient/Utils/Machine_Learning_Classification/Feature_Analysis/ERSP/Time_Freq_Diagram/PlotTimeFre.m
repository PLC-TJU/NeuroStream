%% 画时频图
% 来源: Pan LC. 2021.11.12
function PlotTimeFre(ERSP,freqs,times)
load('colormap_mne.mat','RdBu_r')

ERSP=mean(ERSP,3);
figure;
imagesc(times/1000,freqs,ERSP,[-5,5]);

% colormap(jet);
colormap(RdBu_r);

% set(gca,'ydir','normal');  % make frequency ascend or descend
xlabel('Time(s)');
ylabel('Frequency(Hz)');
set(gca,'FontSize',15);
end