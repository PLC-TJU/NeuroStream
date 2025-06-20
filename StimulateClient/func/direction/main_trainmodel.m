%% 加载数据
load('Samples_20250609T083352.mat')

%%
N=length(labels);
ind=randperm(N);
trainnum=round(0.8*N);
testnum=N-trainnum;
trainind=ind(1:trainnum);
testind=ind(N-testnum+1:N);
Xtrain=samples(:,:,:,trainind);
Ytrain=labels(trainind);
Xtest=samples(:,:,:,testind);
Ytest=labels(testind);

% 训练
model = trainArrowClassifier(Xtrain, Ytrain);

% 测试
tic
[prediction, scores, angles] = classifyArrowImage(Xtest, model);
acc=sum(prediction == Ytest) / length(Ytest) * 100;
disp(acc);
toc

% 展示分类错误的样本
close all;
ind=testind(prediction ~= Ytest);
pred=prediction(prediction ~= Ytest);
for i=1:length(ind)
    figure(i);
    imshow(samples(:,:,:,ind(i)))
    title(['(',num2str(ind(i)),')-',num2str(labels(ind(i))),'-',num2str(pred(i))])
end

%% 使用所有样本训练分类模型
model = trainArrowClassifier(samples, labels);
[prediction, scores, angles] = classifyArrowImage(samples, model);
acc=sum(prediction == labels) / length(labels) * 100;
disp(acc);

save('model_classifyArrowImage.mat','model','Hind','Wind')

%% 查看样本
j=19;
for i=1:15
subplot(5,5,i);
imshow(samples(:,:,:,i+25*(j-1)))
title(['(',num2str(i),')-',num2str(labels(i+25*(j-1)))])
end
%% 校正标签（第一类）
labels([7]+25*(j-1))=1;

%% 校正标签（第一类）
labels([9]+25*(j-1))=2;

%% 校正标签（第一类）
labels([2,11,21,24]+25*(j-1))=3;

%% 重新保存样本数据
save('samples\samples.mat','samples','labels','Hind','Wind');

