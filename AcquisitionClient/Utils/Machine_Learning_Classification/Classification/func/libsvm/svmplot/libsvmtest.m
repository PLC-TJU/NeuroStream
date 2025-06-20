clc
close all
% clear 

% 生成3类样本（二维高斯分布）
mu = [5 5];
sigma = [1 0; 0 1];
X_1 = mvnrnd(mu, sigma, 100);
label_1 = ones(100, 1);

mu = [3 9];
sigma = [1 0; 0 1];
X_2 = mvnrnd(mu, sigma, 100);
label_2 = 2*ones(100, 1);

mu = [-1 7];
sigma = [1 0; 0 1];
X_3 = mvnrnd(mu, sigma, 100);
label_3 = 3*ones(100, 1);

% 整理
data = [X_1; X_2; X_3];
label = [label_1; label_2; label_3];


% 参数设置
c = 0.5;  % trade-off parameter
g = 0.01; % kernel width

% 训练SVM模型
cmd = ['-s 0 -t 2 ', '-c ', num2str(c), ' -g ', num2str(g), ' -q'];
model = libsvmtrain(label, data, cmd);
[~, acc, ~] = libsvmpredict(label, data, model); 

SVM_plot(data,label,model,acc);
