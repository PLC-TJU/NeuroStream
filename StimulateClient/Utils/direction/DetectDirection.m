function [prediction,sample] = DetectDirection(position)
persistent model

if nargin<1 || isempty(position)
    %position=[1977,-300,291,241];  %办公室调试
    position=[-1095,780,291,241];   %107实验室
end
if ~exist('model','var') || isempty(model)
    temp = load('modeldata.mat','model');
    model = temp.model;
end

sample=ImageCapture(position);
[prediction, ~, ~] = classifyArrowImage(sample, model);
end