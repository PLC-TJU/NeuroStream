%% 用于迁移学习模型评估
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

function results = evaluate_transfer_model(sdata, slabel, tdata, tlabel, alg, freqs, timeset)
    % 初始化结果结构
    results = struct();
    results.algorithm = alg;
    results.frequency = freqs;
    results.timewindow = timeset;
    results.evaluationType = '迁移模型';
    results.sourceSamples = size(sdata, 3);
    results.targetSamples = size(tdata, 3);

    % 检查所评估的算法
    if strcmpi(alg,'Stacking') || strcmpi(alg,'RSFDA')
        useParallel = false;
        repeats = 1; %重复测试次数
    else
        useParallel = true;
        repeats = 3; %重复测试次数
    end

    % 仅保留前两类标签
    stype=unique(slabel);
    ttype=unique(tlabel);
    if ~isequal(stype,ttype); error('源域与目标域的样本标签不一致');end
    sdata=sdata(:,:,slabel<=stype(2));
    slabel=slabel(slabel<=stype(2));
    tdata=tdata(:,:,tlabel<=ttype(2));
    tlabel=tlabel(tlabel<=ttype(2));

    % 获取类别信息
    classLabels = unique([slabel(:); tlabel(:)]);
    results.classLabels = classLabels;
    numClasses = 2;
    
    % 设置交叉验证参数 (目标域数据)
    k = 5; % 5折交叉验证
    totalFolds = k * repeats;
    cv=cell(repeats,1);
    rng('default');
    for r = 1:repeats
        cv{r} = cvpartition(tlabel, 'KFold', k);
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
        accuracy = zeros(k, 1);
        precision = zeros(k, numClasses);
        recall = zeros(k, numClasses);
        f1 = zeros(k, numClasses);
        rocCurves = cell(k, 1);
        auc = zeros(k, 1);
        trainTime = zeros(k, 1);
        allPredictions = [];
        allLabels = [];
        
        if useParallel
            % 主评估循环(并行计算)
            parfor fold = 1:totalFolds
                % 计算当前重复和折叠
                repeatNum = ceil(fold / k);
                foldNum = mod(fold - 1, k) + 1;

                % 划分训练测试集
                trainIdx = cv{repeatNum}.training(foldNum); %#ok
                testIdx = cv{repeatNum}.test(foldNum);

                % 训练迁移模型
                tStart = tic;
                model = tlmodel_training(...
                    sdata, slabel, ...
                    tdata(:,:,trainIdx), tlabel(trainIdx), ...
                    alg, freqs, times); %#ok
                trainTime(fold) = toc(tStart);

                % 测试模型
                [predictions, dv, acc] = online_classify(...
                    model, tdata(:,:,testIdx), tlabel(testIdx));

                % 存储结果
                accuracy(fold) = acc;
                allPredictions = [allPredictions; predictions(:)];
                allLabels = [allLabels; tlabel(testIdx)];

                % 计算其他指标
                [precision(fold,:), recall(fold,:), f1(fold,:)] = ...
                    calculate_class_metrics(predictions, tlabel(testIdx), classLabels);

                % 计算AUC (二分类)
                if numClasses == 2
                    try
                        x_vals = linspace(0, 1, 1000); % 使用1000个点
                        [x, y, ~, auc(fold)] = perfcurve(...
                            tlabel(testIdx), dv, classLabels(2), ...
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
            for fold = 1:totalFolds
                % 计算当前重复和折叠
                repeatNum = ceil(fold / k);
                foldNum = mod(fold - 1, k) + 1;

                % 划分训练测试集
                trainIdx = cv{repeatNum}.training(foldNum); 
                testIdx = cv{repeatNum}.test(foldNum);

                % 训练迁移模型
                tStart = tic;
                model = tlmodel_training(...
                    sdata, slabel, ...
                    tdata(:,:,trainIdx), tlabel(trainIdx), ...
                    alg, freqs, times); 
                trainTime(fold) = toc(tStart);

                % 测试模型
                [predictions, dv, acc] = online_classify(...
                    model, tdata(:,:,testIdx), tlabel(testIdx));

                % 存储结果
                accuracy(fold) = acc;
                allPredictions = [allPredictions; predictions(:)];%#ok
                allLabels = [allLabels; tlabel(testIdx)];%#ok

                % 计算其他指标
                [precision(fold,:), recall(fold,:), f1(fold,:)] = ...
                    calculate_class_metrics(predictions, tlabel(testIdx), classLabels);

                % 计算AUC (二分类)
                if numClasses == 2
                    try
                        x_vals = linspace(0, 1, 1000); % 使用1000个点
                        [x, y, ~, auc(fold)] = perfcurve(...
                            tlabel(testIdx), dv, classLabels(2), ...
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