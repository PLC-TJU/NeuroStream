function stimulate_auto(Block,CueTime,RestTime,TrialNum,Address,SaveFig)
% 是否保存训练/测试过程中的任务提示图像样本
if ~exist('SaveFig','var') || isempty(SaveFig)
    SaveFig = 0;
end
if SaveFig ~=0
    samples=[];
    labels=[];
end

import java.awt.Robot;
import java.awt.event.*;
robot = java.awt.Robot;

%% 选择实验任务模式
% Block=1(Left) / 2(Right) / 3(Left & Right) / 4(Mix) / otherwise(auto)
classType={'左手','右手','双手'};
switch Block
    case 1
        allmode(1:TrialNum)=1;%Left
    case 2
        allmode(1:TrialNum)=2;%Right
    case 3
        allmode(1:TrialNum/2)=1;%Left
        allmode(TrialNum/2+1:TrialNum)=2;%Right
        allmode= allmode(randperm(length(allmode)));
    case 4
        N=TrialNum/3;
        allmode=[ones(1,N),2*ones(1,N),3*ones(1,N)];
        allmode= allmode(randperm(length(allmode)));
    otherwise % auto online game 模式
        Block = 'online_game';
        allmode = randi([1,3],TrialNum+10,1);
end
time.modeS=0;time.modeL=0;time.modeR=0;
TypeNum=zeros(1,4);
stopFlag=false;
restBeep=false;%是否使用beep提示静息

%% 验证通信方式
[flag, out] = configureCommunication(Address);

%% 确认NeuRow程序正确运行
Result=GUI_Calibration(1);
position1=[-5,1075];%1919,30
position2=[-437,300];%1483,300 %暂停按键位置坐标
if ~Result
    pauseFlag(2,position1,position2);% 取消暂停
    Result=GUI_Calibration(1);
    pause(0.1);
    pauseFlag(1,position1,position2);% 执行暂停
    if ~Result
        errordlg('请预先按要求启动NeuRow软件！');
        return        
    end
end
h=msgbox('刺激操作由程序接管，本轮实验结束前禁止移动鼠标和使用键盘！','重要提示','warn');
cprintf('*Keywords','刺激范式由程序接管，本轮实验结束前禁止移动鼠标和使用键盘！\n');

pauseFlag(2,position1,position2,0.5);% 取消暂停
pauseFlag(3,position1,position2,0.5);% 锚定界面

delete(h);

% 确保左右按键是释放状态
robot.keyPress    (java.awt.event.KeyEvent.VK_LEFT);
robot.keyPress    (java.awt.event.KeyEvent.VK_RIGHT);
pause(0.01)
robot.keyRelease  (java.awt.event.KeyEvent.VK_LEFT);
robot.keyRelease  (java.awt.event.KeyEvent.VK_RIGHT);

%% 开始刺激界面
try    
    time.start=fix(clock); 
    time.modeL=0;time.modeS=0;time.modeR=0;time.rest=0;
    for i=1:length(allmode)        
        %% 开始静息
        if i>1 && restBeep
            sound(sin(2*pi*5*(1:4000)/100));%Beep一声
        end
        
        tic;
        while toc<RestTime
            if ~stopFlag
                % 检测是否主动暂停实验范式
                stopFlag = check_runStatu(position1,position2);
                pause(0.1);
            else
                break;
            end
        end

        % 是否获取了足够的两类样本/主动暂停
        if stopFlag || all(TypeNum(1:2)>=TrialNum/2)
            break;
        end

        %% 确定任务模式
        if strcmp(Block,'online_game')   
            % 获取游戏进程
            [prediction,sample] = DetectDirection;
            mode=prediction;

            % 确保获取足够的两类样本
            TypeNum(prediction)=TypeNum(prediction)+1;

            % 记录任务提示图像样本
            if SaveFig ~=0
                samples=cat(4,samples,sample);
                labels=cat(1,labels,prediction);
            end
        else
            mode=allmode(i);
        end

        disp(['第',num2str(i),'个试次的MI模式是：',classType{mode}, ...
            '划动,提示时长为：',num2str(CueTime),'秒。']);
                
        %% 0.5秒准备Beep*2
        if flag==1
            lptwrite(out,0);
        elseif flag==2
            write(out,0,'uint8');
        end
        time.rest(i)=toc;
        
        sound(sin(2*pi*7*(1:2000)/100));
        pauseFlag(3,position1,position2,0.5);% 锚定界面
        sound(sin(2*pi*7*(1:2000)/100));

        %% 任一MI任务提示
        tic
        if flag==1
            lptwrite(out,mode);
        elseif flag==2
            write(out,mode,'uint8')
        end
        switch mode
            case 1                
                robot.keyPress    (java.awt.event.KeyEvent.VK_LEFT);               
                pauseFlag(3,position1,position2,CueTime);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_LEFT);
                time.modeL(i)=toc;
            case 2               
                robot.keyPress    (java.awt.event.KeyEvent.VK_RIGHT);               
                pauseFlag(3,position1,position2,CueTime);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_RIGHT);
                time.modeR(i)=toc;
            case 3                
                pause(CueTime);
                time.modeS(i)=toc;
            case 4                
                robot.keyPress    (java.awt.event.KeyEvent.VK_LEFT);
                robot.keyPress    (java.awt.event.KeyEvent.VK_RIGHT);     
                pauseFlag(3,position1,position2,CueTime);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_LEFT);
                robot.keyRelease  (java.awt.event.KeyEvent.VK_RIGHT);
                time.modeS(i)=toc;
        end

        %% 诱导画面结束预留2秒用于反馈
%         pauseFlag(3,position1,position2,2);

    end
    time.end=fix(clock);
    
    %结束实验
    pauseFlag(1,position1,position2);% 执行暂停
    if i>=length(allmode)
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
cprintf('Keywords','个试次, \n');
if strcmp(Block,'online_game')
    cprintf('Keywords','其中第一类样本');
    cprintf('Errors',' %d 个',TypeNum(1));
    cprintf('Keywords','，第二类样本');
    cprintf('Errors',' %d 个\n',TypeNum(2));
end

%% 统计各类刺激时长误差
% cprintf('Keywords','平均休息间隔时长为 %d秒 \n',roundn(mean(time.rest(1:i-1)),-3));
cprintf('Keywords','平均休息间隔时长为');
cprintf('Errors','%d秒 \n',roundn(mean(time.rest(1:i-1)),-3));
if sum(time.modeL)>0
% cprintf('Keywords','平均向左划船时长为 %d秒 \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
cprintf('Keywords','平均向左划船时长为');
cprintf('Errors','%d秒 \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
end
if sum(time.modeR)>0
% cprintf('Keywords','平均向右划船时长为 %d秒 \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
cprintf('Keywords','平均向右划船时长为');
cprintf('Errors','%d秒 \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
end
if sum(time.modeS)>0
% cprintf('Keywords','平均左右划船时长为 %d秒 \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
cprintf('Keywords','平均左右划船时长为');
cprintf('Errors','%d秒 \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
end
%% 保存方向图像样本
if SaveFig ~=0
    folder='func\direction\samples';
    if ~isfolder(folder)
        mkdir(folder);
    end

    filepath=fullfile(folder,['Samples_',datetime('now','Format','yyyyMMdd_HHmmss'),'.mat']);
    save(filepath,'samples','labels')
end
end


function pauseFlag(flag,position1,position2,costtime)
import java.awt.Robot;
import java.awt.event.*;
robot = java.awt.Robot;

if nargin<4 || isempty(costtime)
    costtime=0.5;
end
if nargin<3 || isempty(position2)
    position2=[-437,300];
end
if nargin<2 || isempty(position1)
    position1=[-5,1080];
end

[p(1),p(2)]=getmouse;

if costtime<0.1
    costtime=0.1;
end

switch flag
    case 1
        %暂停
        for j=1:5
            mousemove(position1(1),position1(2));
            pause(costtime/10);
            mouseclick(1,1);
            robot.keyPress    (java.awt.event.KeyEvent.VK_P);
            robot.keyRelease    (java.awt.event.KeyEvent.VK_P);
            pause(costtime/10);
        end
    case 2
        %取消暂停
        for j=1:5
            mousemove(position2(1),position2(2));
            pause(costtime/10);
            mouseclick(1,1);
            pause(costtime/10);
        end
    case 3
        %锚定界面
        for j=1:5
            mousemove(position1(1),position1(2));
            pause(costtime/10);
            mouseclick(1,1);
            pause(costtime/10);
        end
end

mousemove(p(1),p(2));

end

function stopFlag = check_runStatu(position1,position2)
if nargin<2 || isempty(position2)
    position2=[-437,300];
end
if nargin<1 || isempty(position1)
    position1=[-5,1080];
end

[p(1),p(2)]=getmouse;
if norm(p-[0,0],'fro')<=100%主屏幕左上角
    pauseFlag(1,position1,position2);% 执行暂停
    button=questdlg('是否继续或退出刺激程序？','程序暂停','继续','退出','退出');
    switch button
        case '继续'
            pauseFlag(2,position1,position2,1);% 取消暂停
            for ii=1:5
                Result=GUI_Calibration(1);
                if ~Result
                    cprintf('*Keywords','第%d次尝试重连失败！\n',ii);
                    pauseFlag(2,position1,position2,1);% 取消暂停
                    if ii==5
                        cprintf('*Keywords','程序重连失败，已强制中止刺激程序进程！\n');
                        stopFlag = true;
                        return;
                    end
                else
                    h=msgbox('程序已继续，本轮实验结束前禁止移动鼠标和使用键盘！','重要提示','warn');
                    cprintf('*Keywords','程序已继续，本轮实验结束前禁止移动鼠标和使用键盘！\n');
                    % pauseFlag(3,position1,position2,1);% 锚定界面
                    delete(h);
                    stopFlag = false;
                    break;
                end
            end
        otherwise
            stopFlag = true;
    end
else
    stopFlag = false;
    % pauseFlag(3,position1,position2,0.5);% 锚定界面
end
end

