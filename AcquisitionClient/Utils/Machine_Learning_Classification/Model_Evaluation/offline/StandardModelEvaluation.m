%% Standard Model Evaluation
function results = StandardModelEvaluation(traindata, trainlabel, testdata, testlabel, alg, fs, freqs, times, chans)
if ~exist('alg','var') || isempty(alg)
    alg = 'CSP';
end
if ~exist('fs','var') || isempty(fs)
    fs=250;
end
if ~exist('freqs','var') || isempty(freqs)
    freqs=[8,30];
end
if ~exist('times','var') || isempty(times)
    times=[];
end
if ~exist('chans','var') || isempty(chans)
    chans=[];
end

classLabels = unique(trainlabel);

% 训练模型
tStart = tic;
model = model_training(traindata, trainlabel, alg, fs, freqs, times, chans);
trainTime = toc(tStart);

% 测试模型
results = ModelEvaluation(model, testdata, testlabel, classLabels);
results.trainTime = trainTime;
results.classLabels = classLabels;
results.algorithm = alg;
results.fs = fs;
results.frequency = freqs;
results.timewindow = times;
results.channel = chans;
results.evaluationType = '标准模型';
end

