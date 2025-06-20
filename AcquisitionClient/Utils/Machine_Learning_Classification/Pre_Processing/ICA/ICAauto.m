%% 自动进行ICA剔除噪声成分
% Author: LC Pan
% Date: March. 17, 2023

% 需要eeglab安装adjust拓展工具(具体步骤：eeglab->File->Manage EEGLAB extensions->Search "adjust"->install)
% 输入
% filepath:保存cnt文件的文件夹地址；
% 输出
% 保存ICA处理后的EEG信号到源数据文件夹中的*ica.mat文件中
function ICAauto(filepath)
files = dir([filepath,'\*.cnt']);
for i = 1:length(files)
    EEG = pop_loadcnt([files(i).folder,'\',files(i).name] , 'dataformat', 'auto', 'memmapfile', '');
    EEG = eeg_checkset(EEG);
    EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');
    EEG = eeg_checkset(EEG);
    if EEG.nbchan == 68
        EEG = pop_select(EEG, 'nochannel', {'M1','M2','HEO','VEO','EKG','EMG'});
        EEG = eeg_checkset(EEG);
    end

    EEG = pop_resample(EEG, 250);
    EEG = eeg_checkset(EEG);
    EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 40);%1~40Hz带通滤波，根据需要修改
    EEG = eeg_checkset(EEG);
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt','on');
    EEG = eeg_checkset(EEG);

    report = fullfile(pwd, 'report.txt');%当前保存report文件的地址
    pop_ADJUST_interface(EEG, report);
    RejctIC_adjust = find(EEG.reject.gcompreject == 1);
    
    stamp1 = 'Artifacted ICs (total):';%数据查找标志
    a1 = F0_acquire(report,stamp1);
    RejctIC = [];
    if a1 ~= '/'
        b1 = str2num(a1);
        if ~isempty(b1 <= 68)
            RejctIC = union(RejctIC_adjust, b1(b1 <= 68));
        end
    end
    EEG = eeg_checkset(EEG);
%     pop_selectcomps(EEG, 1:EEG.nbchan );
%     EEG = eeg_checkset(EEG);
    EEG = pop_subcomp(EEG, RejctIC, 0);
    EEG = eeg_checkset(EEG);

    % 绘制ICA处理后的EEG
    % pop_eegplot(EEG, 1, 1, 1);

    % 保存ICA处理后的EEG文件
    save([files(i).folder,'\',files(i).name(1:end-4),'ica'],'EEG');

    %关闭所有图窗口
    close all;
end
end

%% 读取txt文件
function file = F0_acquire(phns, stamp1)
fpn = fopen(phns,'rt');      %打开文档
while feof(fpn) ~= 1        %用于判断文件指针p在其所指的文件中的位置，如果到文件末，函数返回1，否则返回0
    file = fgetl(fpn);      %获取文档第一行
    if contains(file, stamp1)
        file = fgetl(fpn);      %获取文档第一行
    end
end
fclose(fpn);
end

%% 生成report.txt文件，保存待剔除成分信息
function pop_ADJUST_interface (EEG,report)
if nargin < 2
    report = 'report.txt';
end

disp(' ')
disp (['Running ADJUST on dataset ' strrep(EEG.filename, '.set', '') '.set'])

interface_ADJ (EEG, report);

end
