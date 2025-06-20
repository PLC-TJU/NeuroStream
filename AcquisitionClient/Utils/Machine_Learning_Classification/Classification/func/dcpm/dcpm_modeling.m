%% DCPM建模（仅用于二分类）
function model=dcpm_modeling(traindata,trainlabel)
Template_0=squeeze(mean(traindata(:,:,trainlabel==1),3))'; % pattern 1
Template_1=squeeze(mean(traindata(:,:,trainlabel==2),3))'; % pattern 2
cov_all=cov( [Template_0,Template_1]);
cov11=cov_all(1:size(Template_0,2),1:size(Template_0,2));
cov22=cov_all(size(Template_0,2)+1:2*size(Template_0,2),size(Template_0,2)+1:2*size(Template_0,2));
cov12=cov_all(1:size(Template_0,2),size(Template_0,2)+1:2*size(Template_0,2));
cov21=cov_all(size(Template_0,2)+1:2*size(Template_0,2),1:size(Template_0,2));
sigma=cov11+cov22-cov12-cov21;%类间

type=unique(trainlabel);
Tartrain=traindata(:,:,trainlabel==type(1));
NTartrain=traindata(:,:,trainlabel==type(2));
for n=1:size(Tartrain,3)
    cov_all2(:,:,n)=cov(squeeze(Tartrain(:,:,n))'-Template_0);
end
cov_0=mean(cov_all2,3);
for n=1:size(NTartrain,3)
    cov_all2(:,:,n)=cov(squeeze(NTartrain(:,:,n))'-Template_1);
end
cov_1=mean(cov_all2,3);
sigma2=cov_0+cov_1;
[U(:,:), D] = eig(inv(sigma2)*sigma);
D=diag(D);
[~,IDX]=sort(D,'descend');
U=U(:,IDX); % DSP filter
U=real(U); %plc 添加

Template_0=Template_0-repmat(mean(Template_0),size(Template_0,1),1);
Template_1=Template_1-repmat(mean(Template_1),size(Template_0,1),1);
tmp_0=Template_0*U;
tmp_1=Template_1*U;

model.name='DCPM';
model.U=U;
model.tmp_1=tmp_1;
model.tmp_0=tmp_0;
model.type=type;

end