% 滤波器组共空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2021.5.1

function model = fbcsp_modeling(traindata, trainlabel, nFilters, classifierType, fs, freqsbands, timewindows, nfea, optimize, timeLimit)

if ~exist('nFilters','var') || isempty(nFilters)
    nFilters=4;
end
if ~exist('classifierType','var') || isempty(classifierType)
    classifierType='SVM';
end
if ~exist('fs','var') || isempty(fs)
    fs=250;
end
if ~exist('freqsbands','var') || isempty(freqsbands)
    freqsbands=[4,8;8,12;12,16;16,20;20,24;24,28;28,32;8,30];
end
if ~exist('timewindows','var') || isempty(timewindows)
    timewindows=[];
end
if ~exist('nfea','var') || isempty(nfea)
    nfea=[];
end
if ~exist('optimize','var') || isempty(optimize)
    optimize = false;
end
if ~exist('timeLimit','var') || isempty(timeLimit)
    timeLimit = 30;
end

% 初始化并行池
% if isempty(gcp('nocreate'))
%     if isempty(getenv('SLURM_JOB_ID')) % 非集群环境
%         parpool('local', feature('numcores'));
%     else
%         parpool('slurm'); 
%     end
% end

nFreqBand = size(freqsbands, 1);
chunkSize = 2 * nFilters;
if ~isempty(timewindows)
    nTimeWin = size(timewindows, 1);
    totalPairs = nTimeWin * nFreqBand;
    
    % 预生成索引映射表（使用线性索引）
    pairIndices = 1:totalPairs;
    [tIdx, fIdx] = ind2sub([nTimeWin, nFreqBand], pairIndices);
    
    % 创建特征存储单元数组（避免直接操作矩阵）
    featureCells = cell(totalPairs, 1);
    filterCells = cell(totalPairs, 1);
    for p = 1:totalPairs%parfor
        currentT = tIdx(p);
        currentF = fIdx(p);
        tw = timewindows(currentT, :);
        fb = freqsbands(currentF, :);
        filteredData = ERPs_Filter(traindata, fb, [], tw, fs);
        [features,~,~,~,W] = CSPfeature(filteredData, trainlabel, [], nFilters);
        featureCells{p} = features;
        filterCells{p} = W;
    end
    
    % 后处理合并特征
    trainFea = nan(size(traindata,3), totalPairs*chunkSize);
    for p = 1:totalPairs
        startCol = (p-1)*chunkSize + 1;
        endCol = p*chunkSize;
        trainFea(:, startCol:endCol) = featureCells{p};
    end
else
    featureCells = cell(nFreqBand, 1);
    filterCells = cell(nFreqBand, 1);
    for f = 1:nFreqBand%parfor
        fb = freqsbands(f, :);
        filteredData = ERPs_Filter(traindata, fb, [], [], fs);
        [features,~,~,~,W] = CSPfeature(filteredData, trainlabel, [], nFilters);
        featureCells{f} = features;
        filterCells{f} = W;
    end
    
    trainFea = nan(size(traindata,3), nFreqBand*chunkSize);
    for f = 1:nFreqBand
        startCol = (f-1)*chunkSize + 1;
        endCol = f*chunkSize;
        trainFea(:, startCol:endCol) = featureCells{f};
    end
end

% 特征选择
if isempty(nfea)
    nfea=max(nFilters,round(0.3*size(trainFea,2)));
end
sort_tmp=all_MuI(trainFea,trainlabel);
index=sort_tmp(1:nfea,2);
trainFeaSelect=trainFea(:,index);

%分类
classifier = train_classifier(trainFeaSelect, trainlabel, classifierType, ...
        optimize, timeLimit);

model.name='FBCSP';
model.fs=fs;
model.W=filterCells;
model.index=index;
model.classifierType=classifierType;
model.classifier=classifier;
model.optimized = optimize;
model.timeLimit = timeLimit;
model.freqsbands=freqsbands;
model.timewindows=timewindows;
model.nFilters=nFilters;
model.type=unique(trainlabel);

end