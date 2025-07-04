%% 使用黎曼距离度量和中位数绝对偏差(MAD)的样本筛选
% 有监督
function [data_out, label_out, idx_remove, thresholds, d] = ...
    SampleFilter2(data, label, metric, lambda)

    % 参数设置
    if nargin < 4, lambda = 8; end    % 默认MAD乘数
    if nargin < 3, metric = 'riemann'; end    % 默认Riemann距离
    
    [~, ~, Ns] = size(data);   % 通道数×时间点数×样本数
    d = nan(Ns, 1);            % 预存储距离
    idx_remove = [];           % 存储所有要移除的样本索引
    thresholds = struct();     % 存储各类别的阈值信息
    
    % ===== 步骤1：计算所有样本的协方差矩阵 =====
    C = covariances(data);
    
    % ===== 步骤2：按类别处理样本 =====
    unique_labels = unique(label);
    for k = 1:length(unique_labels)
        class_label = unique_labels(k);
        class_idx = find(label == class_label);
        class_C = C(:, :, class_idx);
        class_ns = length(class_idx);
        
        fprintf('\n处理类别 %d (样本数: %d)\n', class_label, class_ns);
        
        % 初始化类内变量
        class_d = nan(class_ns, 1);
        class_valid_idx = true(class_ns, 1);
        class_nonSPD_idx = [];
        
        % 检查SPD属性
        for i = 1:class_ns
            Ci = class_C(:, :, i);
            if ~isSPD(Ci)
                class_valid_idx(i) = false;
                class_nonSPD_idx = cat(2, class_nonSPD_idx, i);
                class_d(i) = inf;  % 标记为无穷大
                continue;
            end
        end
        
        % 仅保留SPD样本用于均值计算
        valid_C = class_C(:, :, class_valid_idx);
        if isempty(valid_C)
            error('类别 %d 中没有有效的SPD矩阵', class_label);
        end
        
        % 计算类内黎曼均值
        C_mean = mean_covariances(valid_C, metric);
        
        % 计算类内样本距离
        for i = 1:class_ns
            if class_valid_idx(i)
                class_d(i) = distance(class_C(:, :, i), C_mean, metric);
            end
        end
        
        % 计算类内距离阈值
        valid_d = class_d(class_valid_idx);
        med_dist = median(valid_d);
        MAD = median(abs(valid_d - med_dist));
        class_threshold = med_dist + lambda * MAD;
        
        % 记录全局距离
        d(class_idx) = class_d;
        
        % 识别类内异常样本
        class_outliers = find(class_d > class_threshold);
        class_remove_idx = unique([class_nonSPD_idx, class_outliers(:)']);
        
        % 转换为全局索引
        global_remove_idx = class_idx(class_remove_idx);
        idx_remove = cat(2, idx_remove, global_remove_idx(:)');
        
        % 存储阈值信息
        thresholds(k).label = class_label;
        thresholds(k).threshold = class_threshold;
        thresholds(k).median = med_dist;
        thresholds(k).MAD = MAD;
        thresholds(k).nSPD = numel(class_nonSPD_idx);
        thresholds(k).nOutlier = numel(setdiff(class_outliers, class_nonSPD_idx));
        
        fprintf('  有效SPD样本: %d (%.1f%%)\n', sum(class_valid_idx), 100*mean(class_valid_idx));
        fprintf('  非SPD样本: %d\n', numel(class_nonSPD_idx));
        fprintf('  距离异常样本: %d\n', thresholds(k).nOutlier);
        fprintf('  距离阈值: %.4f (中位数: %.4f, MAD: %.4f)\n', ...
            class_threshold, med_dist, MAD);
    end
    
    % ===== 步骤3：筛选样本 =====
    idx_keep = setdiff(1:Ns, idx_remove);
    data_out = data(:, :, idx_keep);
    label_out = label(idx_keep);
    
    % 输出总结报告
    fprintf('\n===== 样本筛选总结 =====\n');
    fprintf('总样本数: %d\n', Ns);
    fprintf('移除样本数: %d (%.1f%%)\n', numel(idx_remove), 100*numel(idx_remove)/Ns);
    fprintf('保留样本数: %d (%.1f%%)\n', numel(idx_keep), 100*numel(idx_keep)/Ns);
    fprintf('========================\n');

end

% ===== 辅助函数：对称正定矩阵检测 =====
function spd = isSPD(M)
    % 1. 检查对称性 (相对误差<1e-8)
    sym_err = norm(M - M', 'fro') / (norm(M, 'fro') + eps);
    symmetric = sym_err < 1e-8;
    
    % 2. 检查正定性 (最小特征值>0)
    eig_vals = eig(M);
    min_eig = min(eig_vals);
    positive_definite = min_eig > 1e-10 * max(abs(eig_vals));
    
    % 3. 检查数值稳定性
    condition_number = cond(M);
    well_conditioned = condition_number < 1e12;
    
    spd = symmetric && positive_definite && well_conditioned;
end