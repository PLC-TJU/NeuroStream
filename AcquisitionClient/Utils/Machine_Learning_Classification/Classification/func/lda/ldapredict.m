function [prediction,Acc]=ldapredict(featureSet,LDAModel,label)
% LDA Predict
% input:
% featureSet: array type, [trial x feature]
% label: array type, [trial x 1]
if nargin< 3
    label=[];
    Acc=[];
end

a0=LDAModel.a0;
a1=LDAModel.a1;
labelInd=LDAModel.labelInd;
prediction=zeros(size(featureSet,1),1);

ind=featureSet*a1+a0;
prediction(ind>=0)=labelInd(1);
prediction(ind<0)=labelInd(2);

if ~isempty(label)
    Acc = sum(prediction == label) / length(label) * 100;
end

end