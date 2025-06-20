%% 适用于迁移学习的stacking集成学习
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

function model = stacking_tlmodeling(Xs, Ys, Xt, Yt, algs, fs, times, freqs, chans, varargin)
% STACKING_TRAIN 训练一个基于多时间窗、多频带、多通道和多算法的Stacking集成模型
% 使用并行计算加速子模型训练

% 输入:
%   Xs,Xt: 源域、目标域EEG数据 (通道×时间点×样本数)
%   Ys,Yt: 源域、目标域样本标签 (样本数×1)
%   algs: 算法列表 (元胞数组, 如{'CSP','FgMDM','TSM','SBLEST','CTTSP','TRCA','DCPM'})
%   fs: 采样率 (Hz)
%   times: 时间窗列表 (M×2数组, 单位:秒)
%   freqs: 频带列表 (N×2数组, 单位:Hz)
%   chans: 通道元组 (元胞数组, 每个元素是通道索引列表)
%   varargin: 可选参数
% 输出:
%   model: 训练好的Stacking模型

% 默认设置
if ~exist('algs','var') || isempty(algs)
    algs ={'CSP','FgMDM','TSM'};
end
if ~exist('fs','var') || isempty(fs)
    fs =250;
end
if ~exist('freqs','var') || isempty(freqs)
    freqs=[8,13;13,18;18,26;23,30;8,30];
end
if ~exist('times','var') || isempty(times) || isscalar(times)
    if isscalar(times)
        maxtime=times;
    else
        maxtime=size(Xs,2)/fs;
    end
    if maxtime>=4
        times=[0,2;1,3;2,4;0,3;1,4;0,4];
    elseif maxtime>=3
        times=[0,2;1,3;0,3];
    elseif maxtime>=2
        times=[0,1.5;0.5,2;0,2];
    else
        times=[0,maxtime];
    end
end
if ~iscell(algs)
    algs={algs};
    warning('algs参数必须是cell格式');
end
if ~exist('chans','var') || isempty(chans)
    chans={1:size(Xs,1)};
end
if ~iscell(chans)
    chans={chans};
    warning('chans参数必须是cell格式');
end

% 解析可选参数
p = inputParser;
addParameter(p, 'UseRsf', true, @islogical);
addParameter(p, 'Metric', 'euclid', @ischar);
addParameter(p, 'ClassifierType', 'LOGISTIC', @ischar);
addParameter(p, 'UseDecisionValues', true, @islogical);
addParameter(p, 'Optimize', false, @islogical);
addParameter(p, 'OptimizeTimeLimit', 30, @isnumeric);
addParameter(p, 'Verbose', false, @islogical);
addParameter(p, 'UseParallel', true, @islogical); % 添加并行计算选项
parse(p, varargin{:});

% 初始化模型结构
model = struct();
model.name = 'Stacking_TL';
model.algs = algs;
model.fs = fs;
model.times = times;
model.freqs = freqs;
model.chans = chans;
model.useRsf = p.Results.UseRsf;
model.metric = p.Results.Metric;
model.baseModels = {};
model.configs = {};
model.useDV = p.Results.UseDecisionValues;
model.classifierType = p.Results.ClassifierType;
model.optimize = p.Results.Optimize;
model.timeLimit = p.Results.OptimizeTimeLimit;
model.verbose = p.Results.Verbose;
useParallel = p.Results.UseParallel;

% 计算样本数和子模型数量
nTrials = size(Xs, 3) + size(Xt, 3);
nTimes = max(size(times, 1),1);
nFreqs = size(freqs, 1);
nChans = max(numel(chans),1);
nAlgs = numel(algs);
nSubModels = nTimes * nFreqs * nChans * nAlgs;

verbose = model.verbose;
if verbose
    fprintf('开始训练Stacking模型\n');
    fprintf('配置组合数: %d\n', nSubModels);
    if useParallel
        fprintf('使用并行计算加速\n');
    end
end

% 创建所有配置组合
allConfigs = cell(nSubModels, 1);
idx = 1;
for t = 1:nTimes
    time_win = times(t, :);
    for f = 1:nFreqs
        freq_band = freqs(f, :);
        for c = 1:nChans
            chan_idx = chans{c};
            for a = 1:nAlgs
                alg = algs{a};
                allConfigs{idx} = struct(...
                    'time_win', time_win, ...
                    'freq_band', freq_band, ...
                    'chan_idx', chan_idx, ...
                    'alg', alg, ...
                    'index', idx);
                idx = idx + 1;
            end
        end
    end
end

% 预分配子模型和配置存储
baseModels = cell(nSubModels, 1);
metaFeatures = zeros(nTrials, nSubModels);

% 根据是否使用并行计算选择循环类型
useDV = model.useDV;
useRsf = model.useRsf;
metric = model.metric;
if useParallel
    % 确保并行池已开启
    if isempty(gcp('nocreate'))
        parpool('local');
    end
    
    % 并行处理所有配置
    parfor i = 1:nSubModels%parfor
        config = allConfigs{i};
        
        if verbose
            fprintf('训练子模型 %d/%d: 时间窗[%.1f-%.1f]s, ', i, nSubModels, config.time_win(1), config.time_win(2));
            fprintf('频带[%.1f-%.1f]Hz, ', config.freq_band(1), config.freq_band(2));
            fprintf('通道%d个, ', numel(config.chan_idx));
            fprintf('算法: %s\n', config.alg);
        end
        
        % 数据预处理：时频滤波和通道选择
        fXs = ERPs_Filter(Xs, config.freq_band, config.chan_idx, config.time_win, fs);
        fXt = ERPs_Filter(Xt, config.freq_band, config.chan_idx, config.time_win, fs);

        % 数据对齐 
        scov = covariances(fXs,'scm');
        mscov = mean_covariances(scov, metric);
        Ms = mscov^-0.5;
        aXs = zeros(size(fXs));
        for s=1:size(fXs,3)
            aXs(:,:,s) = Ms*fXs(:,:,s);
        end
        
        tcov = covariances(fXt,'scm');
        mtcov = mean_covariances(tcov, metric);
        Mt = mtcov^-0.5;
        aXt = zeros(size(fXt));
        for s=1:size(fXt,3)
            aXt(:,:,s) = Mt*fXt(:,:,s);
        end
        
        % 样本混合
        fX=cat(3,aXs,aXt);
        Y=cat(1,Ys,Yt);

        % 空间滤波
        if useRsf
            [Wrsf, fX]=RSF(fX, Y);
        else
            Wrsf = [];
        end
        
        % 训练子模型
        subModel = p_modeling(fX, Y, config.alg, varargin{:});%#ok
        subModel.Wrct = Mt;
        subModel.Wrsf = Wrsf;
        
        % 在训练集上测试子模型（得到预测标签和决策值）
        [pred, dv, ~] = p_classify(subModel, fX, Y);
        
        % 保存结果
        baseModels{i} = subModel;
        
        % 收集元特征
        if useDV
            metaFeatures(:, i) = dv;
        else
            metaFeatures(:, i) = pred;
        end
    end
else
    % 串行处理所有配置
    for i = 1:nSubModels
        config = allConfigs{i};
        
        if verbose
            fprintf('训练子模型 %d/%d: 时间窗[%.1f-%.1f]s, ', i, nSubModels, config.time_win(1), config.time_win(2));
            fprintf('频带[%.1f-%.1f]Hz, ', config.freq_band(1), config.freq_band(2));
            fprintf('通道%d个, ', numel(config.chan_idx));
            fprintf('算法: %s\n', config.alg);
        end
        
        % 数据预处理：时频滤波和通道选择
        fXs = ERPs_Filter(Xs, config.freq_band, config.chan_idx, config.time_win, fs);
        fXt = ERPs_Filter(Xt, config.freq_band, config.chan_idx, config.time_win, fs);

        % 数据对齐 
        scov = covariances(fXs,'scm');
        mscov = mean_covariances(scov, metric);
        Ms = mscov^-0.5;
        aXs = zeros(size(fXs));
        for s=1:size(fXs,3)
            aXs(:,:,s) = Ms*fXs(:,:,s);
        end
        
        tcov = covariances(fXt,'scm');
        mtcov = mean_covariances(tcov, metric);
        Mt = mtcov^-0.5;
        aXt = zeros(size(fXt));
        for s=1:size(fXt,3)
            aXt(:,:,s) = Mt*fXt(:,:,s);
        end
        
        % 样本混合
        fX=cat(3, aXs, aXt);
        Y=cat(1, Ys(:), Yt(:));

        % 空间滤波
        if useRsf
            [Wrsf, fX]=RSF(fX, Y);
        else
            Wrsf = [];
        end
        
        % 训练子模型
        subModel = p_modeling(fX, Y, config.alg, varargin{:});
        subModel.Wrsf = Wrsf;
        
        % 在训练集上测试子模型（得到预测标签和决策值）
        [pred, dv, ~] = p_classify(subModel, fX, Y);
        
        % 保存结果
        baseModels{i} = subModel;
        
        % 收集元特征
        if useDV
            metaFeatures(:, i) = dv;
        else
            metaFeatures(:, i) = pred;
        end
    end
end

% 将临时结果转移到模型结构
model.baseModels = baseModels;
model.configs = allConfigs;

% 训练元分类器
if verbose
    fprintf('训练元分类器 (%s)...\n', model.classifierType);
end

Y = cat(1, Ys(:), Yt(:));
model.metaModel = train_classifier(metaFeatures, Y, model.classifierType, ...
        model.optimize, model.timeLimit);

if verbose
    fprintf('Stacking模型训练完成\n');
end
end