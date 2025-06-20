%% SVM分类结果可视化
%来源：Pan.LC 2021.11.24
%实现二维特征进行SVM分类的可视化（对于大于二维的数据必须要先进行降维）
%超过4类时，请补充color_p、color_b颜色维度
function SVM_plot(data,label,model,acc)
%data:特征向量，samples*dim
%label:标签，samples*1
%model:libSVM分类模型
%acc:分类正确率
if nargin<4
    [~, acc,~] = libsvmpredict(label, data, model,'-q');
end
acc=roundn(acc(1),-2);

% 确定类别数
labelNum=model.nr_class;
switch labelNum
    case 2
        classtype={'LH','RH'};
    case 3
        classtype={'LH','RH','FT'};
end

% 生成网格点
d = 0.005;
[X1, X2] = meshgrid(min(data(:,1)):d:max(data(:,1)), min(data(:,2)):d:max(data(:,2)));
X_grid = [X1(:), X2(:)];

% 设定网格点标签（仅充当输入参数）
grid_label = ones(size(X_grid, 1), 1);

% 预测网格点标签
[pre_label, ~, ~] = libsvmpredict(grid_label, X_grid, model,'-q');

% 颜色预设
color_p = [220, 94, 75; 30 144 255; 150, 138, 191; 12, 112, 104]/255; % 数据点颜色
color_b = [244, 195, 171; 135 206 250;218, 216, 232;179,226,219]/255; % 边界区域颜色

% 绘制散点图
figure
hold on
ax(1:labelNum) = gscatter(X_grid (:,1), X_grid (:,2), pre_label, color_b(1:labelNum,:));
legend('off')
axis tight

% 绘制原始数据图
ax(labelNum+1:labelNum*2) = gscatter(data(:,1), data(:,2), label);
for num=1:labelNum
    set(ax(labelNum+num), 'Marker','o', 'MarkerSize', 7, 'MarkerEdgeColor','k', 'MarkerFaceColor', color_p(num,:));
end

legend('off')
set(gca, 'linewidth', 1.1)
% title('Decision boundary (gaussian kernel function)')
axis tight

degree=model.Parameters(3);
gamma=model.Parameters(4); 
coef0=model.Parameters(5);
switch model.Parameters(2)
    case 0
        Kernel='线性核函数:u''*v';
    case 1
%         Kernel='多项式核函数:(gamma*u’*v + coef0)^degree ';
        if coef0~=0
            Kernel=['多项式核函数:(',num2str(gamma),'*u''*v+',num2str(coef0),')^',num2str(degree)];
        else
            Kernel=['多项式核函数:(',num2str(gamma),'*u''*v)^',num2str(degree)];
        end
    case 2
%         Kernel='RBF(径向基)核函数:exp(-gamma*|u-v|^2）';
        Kernel=['RBF(径向基)核函数:exp(-',num2str(gamma),'*|u-v|^2)'];
    case 3
%         Kernel='sigmoid核函数:tanh(gamma*u’*v + coef0) ';
        if coef0~=0
            Kernel=['sigmoid核函数:tanh(',num2str(gamma),'*u''*v+',num2str(coef0),')'];
        else
            Kernel=['sigmoid核函数:tanh(',num2str(gamma),'*u''*v)'];
        end
end
title(['SVM分类结果(',Kernel,'),正确率:',num2str(acc),'%']);
xlabel('第一维特征值')
ylabel('第二维特征值')
legend(ax(labelNum+1:labelNum*2),classtype)
end

% MDRM=get(gca,'Children');
% for i=1:14
% x(i,:)=get(MDRM(i),'xdata');
% y(i,:)=get(MDRM(i),'ydata');
% m{i,1}=get(MDRM(i),'Marker');
% r{i,1}=get(MDRM(i),'Color');
% end
% r=fliplr(r')';
% m=fliplr(m')';
% y=fliplr(y')';
% x=fliplr(x')';
% for i=1:14
% data([1:90]+(i-1)*90,1)=x(i,:);
% data([1:90]+(i-1)*90,2)=y(i,:);
% end
% label=[ones(90,1);2*ones(90,1)];
% label=repmat(label,7,1);
% model = libsvmtrain(label, data, '-t 0 -c 1 -q');
% [~, acc, ~] = libsvmpredict(label, data, model);
% SVM_plot(data,label,model,acc);