function stimulate_plc(Block,CueTime,RestTime,TrialNum,Adress)

persistent frame_S frame_L frame_R y fs

%% 验证通信方式
[flag, out] = configureCommunication(Adress);

%% 加载数据
h=waitbar(0,'加载中，请稍等...');
if isempty(frame_L) || isempty(frame_R) || isempty(frame_S) || isempty(y) || isempty(fs)
    [y, fs] = audioread('water.wav');

    filename = 'LeftTurn.MP4';
    video_L = VideoReader(filename);
    % nFrame_L = video_L.NumberOfFrame;

    filename = 'RightTurn.MP4';
    video_R = VideoReader(filename);
    % nFrame_R = video_R.NumberOfFrame;

    filename = 'Stop.MP4';
    video_S = VideoReader(filename);
    % nFrame_S = video_S.NumberOfFrame;    
    waitbar(10/100,h,'首次打开加载时间较长，请耐心等待！...10%')
    
    frame_S = read(video_S); 
    waitbar(50/100,h,'马上就好~~~...50%')
    
    frame_L = read(video_L);   
    waitbar(75/100,h,'请保持平静！...75%')
    
    frame_R = read(video_R);
    waitbar(95/100,h,'精彩马上开始！...90%')
end

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
        allmode(TrialNum/2+1:TrialNum)=2;%Left
    case 4
        N=TrialNum/3;
        for l=1:3:3*N
            rand=randperm(3);
            allmode(l:l+2)=rand;
        end
end
allmode= allmode(randperm(length(allmode)));

time.modeS=0;time.modeL=0;time.modeR=0;
waitbar(0.95,h,'请保持平静！...95%')

%% 开始刺激界面
try
    
    KbName('UnifyKeyNames');
    HideCursor;
    waitbar(1,h,'预加载完毕，即将启动刺激程序！...100%')
    delete(h);
    Screen('Preference', 'SkipSyncTests', 1);
    % Here we call some default settings for setting up Psychtoolbox
    PsychDefaultSetup(2);
    % Get the screen numbers
    screens = Screen('Screens');
    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    wPtr=Screen('OpenWindow',screenNumber,[153 204 255]);% 100 149 237
    %     offScreen=Screen('OpenOffscreenWindow',wPtr);
    

    escape=KbName('ESCAPE');
    space=KbName('space');
    
    ListenChar(2);
    
    fontname='宋体';
    Screen('TextSize',wPtr,60);
    Screen('TextStyle' ,wPtr,1);
    % Screen('TextColor',wPtr,0);
    
    string={'Relax！','Ready?','Press SPACE to start!','Press any key to end！'};
%     string={'请放松！','请准备！','请按空格键开始实验！','请按任意键结束实验！'};
    bounds=zeros(size(string,1),4);
    for i=1:length(string)
        bounds(i,:) = Screen(wPtr , 'TextBounds', double(string{i}) );
    end

%     [xc,yc]=WindowCenter(wPtr);
    xc=960;yc=540;
    
    Screen('DrawText',wPtr,double(string{3}),xc-bounds(3,3)/2,yc-bounds(3,4)/2);
    Screen('Flip',wPtr);
    % KbWait; % 按键继续程序
    
    while 1
        [kD,secs,kC]=KbCheck;
        if kC(space)
            time.start=fix(clock);
            break;
        elseif kD
            fprintf('你按的是： %s, [请按空格键开始！]\n',char(KbName(kC)));
%             a=strcat('You pressed:',char(KbName(kC)),', Please press SPACE to start！');
%             bounds(5,:)=Screen(wPtr,'TextBounds', double(a));
%             Screen('DrawText',wPtr,double(a),xc-bounds(5,3)/2,yc-bounds(5,4)/2,[255,0,0]);
            
            a1=strcat('You pressed:',char(KbName(kC)));bounds(5,:)=Screen(wPtr,'TextBounds', double(a1));
            a2='Please press SPACE to start！';bounds(6,:)=Screen(wPtr,'TextBounds', double(a2));
            Screen('DrawText',wPtr,double(a1),xc-bounds(5,3)/2,yc-bounds(5,4)/2-45,[255,0,0]);
            Screen('DrawText',wPtr,double(a2),xc-bounds(6,3)/2,yc-bounds(6,4)/2+45,[0,0,0]);
            Screen('Flip',wPtr);
            while KbCheck
            end
        end
        
    end
    
    ListenChar(0);
    time.modeL=0;time.modeS=0;time.modeR=0;time.rest=0;
    for i=1:length(allmode)
        
        mode=allmode(i);
%         disp(['第',num2str(i),'个试次的MI模式是：',classType{mode},'划动,时长为：',num2str(TimeLimit),'秒。']);
        cprintf('Text','第');
        cprintf('UnterminatedStrings','%d',i);
        cprintf('Text','个试次的MI模式是：');
        cprintf('UnterminatedStrings',[classType{mode},'划动 ']);
        cprintf('Text',',时长为：%d秒。 \n',CueTime);
        %%  4秒休息
        tic
        Screen('DrawText',wPtr,double(string{1}),xc-bounds(1,3)/2,yc-bounds(1,4)/2,0 );
        Screen('Flip',wPtr);
        FlushEvents('keyDown');
        while toc<=RestTime-0.25
            [~,~,kC]=KbCheck;
            if kC(escape)
                break;
            end
        end
        time.rest(i)=toc;
        if toc<RestTime
            break;
        end
        
        
        %% 0.25秒准备
        sound(sin(2*pi*5*(1:4000)/100));
        Screen('DrawText',wPtr,double(string{2}),xc-bounds(2,3)/2,yc-bounds(2,4)/2,[200,0,0]);
        Screen('Flip',wPtr);
        if flag==1
            lptwrite(out,0);
        elseif flag==2
            write(out,0,'single')
        end
        pause(0.25)
        
       %% 8秒任一刺激
        tic
        sound(y, fs)
        if flag==1
            lptwrite(out,mode);
        elseif flag==2
            write(out,mode,'single')
        end
        switch mode
            case 3        
                for k=1:size(frame_S,4)
                    
                    Screen('PutImage',wPtr,frame_S(:,:,:,k),[0 0 1920 1080])
                    Screen('Flip',wPtr);
                    
                    [kD,secs,kC]=KbCheck;
                    if kC(escape)
                        break;
                    end
                    
                    if toc>=CueTime
                        time.modeS(i)=toc;
                        break;
                    end
                    
                end
                if toc<CueTime-0.5
                    break;
                end
                
                
            case 1
                for k=1:size(frame_L,4)
                    
                    Screen('PutImage',wPtr,frame_L(:,:,:,k),[0 0 1920 1080])
                    Screen('Flip',wPtr);
                    
                    [kD,secs,kC]=KbCheck;
                    if kC(escape)
                        break;
                    end
                    
                    if toc>=CueTime
                        time.modeL(i)=toc;
                        break;
                    end
                    
                end
                if toc<CueTime-0.5
                    break;
                end
                
            case 2
                for k=1:size(frame_R,4)
                    
                    Screen('PutImage',wPtr,frame_R(:,:,:,k),[0 0 1920 1080])
                    Screen('Flip',wPtr);
                    
                    [kD,secs,kC]=KbCheck;
                    if kC(escape)
                        break;
                    end
                    
                    if toc>=CueTime
                        time.modeR(i)=toc;
                        break;
                    end
                    
                end
                if toc<CueTime-0.5
                    break;
                end
                
        end
        clear sound;
        
    end
    time.end=fix(clock);
    if i==length(allmode)
        Screen('DrawText',wPtr,double(string{4}),xc-bounds(4,3)/2,yc-bounds(4,4)/2,0);
        Screen('Flip',wPtr);
        KbWait; % 按键跳出程序
        cprintf('*Comments','实验正常完成！\n');
    else
        cprintf('*Errors','实验未完成，程序被中止！\n');
    end
    ListenChar(0);
    clear sound;
    sca;
    ShowCursor;
    
catch error
    if flag==2
        write(out,0,'uint8');
        clear out;% 关闭串口
    end
    ListenChar(0);
    ShowCursor;
    sca;
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
cprintf('UnterminatedStrings','%d分%d秒',time.min,time.sec);
cprintf('Keywords','，共进行了');
cprintf('UnterminatedStrings',' %d ',i);
cprintf('Keywords','个试次 \n');
%% 统计各类刺激时长误差
% cprintf('Keywords','平均休息间隔时长为 %d秒 \n',roundn(mean(time.rest(1:i-1)),-3));
cprintf('Keywords','平均休息间隔时长为');
cprintf('UnterminatedStrings','%d秒 \n',roundn(mean(time.rest(1:i-1)),-3));
if ismember(1,allmode(1:i))
% cprintf('Keywords','平均向左划船时长为 %d秒 \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
cprintf('Keywords','平均向左划船时长为');
cprintf('UnterminatedStrings','%d秒 \n',roundn(sum(time.modeL)/length(find(time.modeL~=0)),-3));
end
if ismember(2,allmode(1:i))
% cprintf('Keywords','平均向右划船时长为 %d秒 \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
cprintf('Keywords','平均向右划船时长为');
cprintf('UnterminatedStrings','%d秒 \n',roundn(sum(time.modeR)/length(find(time.modeR~=0)),-3));
end
if ismember(3,allmode(1:i))
% cprintf('Keywords','平均左右划船时长为 %d秒 \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
cprintf('Keywords','平均左右划船时长为');
cprintf('UnterminatedStrings','%d秒 \n',roundn(sum(time.modeS)/length(find(time.modeS~=0)),-3));
end
