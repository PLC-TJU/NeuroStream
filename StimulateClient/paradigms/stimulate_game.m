function stimulate_game(Block,CueTime,RestTime,TrialNum,Adress)

import java.awt.Robot;
import java.awt.event.*;
robot = java.awt.Robot;

%% ��֤ͨ�ŷ�ʽ
[flag, out] = configureCommunication(Adress);

%% ȷ��NeuRow������ȷ����
Result=GUI_Calibration(1);
position1=[-5,1075];%1919,30
position2=[-437,300];%1483,300 %��ͣ����λ������
% position1=[6120,-20];
% position2=[5274,-1558];
if ~Result
    pauseFlag(false,position1,position2);% ȡ���ݶ�
    Result=GUI_Calibration(1);
    pause(0.1);
    pauseFlag(true,position1,position2);% ִ���ݶ�
    if ~Result
        errordlg('��Ԥ�Ȱ�Ҫ������NeuRow�����');
        return
    end
end
h=msgbox('�̼������ɳ���ӹܣ�����ʵ�����ǰ��ֹ�ƶ�����ʹ�ü��̣�','��Ҫ��ʾ','warn');
cprintf('*Keywords','�̼���ʽ�ɳ���ӹܣ�����ʵ�����ǰ��ֹ�ƶ�����ʹ�ü��̣�\n');

pause(1)
mousemove(position2(1),position2(2));
pause(0.1)
mouseclick(1,1);
pause(1)
mousemove(position1(1),position1(2));
pause(0.1)
mouseclick(1,1);
pause(1)

delete(h);

%% ѡ��ģʽ
% Block=1(Left) / 2(Right) / 3(Left & Right) / 4(Mix)
classType={'����','����','˫��'};
switch Block
    case 1
        allmode(1:TrialNum)=1;%Left
    case 2
        allmode(1:TrialNum)=2;%Right
    case 3
        allmode(1:TrialNum/2)=1;%Left
        allmode(TrialNum/2+1:TrialNum)=2;%Right
    case 4
        N=TrialNum/3;
        allmode=[ones(1,N),2*ones(1,N),3*ones(1,N)];
end
allmode= allmode(randperm(length(allmode)));

time.modeS=0;time.modeL=0;time.modeR=0;

%% ��ʼ�̼�����
try    
    time.start=fix(clock);    
    time.modeL=0;time.modeS=0;time.modeR=0;time.rest=0;
    for i=1:length(allmode)
        [p(1),p(2)]=getmouse;
        if norm(p-[0,0],'fro')<=60%����Ļ���Ͻ�
            %��ͣ�̼�
            mousemove(position1(1),position1(2));
            mouseclick(1,1);
            pause(0.1);
            robot.keyPress    (java.awt.event.KeyEvent.VK_P);
            robot.keyRelease  (java.awt.event.KeyEvent.VK_P);
            %
            button=questdlg('�Ƿ�������˳��̼�����','������ͣ','����','�˳�','�˳�'); 
            switch button
                case '����'
                    pause(1)
                    mousemove(position2(1),position2(2));
                    pause(0.01)
                    mouseclick(1,1);
                    pause(0.01);
                    mousemove(position1(1),position1(2));
                    pause(0.01);
                    for ii=1:6
                        Result=GUI_Calibration(1);
                        if ~Result
                            cprintf('*Keywords','��%d�γ�������ʧ�ܣ�\n',ii);
                            mousemove(position2(1),position2(2));
                            pause(0.01)
                            mouseclick(1,1);
                            pause(0.01);
                            mousemove(position1(1),position1(2));
                            pause(1);
                            if ii==6
                                cprintf('*Keywords','��������ʧ�ܣ���ǿ����ֹ�̼�������̣�\n');
                                return;
                            end
                        else
                            h=msgbox('�����Ѽ���������ʵ�����ǰ��ֹ�ƶ�����ʹ�ü��̣�','��Ҫ��ʾ','warn');
                            cprintf('*Keywords','�����Ѽ���������ʵ�����ǰ��ֹ�ƶ�����ʹ�ü��̣�\n');
                            mousemove(position1(1),position1(2));
                            pause(0.01)
                            mouseclick(1,1);
                            pause(1)
                            delete(h);
                            break;
                        end
                    end
                otherwise
                    break;
            end
        elseif ~isequal(p,position1) 
            mousemove(position1(1),position1(2));
            pause(0.01)
            mouseclick(1,1);
            pause(0.01)
        end
             
        mode=allmode(i);
        disp(['��',num2str(i),'���Դε�MIģʽ�ǣ�',classType{mode},'����,��ʾʱ��Ϊ��',num2str(CueTime),'�롣']);

        %% ��Ϣ
        tic
        pause(RestTime-0.25);
                
        %% 0.3��׼��Beep
        sound(sin(2*pi*5*(1:4000)/100));
        if flag==1
            lptwrite(out,0);
        elseif flag==2
            write(out,0,'single')
        end
        pause(0.25)
        time.rest(i)=toc;
        
        %% ��һMI����̼�
        tic
        if flag==1
            lptwrite(out,mode);
        elseif flag==2
            write(out,mode,'single')
        end
        switch mode
            case 1                
                robot.keyPress    (java.awt.event.KeyEvent.VK_LEFT);               
                pause(CueTime);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_LEFT);
                time.modeL(i)=toc;
            case 2               
                robot.keyPress    (java.awt.event.KeyEvent.VK_RIGHT);               
                pause(CueTime);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_RIGHT);
                time.modeR(i)=toc;
            case 3                
                robot.keyPress    (java.awt.event.KeyEvent.VK_LEFT);
                robot.keyPress    (java.awt.event.KeyEvent.VK_RIGHT);     
                pause(CueTime);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_LEFT);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_RIGHT);
                time.modeS(i)=toc;
        end
        pause(0.1);
    end
    time.end=fix(clock);
    if i==length(allmode)
        %�����̼�
        robot.keyPress    (java.awt.event.KeyEvent.VK_P);
        robot.keyRelease    (java.awt.event.KeyEvent.VK_P);
        cprintf('*Comments','ʵ��������ɣ�\n');
    else
        cprintf('*Errors','ʵ��δ��ɣ�������ֹ��\n');
    end
    
catch error
    if flag==2
        write(out,0,'uint8');
        clear out;% �رմ���
    end
    rethrow(error);
end

if flag==1
    lptwrite(out,0);
elseif flag==2
    write(out,0,'uint8');
    clear out;% �رմ���
end


time.cost=time.end-time.start;
time.min=fix((3600*time.cost(4)+60*time.cost(5)+time.cost(6))/60);
time.sec=rem(3600*time. cost(4)+60*time.cost(5)+time.cost(6),60);

% cprintf('*Keywords','����ʵ���ʱΪ:%d��%d�룬������%d Trials�� \n',time.min,time.sec,i);
cprintf('Keywords','����ʵ���ʱΪ:');
cprintf('Errors','%d��%d��',time.min,time.sec);
cprintf('Keywords','����������');
cprintf('Errors',' %d ',i);
cprintf('Keywords','���Դ� \n');
%% ͳ�Ƹ���̼�ʱ�����
% cprintf('Keywords','ƽ����Ϣ���ʱ��Ϊ %d�� \n',roundn(mean(time.rest(1:i-1)),-3));
cprintf('Keywords','ƽ����Ϣ���ʱ��Ϊ');
cprintf('Errors','%d�� \n',roundn(mean(time.rest(1:i-1)),-3));
if ismember(1,allmode(1:i))
% cprintf('Keywords','ƽ�����󻮴�ʱ��Ϊ %d�� \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
cprintf('Keywords','ƽ�����󻮴�ʱ��Ϊ');
cprintf('Errors','%d�� \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
end
if ismember(2,allmode(1:i))
% cprintf('Keywords','ƽ�����һ���ʱ��Ϊ %d�� \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
cprintf('Keywords','ƽ�����һ���ʱ��Ϊ');
cprintf('Errors','%d�� \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
end
if ismember(3,allmode(1:i))
% cprintf('Keywords','ƽ�����һ���ʱ��Ϊ %d�� \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
cprintf('Keywords','ƽ�����һ���ʱ��Ϊ');
cprintf('Errors','%d�� \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
end
end

function pauseFlag(flag,position1,position2)
if nargin<3 || isempty(position2)
    position2=[-437,300];
end
if nargin<2 || isempty(position1)
    position1=[-5,1080];
end

[p(1),p(2)]=getmouse;

if flag
    %��ͣ
    for j=1:5
        mousemove(position1(1),position1(2));
        pause(0.05);
        robot.keyPress    (java.awt.event.KeyEvent.VK_P);
        robot.keyRelease    (java.awt.event.KeyEvent.VK_P);
        pause(0.05);
    end
else
    %ȡ����ͣ
    for j=1:5
        mousemove(position2(1),position2(2));
        pause(0.05);
        mouseclick(1,1);
        pause(0.05);
    end
end

mousemove(p(1),p(2));

end
