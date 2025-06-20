%% 用于标准模型评估
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

function results = evaluate_standard_model(data, label, alg, freqs, timeset)
    % 初始化结果结构
    results = struct();
    results.algorithm = alg;
    results.frequency = freqs;
    results.timewindow = timeset;
    results.evaluationType = '标准模型';
    results.totalSamples = size(data, 3);

    % 检查所评估的算法
    if strcmpi(alg,'Stacking')
        useParallel = false;
        repeats = 1; %重复测试次数
    else
        useParallel = true;
        repeats = 3; %重复测试次数
    end
    
    % 仅保留前两类标签
    type=unique(label);
    data=data(:,:,label<=type(2));
    label=label(label<=type(2));

    % 获取类别信息
    classLabels = unique(label);
    results.classLabels = classLabels;
    numClasses = 2;
    
    % 设置交叉验证参数
    k = 5; % 交叉验证折数
    totalFolds = k * repeats;
    cv=cell(repeats,1);
    rng('default');
    for r = 1:repeats
        cv{r} = cvpartition(label, 'KFold', k);
    end
    
    % 预分配时间点结构
    timePointTemplate = struct(...
        'feedbackTime', [], ...
        'accuracy', [], ...
        'precision', [], ...
        'recall', [], ...
        'f1', [], ...
        'auc', [], ...
        'trainTime', [], ...
        'rocCurves', {{}}, ...
        'confusionMatrix', [], ...
        'allPredictions', [], ...
        'allLabels', [], ...
        'summary', struct() ...
        );
    results.timePoints = repmat(timePointTemplate, size(timeset,1), 1);
    
    % 对每个反馈时间点进行评估
    for tIdx = 1:size(timeset,1)
        times = timeset(tIdx,:);
        timePoint = times(2);
        
        % 进度更新
        fprintf('评估第 %.1fs 时间点的分类模型...\n', timePoint);
        
        % 初始化当前时间点的存储
        accuracy = zeros(totalFolds, 1);
        precision = zeros(totalFolds, numClasses);
        recall = zeros(totalFolds, numClasses);
        f1 = zeros(totalFolds, numClasses);
        rocCurves = cell(totalFolds, 1);
        auc = zeros(totalFolds, 1);
        trainTime = zeros(totalFolds, 1);
        allPredictions = [];
        allLabels = [];
        
        if useParallel
            % 主评估循环(并行计算)
            parfor fold = 1:totalFolds%parfor
                % 计算当前重复和折叠
                repeatNum = ceil(fold / k);
                foldNum = mod(fold - 1, k) + 1;
    
                % 划分训练测试集
                trainIdx = cv{repeatNum}.training(foldNum);%#ok
                testIdx = cv{repeatNum}.test(foldNum);
                
                % 训练模型
                tStart = tic;
                model = model_training(...
                    data(:,:,trainIdx), label(trainIdx), alg, freqs, times); %#ok
                trainTime(fold) = toc(tStart);
                
                % 测试模型
                [predictions, dv, acc] = online_classify(...
                    model, data(:,:,testIdx), label(testIdx));
                
                % 存储结果
                accuracy(fold) = acc;
                allPredictions = [allPredictions; predictions(:)];
                allLabels = [allLabels; label(testIdx)];
                
                % 计算其他指标
                [precision(fold,:), recall(fold,:), f1(fold,:)] = ...
                    calculate_class_metrics(predictions, label(testIdx), classLabels);
                
                % 计算AUC (二分类)
                if numClasses == 2
                    try
                        x_vals = linspace(0, 1, 1000); % 使用1000个点
                        [x, y, ~, auc(fold)] = perfcurve(...
                            label(testIdx), dv, classLabels(2), ...
                            'XVals', x_vals, 'UseNearest', 'on');
    
                        % 确保有足够的数据点
                        if numel(x) < 2 || numel(y) < 2
                            auc(fold) = NaN;
                            rocCurves{fold} = [];
                        else
                            rocCurves{fold} = struct('x', x(:)', 'y', y(:)');
                        end
                    catch
                        auc(fold) = NaN;
                        rocCurves{fold} = [];
                    end
                else
                    auc(fold) = NaN; % 多分类时不计算AUC
                    rocCurves{fold} = [];
                end
            end
        else
            % 主评估循环(单核计算)
            for fold = 1:totalFolds%parfor
                % 计算当前重复和折叠
                repeatNum = ceil(fold / k);
                foldNum = mod(fold - 1, k) + 1;
    
                % 划分训练测试集
                trainIdx = cv{repeatNum}.training(foldNum);
                testIdx = cv{repeatNum}.test(foldNum);
                
                % 训练模型
                tStart = tic;
                model = model_training(...
                    data(:,:,trainIdx), label(trainIdx), alg, freqs, times); 
                trainTime(fold) = toc(tStart);
                
                % 测试模型
                [predictions, dv, acc] = online_classify(...
                    model, data(:,:,testIdx), label(testIdx));
                
                % 存储结果
                accuracy(fold) = acc;
                allPredictions = [allPredictions; predictions(:)];%#ok
                allLabels = [allLabels; label(testIdx)];%#ok
                
                % 计算其他指标
                [precision(fold,:), recall(fold,:), f1(fold,:)] = ...
                    calculate_class_metrics(predictions, label(testIdx), classLabels);
                
                % 计算AUC (二分类)
                if numClasses == 2
                    try
                        x_vals = linspace(0, 1, 1000); % 使用1000个点
                        [x, y, ~, auc(fold)] = perfcurve(...
                            label(testIdx), dv, classLabels(2), ...
                            'XVals', x_vals, 'UseNearest', 'on');
    
                        % 确保有足够的数据点
                        if numel(x) < 2 || numel(y) < 2
                            auc(fold) = NaN;
                            rocCurves{fold} = [];
                        else
                            rocCurves{fold} = struct('x', x(:)', 'y', y(:)');
                        end
                    catch
                        auc(fold) = NaN;
                        rocCurves{fold} = [];
                    end
                else
                    auc(fold) = NaN; % 多分类时不计算AUC
                    rocCurves{fold} = [];
                end
            end
        end
        
        % 计算当前时间点的混淆矩阵
        timeConfMat = confusionmat(allLabels, allPredictions);
        
        % 存储当前时间点结果 (直接赋值到预分配结构体)
        results.timePoints(tIdx).feedbackTime = timePoint;
        results.timePoints(tIdx).accuracy = accuracy;
        results.timePoints(tIdx).precision = precision;
        results.timePoints(tIdx).recall = recall;
        results.timePoints(tIdx).f1 = f1;
        results.timePoints(tIdx).auc = auc;
        results.timePoints(tIdx).trainTime = trainTime;
        results.timePoints(tIdx).rocCurves = rocCurves;
        results.timePoints(tIdx).confusionMatrix = timeConfMat;
        results.timePoints(tIdx).allPredictions = allPredictions;
        results.timePoints(tIdx).allLabels = allLabels;

        % 计算当前时间点的汇总指标
        results.timePoints(tIdx).summary = calculate_timepoint_summary(results.timePoints(tIdx));
    end
end