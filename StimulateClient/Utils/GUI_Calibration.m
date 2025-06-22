%% 界面校准程序
function Result=GUI_Calibration(~)
%flag=1,自动取样
%flag=2,手动取样
%flag=3,样本校准
fullpath = mfilename('fullpath');
[path,~]=fileparts(fullpath);

if nargin <1
    button=questdlg('请选择参考样本位置！','校准程序','自动选择','手动选择','自动选择'); %内容，标题，选项，默认选项
    switch button
        case '手动选择'
            flag=2;
        otherwise
            flag=1;
    end
else
    flag=3;
end

switch flag
    case 1
        Position=[-40,10,10,10];
    case 2
        Position(3:4)=10;
        button2=[];
        while ~strcmp(button2,'是')
            cprintf('*SystemCommands','请在5秒内移动鼠标至参考样本位置处！ \n');
            pause(5)
            [Position(1),Position(2)]=getmouse();
            button2=questdlg('是否选择完成？','参考样本选定','是','否','否');
        end
    case 3
        try
            load([path,'\CalibrationSample.mat'],'sample','Position');
        catch
            msgbox('请先完成【参考样本选定】操作！','错误','error')
            error('请先完成【参考样本选定】操作！')
        end
        Sample=ImageCapture(Position);
        if isequal(Sample,sample)
            Result=1;
        else
            Result=0;
        end
end
if flag==1 || flag==2
    sample=ImageCapture(Position);
    save([path,'\CalibrationSample.mat'],'sample','Position');
    cprintf('*Keywords','【参考样本选定】程序已完成！ \n');
    Result=[];
end
end