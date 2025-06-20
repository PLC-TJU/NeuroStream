Hind = 780:1020;%高度范围
Wind = 825:1115;%宽度范围

LeftSample=zeros(length(Hind),length(Wind),3,size(LeftTurn,4),'uint8');
for i=1:size(LeftTurn,4)
    LeftSample(:,:,:,i)=LeftTurn(Hind,Wind,:,i);
end
num=155;
Label1=cat(1,ones(num,1),3*ones(size(LeftTurn,4)-num,1));

RightSample=zeros(length(Hind),length(Wind),3,size(RightTurn,4),'uint8');
for i=1:size(RightTurn,4)
    RightSample(:,:,:,i)=RightTurn(Hind,Wind,:,i);
end
num=155;
Label2=cat(1,2*ones(num,1),3*ones(size(RightTurn,4)-num,1));

StopSample=zeros(length(Hind),length(Wind),3,size(Stop,4),'uint8');
for i=1:size(Stop,4)
    StopSample(:,:,:,i)=Stop(Hind,Wind,:,i);
end
Label3=3*ones(size(Stop,4),1);

samples=cat(4,LeftSample,RightSample,StopSample);
labels=cat(1,Label1,Label2,Label3);

%%
N=length(labels);
ind=randperm(N);
trainind=ind(1:N-100);
testind=ind(N-99:N);
Xtrain=samples(:,:,:,trainind);
Ytrain=labels(trainind);
Xtest=samples(:,:,:,testind);
Ytest=labels(testind);

% 离线训练
model = trainArrowClassifier(Xtrain, Ytrain);

% 在线预测
tic
[prediction, scores, angles] = classifyArrowImage(Xtest, model);
acc=sum(prediction == Ytest) / length(Ytest) * 100;
disp(acc);
toc
%%
model = trainArrowClassifier(samples, labels);
[prediction, scores, angles] = classifyArrowImage(samples, model);
acc=sum(prediction == labels) / length(labels) * 100;
disp(acc);

save('model_classifyArrowImage.mat','model','Hind','Wind')

%%
j=29;
for i=1:25
subplot(5,5,i);
imshow(samples(:,:,:,i+25*(j-1)))
title(['(',num2str(i),')-',num2str(labels(i+25*(j-1)))])
end
%%
labels([2,11,21,24]+25*(j-1))=3;
