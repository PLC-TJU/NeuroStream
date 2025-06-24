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

function Model = p_modeling(traindata, trainlabel, alg, varargin)
% 扩展参数解析系统
p = inputParser;
p.KeepUnmatched = true; % 允许未匹配参数传递给子函数

% 添加通用参数
addParameter(p, 'ClassifierType', 'LOGISTIC', @ischar);%'LOGISTIC'
addParameter(p, 'Optimize', false, @islogical); %false
addParameter(p, 'OptimizeTimeLimit', 30, @isnumeric);
addParameter(p, 'UseDecisionValues', true, @islogical);

% 算法特定参数
addParameter(p, 'metric', 'riemann', @ischar);
addParameter(p, 'nFilters', 4, @isnumeric);
addParameter(p, 'freqsbands', [4,8;8,12;12,16;16,20;20,24;24,28;28,32;8,30], @isnumeric);
addParameter(p, 'sblest_tau', 1, @isnumeric);
addParameter(p, 'ctssp_tau', [0, 3], @isnumeric);
addParameter(p, 'ctssp_t_win', {}, @iscell);
addParameter(p, 'alg_list', {}, @iscell);
addParameter(p, 'fs', 250, @isnumeric);

% 解析输入参数
parse(p, varargin{:});
params = p.Results;

% 获取参数值
classifierType = params.ClassifierType;
useDV = params.UseDecisionValues;
optimize = params.Optimize;
timeLimit = params.OptimizeTimeLimit;
fs = params.fs;

% 检查是否为集成学习
if iscell(alg) || (isnumeric(alg) && numel(alg) > 1)
    % 处理数字输入
    if isnumeric(alg)
        alg = arrayfun(@num2str, alg, 'UniformOutput', false);
    end
    
    numModels = numel(alg);
    baseModels = cell(1, numModels);
    trainPredictions = zeros(size(traindata, 3), numModels);
    trainDecisionValues = zeros(size(traindata, 3), numModels);
    
    % 创建子参数结构（移除集成相关参数）
    subParams = rmfield(params, 'alg_list');
    subParams = struct2nvpairs(subParams);
    
    % 训练每个基础模型
    for i = 1:numModels
        baseModels{i} = p_modeling(traindata, trainlabel, alg{i}, subParams{:});
        
        % 获取训练集预测结果
        [pred, dv, ~] = p_classify(baseModels{i}, traindata, trainlabel);
        trainPredictions(:, i) = pred;
        trainDecisionValues(:, i) = dv;
    end
    
    % 准备元学习特征
    if useDV
        metaFeatures = trainDecisionValues;
    else
        metaFeatures = trainPredictions;
    end
    
    % 训练元分类器
    metaModel = train_classifier(metaFeatures, trainlabel, classifierType, ...
        optimize, timeLimit);
    
    % 构建集成模型
    Model = struct();
    Model.name = 'Ensemble';
    Model.baseModels = baseModels;
    Model.metaModel = metaModel;
    Model.algList = alg;
    Model.useDecisionValues = useDV;
    Model.classifierType = classifierType;
    Model.optimized = optimize;
    Model.timeLimit = timeLimit;
else
    % 处理单个算法
    alg_str = upper(string(alg));
    
    switch alg_str
        case {'CSP', '1'}
            Model = csp_modeling(traindata, trainlabel, ...
                params.nFilters, classifierType, ...
                optimize, timeLimit);
            
        case {'FBCSP', '2'}
            Model = fbcsp_modeling(traindata, trainlabel, ...
                params.nFilters, classifierType, ...
                fs, params.freqsbands, [], [], ...
                optimize, timeLimit);
            
        case {'FGMDM', '3'}
            Model = fgmdm_modeling(traindata, trainlabel, params.metric);
            
        case {'TSM', '4'}
            Model = tsm_modeling(traindata, trainlabel, params.metric, classifierType, ...
                optimize, timeLimit);
            
        case {'TRCA', '5'}
            Model = trca_modeling(traindata, trainlabel);
            
        case {'DCPM', '6'}
            Model = dcpm_modeling(traindata, trainlabel);
            
        case {'SBLEST', '7'}
            Model = sblest_modeling(traindata, trainlabel, ...
                params.sblest_tau);
            
        case {'CTSSP', '8'}
            % 处理时间窗参数
            t_win = params.ctssp_t_win;
            if isempty(t_win)
                t_win = {[1, size(traindata,2)], [0.5*fs+1, size(traindata,2)]};
            end
            
            Model = ctssp_modeling(traindata, trainlabel, ...
                t_win, params.ctssp_tau, classifierType, ...
                optimize, timeLimit);
            
        case {'ENSEMBLE', '9'}
            % 处理算法集合
            alg_list = params.alg_list;
            if isempty(alg_list)
                alg_list = {'CSP', 'FBCSP', 'FGMDM', 'TSM', 'CTSSP'};
            end
            
            % 递归调用，传递所有参数
            Model = p_modeling(traindata, trainlabel, alg_list, varargin{:});
            
        otherwise
            error('未知算法: %s', alg);
    end
    
end
end

% 辅助函数：结构体转名称-值对
function nvp = struct2nvpairs(s)
fields = fieldnames(s);
values = struct2cell(s);
nvp = [fields, values]';
nvp = nvp(:)';
end