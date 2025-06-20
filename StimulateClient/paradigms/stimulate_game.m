function stimulate_game(Block,CueTime,RestTime,TrialNum,Adress)

import java.awt.Robot;
import java.awt.event.*;
robot = java.awt.Robot;

%% 验证通信方式
[flag, out] = configureCommunication(Adress);

%% 确认NeuRow程序正确运行
Result=GUI_Calibration(1);
position1=[-5,1075];%1919,30
position2=[-437,300];%1483,300 %暂停按键位置坐标
% position1=[6120,-20];
% position2=[5274,-1558];
if ~Result
    pauseFlag(false,position1,position2);% 取消暂定
    Result=GUI_Calibration(1);
    pause(0.1);
    pauseFlag(true,position1,position2);% 执行暂定
    if ~Result
        errordlg('请预先按要求启动NeuRow软件！');
        return
    end
end
h=msgbox('刺激操作由程序接管，本轮实验结束前禁止移动鼠标和使用键盘！','重要提示','warn');
cprintf('*Keywords','刺激范式由程序接管，本轮实验结束前禁止移动鼠标和使用键盘！\n');

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

%% 选择模式
% Block=1(Left) / 2(Right) / 3(Left & Right) / 4(Mix)
classType={'左手','右手','双手'};
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

%% 开始刺激界面
try    
    time.start=fix(clock);    
    time.modeL=0;time.modeS=0;time.modeR=0;time.rest=0;
    for i=1:length(allmode)
        [p(1),p(2)]=getmouse;
        if norm(p-[0,0],'fro')<=60%主屏幕左上角
            %暂停刺激
            mousemove(position1(1),position1(2));
            mouseclick(1,1);
            pause(0.1);
            robot.keyPress    (java.awt.event.KeyEvent.VK_P);
            robot.keyRelease  (java.awt.event.KeyEvent.VK_P);
            %
            button=questdlg('是否继续或退出刺激程序？','程序暂停','继续','退出','退出'); 
            switch button
                case '继续'
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
                            cprintf('*Keywords','第%d次尝试重连失败！\n',ii);
                            mousemove(position2(1),position2(2));
                            pause(0.01)
                            mouseclick(1,1);
                            pause(0.01);
                            mousemove(position1(1),position1(2));
                            pause(1);
                            if ii==6
                                cprintf('*Keywords','程序重连失败，已强制中止刺激程序进程！\n');
                                return;
                            end
                        else
                            h=msgbox('程序已继续，本轮实验结束前禁止移动鼠标和使用键盘！','重要提示','warn');
                            cprintf('*Keywords','程序已继续，本轮实验结束前禁止移动鼠标和使用键盘！\n');
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
        disp(['第',num2str(i),'个试次的MI模式是：',classType{mode},'划动,提示时长为：',num2str(CueTime),'秒。']);

        %% 静息
        tic
        pause(RestTime-0.25);
                
        %% 0.3秒准备Beep
        sound(sin(2*pi*5*(1:4000)/100));
        if flag==1
            lptwrite(out,0);
        elseif flag==2
            write(out,0,'single')
        end
        pause(0.25)
        time.rest(i)=toc;
        
        %% 任一MI任务刺激
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
        %结束刺激
        robot.keyPress    (java.awt.event.KeyEvent.VK_P);
        robot.keyRelease    (java.awt.event.KeyEvent.VK_P);
        cprintf('*Comments','实验正常完成！\n');
    else
        cprintf('*Errors','实验未完成，程序被中止！\n');
    end
    
catch error
    if flag==2
        write(out,0,'uint8');
        clear out;% 关闭串口
    end
    rethrow(error);
end

if flag==1
    lptwrite(out,0);
elseif flag==2
    write(out,0,'uint8');
    clear out;% 关闭串口
end


time.cost=time.end-time.start;
time.min=fix((3600*time.cost(4)+60*time.cost(5)+time.cost(6))/60);
time.sec=rem(3600*time. cost(4)+60*time.cost(5)+time.cost(6),60);

% cprintf('*Keywords','本次实验耗时为:%d分%d秒，共进行%d Trials。 \n',time.min,time.sec,i);
cprintf('Keywords','本次实验耗时为:');
cprintf('Errors','%d分%d秒',time.min,time.sec);
cprintf('Keywords','，共进行了');
cprintf('Errors',' %d ',i);
cprintf('Keywords','个试次 \n');
%% 统计各类刺激时长误差
% cprintf('Keywords','平均休息间隔时长为 %d秒 \n',roundn(mean(time.rest(1:i-1)),-3));
cprintf('Keywords','平均休息间隔时长为');
cprintf('Errors','%d秒 \n',roundn(mean(time.rest(1:i-1)),-3));
if ismember(1,allmode(1:i))
% cprintf('Keywords','平均向左划船时长为 %d秒 \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
cprintf('Keywords','平均向左划船时长为');
cprintf('Errors','%d秒 \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
end
if ismember(2,allmode(1:i))
% cprintf('Keywords','平均向右划船时长为 %d秒 \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
cprintf('Keywords','平均向右划船时长为');
cprintf('Errors','%d秒 \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
end
if ismember(3,allmode(1:i))
% cprintf('Keywords','平均左右划船时长为 %d秒 \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
cprintf('Keywords','平均左右划船时长为');
cprintf('Errors','%d秒 \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
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
    %暂停
    for j=1:5
        mousemove(position1(1),position1(2));
        pause(0.05);
        robot.keyPress    (java.awt.event.KeyEvent.VK_P);
        robot.keyRelease    (java.awt.event.KeyEvent.VK_P);
        pause(0.05);
    end
else
    %取消暂停
    for j=1:5
        mousemove(position2(1),position2(2));
        pause(0.05);
        mouseclick(1,1);
        pause(0.05);
    end
end

mousemove(p(1),p(2));

end
