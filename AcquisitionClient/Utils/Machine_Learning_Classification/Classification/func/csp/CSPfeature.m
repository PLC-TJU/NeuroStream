%% train CSP filters
% 共空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2021.5.1

function [fTrain,fTest,CovXtrain,CovXtest,W]=CSPfeature(xTrain,yTrain,xTest,nFilters)
%% 变量说明
% 输入
% xTrain:训练集，channels*points*trials or channels*channels*trials
% yTrain:训练集标签，1*trials or trials*1
% xTest:测试集，channels*points*trials or channels*channels*trials
% nFilters:CSP滤波器阶数，实际输出阶数为 2*nFilters
% 输出
% fTrain:训练集特征，trials*2nFilters
% fTest:测试集特征，trials*2nFilters
% CovXtrain:训练集滤波后的样本协方差矩阵，2nFilters*2nFilters*trials
% CovXtest:测试集滤波后的样本协方差矩阵，2nFilters*2nFilters*trials
% W:空间滤波器，channels*2nFilters

if ~exist('xTest','var') || isempty(xTest)
    xTest=[];
    fTest=[];
    CovXtest=[];
end
if ~exist('nFilters','var') || isempty(nFilters)
    nFilters=3;
end

cs=unique(yTrain);
xTrain0=xTrain(:,:,yTrain==cs(1));
xTrain1=xTrain(:,:,yTrain==cs(2));

if issymmetric(mean(xTrain,3))
    Sigma0=mean_covariances(xTrain0,'arithmetic');
    Sigma1=mean_covariances(xTrain1,'arithmetic');
else
    Sigma0=mean_covariances(covariances(xTrain0),'arithmetic');
    Sigma1=mean_covariances(covariances(xTrain1),'arithmetic');
end

[d,v]=eig(Sigma1\Sigma0);
[~,ids]=sort(diag(v),'descend');
W=d(:,ids([1:nFilters end-nFilters+1:end])); 

fTrain=zeros(size(xTrain,3),size(W,2));
CovXtrain=zeros(size(W,2),size(W,2),size(xTrain,3));

if issymmetric(mean(xTrain,3))
    for i=1:size(xTrain,3)
        CovXtrain(:,:,i)=W'*xTrain(:,:,i)*W;
        fTrain(i,:)=log10(diag(CovXtrain(:,:,i))/trace(CovXtrain(:,:,i)));
    end
    if ~isempty(xTest)
        fTest=zeros(size(xTest,3),size(W,2));
        CovXtest=zeros(size(W,2),size(W,2),size(xTest,3));
        for i=1:size(xTest,3)
            CovXtest(:,:,i)=W'*xTest(:,:,i)*W;
            fTest(i,:)=log10(diag(CovXtest(:,:,i))/trace(CovXtest(:,:,i)));
        end
    end
else
    for i=1:size(xTrain,3)
        CovXtrain(:,:,i)=W'*xTrain(:,:,i)*xTrain(:,:,i)'*W;
        fTrain(i,:)=log10(diag(CovXtrain(:,:,i))/trace(CovXtrain(:,:,i)));
    end
    if ~isempty(xTest)
        fTest=zeros(size(xTest,3),size(W,2));
        CovXtest=zeros(size(W,2),size(W,2),size(xTest,3));
        for i=1:size(xTest,3)
            CovXtest(:,:,i)=W'*xTest(:,:,i)*xTest(:,:,i)'*W;
            fTest(i,:)=log10(diag(CovXtest(:,:,i))/trace(CovXtest(:,:,i)));
        end
    end
end



