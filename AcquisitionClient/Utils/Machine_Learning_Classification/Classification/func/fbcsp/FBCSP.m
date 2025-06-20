%% FBCSP
% [1] Ang K K, Chin Z Y, Zhang H, et al. Filter Bank Common Spatial Pattern (FBCSP) in 
% Brain-Computer Interface. IEEE International Joint Conference on Neural Networks 
% (IEEE World Congress on Computational Intelligence), Hong Kong. 2008: 2390-2397
% [2] Ang K K, Chin Z Y, Wang C, et al. Filter Bank Common Spatial Pattern Algorithm on BCI 
% Competition IV Datasets 2a and 2b. Front Neurosci, 2012, 6: 39.

% Author: Pan Lincong
% Edition date: 22 April 2023

%% 参数说明
% 输入
% traindata     训练集的任务态样本,导联数*时间点数*样本数;
% trainlabel    训练集的标签
% testdata      测试集的任务态样本,导联数*时间点数*样本数;

% 可选输入
% paraSet       空间-时间-频率参数，cell:3*1

% 输出
% trainFeaSelect训练集特征
% testFeaSelect 测试集特征

function [trainFeaSelect,testFeaSelect]=FBCSP(traindata,trainlabel,testdata,k,paraSet,fs)
if ~exist('fs','var') || isempty(fs)
    fs=250;
end
if ~exist('k','var') || isempty(k)
    k=4;
end

if ~exist('paraSet','var') || isempty(paraSet)
    timewindows=[0,3];
%     freqsbands=[8,12;10,14;12,16;14,18;16,20;18,22;20,24;22,26;24,28;26,30];
    freqsbands=[4,8;8,12;12,16;16,20;20,24;24,28;28,32;4,12;12,30];
else
    timewindows=nan(size(paraSet,1),2);
    freqsbands=nan(size(paraSet,1),2);
    for i=1:size(paraSet,1)
        timewindows(i,:)=paraSet{i,2};
        freqsbands(i,:) =paraSet{i,3};
    end
    timewindows=unique(timewindows,'rows');
    freqsbands=unique(freqsbands,'rows');
end

trainFea=[];
testFea=[];

if ~isempty(timewindows)
    for t=1:size(timewindows,1)
        for f=1:size(freqsbands,1)
            tw=timewindows(t,:);
            fb=freqsbands(f,:);
            trainData=ERPs_Filter(traindata,fb,[],tw,fs);
            testData=ERPs_Filter(testdata,fb,[],tw,fs);

            [trainfea,testfea]=CSPfeature(trainData,trainlabel,testData,k);

            trainFea=cat(2,trainFea,real(trainfea));
            testFea=cat(2,testFea,real(testfea));
        end
    end
else
    for f=1:size(freqsbands,1)
        fb=freqsbands(f,:);
        trainData=ERPs_Filter(traindata,fb,[],fs);
        testData=ERPs_Filter(testdata,fb,[],fs);

        [trainfea,testfea]=CSPfeature(trainData,trainlabel,testData,k);

        trainFea=cat(2,trainFea,real(trainfea));
        testFea=cat(2,testFea,real(testfea));
    end
end


% %Feature Selection
if size(trainFea,2) > 12
    k2=round(0.3*size(trainFea,2));%选择30%的特征
else
    k2=min(4,size(trainFea,2));
end

sort_tmp=all_MuI(trainFea,trainlabel);
index=sort_tmp(1:k2,2);
trainFeaSelect=trainFea(:,index);
testFeaSelect=testFea(:,index);

% SVMmodel=libsvmtrain(trainlabel,trainFea(:,index),'-t 0 -c 1 -q');
% [prediction,acc,~]=libsvmpredict(testlabel,testFea(:,index),SVMmodel);
% testAcc=acc(1);