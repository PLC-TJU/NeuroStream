% 滤波器组共空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2021.5.1

function [prediction,decision_values,TestAcc] = fbcsp_classify(model, testdata, testlabel)
if ~exist('testlabel','var') || isempty(testlabel)
    testlabel=[];
end

fs=model.fs;
filterCells=model.W;
index=model.index;
classifierType=model.classifierType;
classifier=model.classifier;
freqsbands=model.freqsbands;
timewindows=model.timewindows;
nFilters=model.nFilters;

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
    for p = 1:totalPairs
        currentT = tIdx(p);
        currentF = fIdx(p);
        tw = timewindows(currentT, :);
        fb = freqsbands(currentF, :);
        filteredData = ERPs_Filter(testdata, fb, [], tw, fs);

        W = filterCells{p};
        testcov=zeros(size(W,2),size(W,2),size(testdata,3));
        testfea=zeros(size(testdata,3),size(W,2));
        for i=1:size(filteredData,3)
            testcov(:,:,i)=W'*filteredData(:,:,i)*filteredData(:,:,i)'*W;
            testfea(i,:)=log10(diag(testcov(:,:,i))/trace(testcov(:,:,i)));
        end
        featureCells{p} = testfea;
    end
    
    % 后处理合并特征
    testFea = nan(size(testdata,3), totalPairs*chunkSize);
    for p = 1:totalPairs
        startCol = (p-1)*chunkSize + 1;
        endCol = p*chunkSize;
        testFea(:, startCol:endCol) = featureCells{p};
    end
else
    featureCells = cell(nFreqBand, 1);
    for f = 1:nFreqBand
        fb = freqsbands(f, :);
        filteredData = ERPs_Filter(testdata, fb, [], [], fs);

        W = filterCells{f};
        testcov=zeros(size(W,2),size(W,2),size(testdata,3));
        testfea=zeros(size(testdata,3),size(W,2));
        for i=1:size(filteredData,3)
            testcov(:,:,i)=W'*filteredData(:,:,i)*filteredData(:,:,i)'*W;
            testfea(i,:)=log10(diag(testcov(:,:,i))/trace(testcov(:,:,i)));
        end
        featureCells{f} = testfea;
    end
    
    testFea = nan(size(testdata,3), nFreqBand*chunkSize);
    for f = 1:nFreqBand
        startCol = (f-1)*chunkSize + 1;
        endCol = f*chunkSize;
        testFea(:, startCol:endCol) = featureCells{f};
    end
end

% 特征选择
testFeaSelect=testFea(:,index);

%分类
switch upper(classifierType)
    case 'LIBSVM'
        [prediction, ~, decision_values] = svmpredict(zeros(size(testFeaSelect,1),1), ...
            testFeaSelect, classifier, '-q');
    otherwise % 'SVM', 'LDA', 'LOGISTIC'
        [prediction, scores] = predict(classifier, testFeaSelect);
        decision_values = scores(:,2); % 正类概率
end

if ~isempty(testlabel)
    TestAcc=mean(prediction==testlabel)*100;
else
    TestAcc=[];
end

end