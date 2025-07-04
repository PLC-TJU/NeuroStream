%% Tansfer Model Evaluation
function results = TransferModelEvaluation(sdata, slabel, tdata, tlabel, testdata, testlabel, alg, fs, freqs, times, chans)
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

classLabels = unique(slabel);

% 训练模型
tStart = tic;
model = tlmodel_training(...
                    sdata, slabel, ...
                    tdata, tlabel, ...
                    alg, fs, freqs, times, chans); 
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
results.evaluationType = '迁移模型';
end

