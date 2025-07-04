%% 使用黎曼距离度量和中位数绝对偏差(MAD)的样本筛选
% 无监督
function [data_out, label_out, idx_remove, threshold, d, nonSPD_idx] = ...
    SampleFilter(data, label, metric, lambda)

    % 参数设置
    if nargin < 4, lambda = 8; end    % 默认MAD乘数
    if nargin < 3, metric = 'riemann'; end    % 默认Riemann距离
    
    [~, ~, Ns] = size(data);    % 通道数×时间点数×样本数 
    d = nan(Ns, 1);             % 预存储距离 (非SPD样本设为NaN)
    valid_idx = true(Ns, 1);    % 初始化为所有样本有效
    nonSPD_idx = [];            % 存储非SPD样本索引
    
    % ===== 步骤1：SPD检测和协方差计算 =====
    % 计算所有样本的协方差矩阵
    C = covariances(data);
    
    % 检查每个协方差矩阵的SPD属性
    for i = 1:Ns
        Ci = C(:, :, i);
        
        % 增强SPD检测：检查对称性、正定性和数值稳定性
        if ~isSPD(Ci)
            valid_idx(i) = false;
            nonSPD_idx = cat(2, nonSPD_idx, i);
            d(i) = inf;  % 标记为无穷大距离，便于后续处理
        end
    end
    
    % 仅保留SPD样本
    C_valid = C(:, :, valid_idx);
    if isempty(C_valid)
        error('没有找到有效的SPD矩阵。数据集可能存在问题。');
    end
    
    % ===== 步骤2：计算黎曼几何均值 =====
    C_mean = mean_covariances(C_valid, metric);
    
    % ===== 步骤3：计算黎曼距离 =====
    % 仅对有效SPD样本计算距离
    valid_samples = find(valid_idx);
    for i = 1:length(valid_samples)
        idx = valid_samples(i);
        d(idx) = distance(C(:, :, idx), C_mean, metric);
    end
    
    % ===== 步骤4：基于MAD计算阈值 =====
    % 仅使用有效SPD样本的距离计算阈值
    valid_d = d(valid_idx);
    med_dist = median(valid_d);
    MAD = median(abs(valid_d - med_dist));
    threshold = med_dist + lambda * MAD;
    
    % ===== 步骤5：筛选样本 =====
    % 标记非SPD和距离超限样本
    distance_outliers = find(d > threshold);
    idx_remove = unique([nonSPD_idx(:)', distance_outliers(:)']);
    idx_keep = setdiff(1:Ns, idx_remove);
    
    % 输出结果
    data_out = data(:, :, idx_keep);
    label_out = label(idx_keep);
    
    % ===== 提供诊断信息 =====
    fprintf('样本筛选报告:\n');
    fprintf('总样本数: %d\n', Ns);
    fprintf('非SPD样本数: %d (%.1f%%)\n', numel(nonSPD_idx), 100*numel(nonSPD_idx)/Ns);
    fprintf('距离异常样本数: %d (%.1f%%)\n', numel(setdiff(distance_outliers, nonSPD_idx)), ...
            100*numel(setdiff(distance_outliers, nonSPD_idx))/Ns);
    fprintf('保留样本数: %d (%.1f%%)\n', numel(idx_keep), 100*numel(idx_keep)/Ns);
    fprintf('距离阈值: %.4f (λ = %.1f)\n', threshold, lambda);

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
    
    % 4. 检查正对角元素
    diag_positive = all(diag(M) > 0);
    
    spd = symmetric && positive_definite && diag_positive && well_conditioned;
end