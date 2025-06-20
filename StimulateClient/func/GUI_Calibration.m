%% ����У׼����
function Result=GUI_Calibration(~)
%flag=1,�Զ�ȡ��
%flag=2,�ֶ�ȡ��
%flag=3,����У׼
fullpath = mfilename('fullpath');
[path,~]=fileparts(fullpath);

if nargin <1
    button=questdlg('��ѡ��ο�����λ�ã�','У׼����','�Զ�ѡ��','�ֶ�ѡ��','�Զ�ѡ��'); %���ݣ����⣬ѡ�Ĭ��ѡ��
    switch button
        case '�ֶ�ѡ��'
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
        while ~strcmp(button2,'��')
            cprintf('*SystemCommands','����5�����ƶ�������ο�����λ�ô��� \n');
            pause(5)
            [Position(1),Position(2)]=getmouse();
            button2=questdlg('�Ƿ�ѡ����ɣ�','�ο�����ѡ��','��','��','��');
        end
    case 3
        try
            load([path,'\CalibrationSample.mat'],'sample','Position');
        catch
            msgbox('������ɡ��ο�����ѡ����������','����','error')
            error('������ɡ��ο�����ѡ����������')
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
    cprintf('*Keywords','���ο�����ѡ������������ɣ� \n');
    Result=[];
end
end