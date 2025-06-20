%% Machine_Learning_Classification
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.5.1

% 1.CSP
% 2.FBCSP
% 3.FgMDM
% 4.TSM
% 5.TRCA
% 6.DCPM
% 7.SBLEST
% 8.CTSSP
% 9.ENSEMBLE

function [predlabel, decision_values, testacc] = p_classify(model, testdata, testlabel)
if ~exist('testlabel','var')
    testlabel = [];
end

folderPath = 'func\';
addpath(genpath(folderPath));

% 处理单个样本输入
if ismatrix(testdata)
    testdata = reshape(testdata, size(testdata,1), size(testdata,2), 1);
end

alg = upper(string(model.name));
if strcmp(alg, 'ENSEMBLE')
    % 集成学习分类
    numModels = numel(model.baseModels);
    numSamples = size(testdata, 3);
    testPredictions = zeros(numSamples, numModels);
    testDecisionValues = zeros(numSamples, numModels);
    
    % 获取每个基础模型的预测
    for i = 1:numModels
        [pred_i, dv_i, ~] = p_classify(model.baseModels{i}, testdata, []);
        testPredictions(:, i) = pred_i;
        testDecisionValues(:, i) = dv_i;
    end
    
    % 准备元学习特征
    if model.useDecisionValues
        metaFeatures = testDecisionValues;
    else
        metaFeatures = testPredictions;
    end
    
    % 使用元分类器进行最终预测
    switch upper(model.classifierType)
        case 'LIBSVM'
            [predlabel, ~, decision_values] = libsvmpredict(zeros(size(metaFeatures,1),1), ...
            metaFeatures, model.metaModel, '-q');
        otherwise % LDA/SVM/LGM
            [predlabel, scores] = predict(model.metaModel, metaFeatures);
            decision_values = scores(:,2); % 正类概率
    end
    
    if ~isempty(testlabel)
        testacc = mean(predlabel == testlabel) * 100;
    else
        testacc = [];
    end
else
    % 单个模型分类
    switch alg
        case {'CSP', '1'}
            [predlabel, decision_values, testacc] = csp_classify(model, testdata, testlabel);
        case {'FBCSP', '2'}
            [predlabel, decision_values, testacc] = fbcsp_classify(model, testdata, testlabel);
        case {'FGMDM', '3'}
            [predlabel, decision_values, testacc] = fgmdm_classify(model, testdata, testlabel);
        case {'TSM', '4'}
            [predlabel, decision_values, testacc] = tsm_classify(model, testdata, testlabel);
        case {'TRCA', '5'}
            [predlabel, decision_values, testacc] = trca_classify(model, testdata, testlabel);
        case {'DCPM', '6'}
            [predlabel, decision_values, testacc] = dcpm_classify(model, testdata, testlabel);
        case {'SBLEST', '7'}
            [predlabel, decision_values, testacc] = sblest_classify(model, testdata, testlabel);
        case {'CTSSP', '8'}
            [predlabel, decision_values, testacc] = ctssp_classify(model, testdata, testlabel);
    end
end
end


