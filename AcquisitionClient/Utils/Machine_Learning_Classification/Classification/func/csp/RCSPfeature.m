%%  train RCSP filters
% 共空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2021.5.1

function [fTrain,fTest,CovXtrain,CovXtest]=RCSPfeature(Xs,ys,Xt,ytTrain,nFilters,beta,gamma)
% 输入：
% Xs:源数据，channels*points*trials or channels*channels*trials
% ys:源数据标签，1*trials or trials*1
% Xt:目标数据（训练样本+测试样本），channels*points*(trials1+trials2) or channels*channels*(trials1+trials2)
% ytTrain:目标数据中训练样本的标签，注意不包含测试样本的标签，1*trials1 or trials1*1
% nFilters:RCSP滤波器阶数，实际输出阶数为 2*nFilters
% beta，gamma: RCSP的超参数，默认均为0.1
% 输出：
% fTrain:（训练样本+源数据）的特征集合，(trials1+trials)*2nFilters
% fTest:测试样本的特征集合，trials2*2nFilters
% CovXtrain:（训练样本+源数据）滤波后的样本协方差矩阵，2nFilters*2nFilters*(trials1+trials)
% CovXtest:测试样本滤波后的样本协方差矩阵，2nFilters*2nFilters*trials2

if ~exist('nFilters','var') || isempty(nFilters)
    nFilters=3;
end

if ~exist('beta','var') || isempty(beta)
    beta=0.1;
end

if ~exist('gamma','var') || isempty(gamma)
    gamma=0.1;
end

[nChannels,~,N]=size(Xs); M=size(Xt,3); m=length(ytTrain);
XtTest=Xt(:,:,m+1:end);
cs=unique(ys);
Xs0=Xs(:,:,ys==cs(1)); 
Xs1=Xs(:,:,ys==cs(2));
XtTrain0=Xt(:,:,ytTrain==cs(1));
XtTrain1=Xt(:,:,ytTrain==cs(2));
SigmaS0=zeros(nChannels);  SigmaS1=zeros(nChannels);
SigmaT0=zeros(nChannels);  SigmaT1=zeros(nChannels);

if issymmetric(mean(Xs,3)) && issymmetric(mean(Xt,3))
    for i=1:size(Xs0,3)
        SigmaS0=SigmaS0+Xs0(:,:,i);
    end
    for i=1:size(Xs1,3)
        SigmaS1=SigmaS1+Xs1(:,:,i);
    end
    for i=1:size(XtTrain0,3)
        SigmaT0=SigmaT0+XtTrain0(:,:,i);
    end
    for i=1:size(XtTrain1,3)
        SigmaT1=SigmaT1+XtTrain1(:,:,i);
    end
else
    for i=1:size(Xs0,3)
        SigmaS0=SigmaS0+cov(Xs0(:,:,i)');
    end
    for i=1:size(Xs1,3)
        SigmaS1=SigmaS1+cov(Xs1(:,:,i)');
    end
    for i=1:size(XtTrain0,3)
        SigmaT0=SigmaT0+cov(XtTrain0(:,:,i)');
    end
    for i=1:size(XtTrain1,3)
        SigmaT1=SigmaT1+cov(XtTrain1(:,:,i)');
    end
end

Omega0=((1-beta)*SigmaT0+beta*SigmaS0)/((1-beta)*size(XtTrain0,3)+beta*size(Xs0,3));
Omega1=((1-beta)*SigmaT1+beta*SigmaS1)/((1-beta)*size(XtTrain1,3)+beta*size(Xs1,3));
SigmaST0=(1-gamma)*Omega0+gamma*trace(Omega0)*eye(nChannels)/nChannels;
SigmaST1=(1-gamma)*Omega1+gamma*trace(Omega1)*eye(nChannels)/nChannels;
[d,v]=eig(SigmaST1\SigmaST0);
[~,ids]=sort(diag(v),'descend');
W=d(:,ids([1:nFilters end-nFilters+1:end])); 

XTrain=cat(3,Xt(:,:,1:m),Xs);
fTrain=zeros(N+m,2*nFilters);
fTest=zeros(M-m,2*nFilters);
CovXtrain=zeros(2*nFilters,2*nFilters,N+m);
CovXtest=zeros(2*nFilters,2*nFilters,M-m);
for i=1:N+m
    X=W'*XTrain(:,:,i);
    fTrain(i,:)=log10(diag(X*X')/trace(X*X'));
    CovXtrain(:,:,i)=X*X';
end
for i=1:M-m
    X=W'*XtTest(:,:,i);
    fTest(i,:)=log10(diag(X*X')/trace(X*X'));
    CovXtest(:,:,i)=X*X';
end
