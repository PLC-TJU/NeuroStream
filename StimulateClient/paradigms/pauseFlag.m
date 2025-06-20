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