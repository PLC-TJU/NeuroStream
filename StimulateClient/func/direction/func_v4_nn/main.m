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
model = trainArrowCNN(Xtrain, Ytrain);

% 在线预测
tic
prediction = classifyArrowCNN(Xtest, model);
acc=sum(prediction == Ytest) / length(Ytest) * 100;
disp(acc);
angles = estimateArrowAngleUnsupervised(Xtest, model);
toc
%%
model = trainArrowCNN(samples, labels);
prediction = classifyArrowCNN(samples, model);
angles = estimateArrowAngleUnsupervised(samples, model);
acc=sum(prediction == labels) / length(labels) * 100;
disp(acc);



% save('model_classifyArrowImage.mat','model','Hind','Wind')

%%
j=29;
for i=1:25
subplot(5,5,i);
imshow(samples(:,:,:,i+25*(j-1)))
title(['(',num2str(i),')-',num2str(labels(i+25*(j-1)))])
end
%%
% labels([2,11,21,24]+25*(j-1))=3;
