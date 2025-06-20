%% CTSSP辅助函数
% 计算增强的协方差矩阵（带白化处理）
function [final_covariances, whiten_filter] = p_enhanced_cov(X, t_win, tau, ...
    whiten_filter, estimator, metric)
% 输入:
%   X: EEG数据 (n_channels, n_timepoints, n_trials)
%   t_win: 时间窗口列表，每个元素为[start, end],单位为点数而非时间
%   tau: 延迟值（整数或整数数组）
%   whiten_filter: 白化滤波器（训练模式为空）
%   estimator: 协方差估计方法（默认'cov'）
%   metric: 距离度量（'euclid'或'riemann'，默认'euclid'）

% 输出:
%   final_covariances: 增强的协方差矩阵 (n_channels*K*N, n_channels*K*N, n_trials)
%   whiten_filter: 白化滤波器（元胞数组，每个元素对应一个子窗口）

% 参数默认值处理
if nargin < 6 || isempty(metric), metric = 'euclid'; end
if nargin < 5 || isempty(estimator), estimator = 'cov'; end
if nargin < 4, whiten_filter = []; end

% 获取数据维度
[num_channels, num_time_points, num_samples] = size(X);
is_train = isempty(whiten_filter);
if is_train
    whiten_filter = {};
end

% 处理tau参数
if isempty(tau)
    tau = 0;
end
K = numel(tau);

% 处理时间窗口参数
if isempty(t_win)
    t_win = {[1, num_time_points]};
elseif isnumeric(t_win) && numel(t_win) == 2
    t_win = {t_win(:)'}; % 转换为单元数组
end
N = numel(t_win); % 子窗口数量

% 处理每个时间窗口
enhanced_covs = cell(1, N);
for win_idx = 1:N
    win = t_win{win_idx};
    start_t = win(1);
    end_t = win(2);
    win_len = end_t - start_t + 1;
    
    % 检查窗口有效性
    if end_t > num_time_points
        error('时间窗口超出数据范围');
    end
    
    % 提取子窗口数据 (通道×时间×样本)
    sub_signal = X(:, start_t:end_t, :);
    
    % 应用时延并拼接通道
    delayed_signals = cell(1, K);
    for k = 1:K
        d = tau(k);
        if d == 0
            delayed_signals{k} = sub_signal;
        else
            % 创建延迟信号 (前面补零)
            delayed = zeros(num_channels, win_len, num_samples);
            delayed(:, (d+1):end, :) = sub_signal(:, 1:(end-d), :);
            delayed_signals{k} = delayed;
        end
    end
    
    % 沿通道维度拼接 (通道数×K)
    concat_signal = cat(1, delayed_signals{:}); % (num_channels*K, win_len, num_samples)
    
    % 计算协方差矩阵
    Cov = covariances(concat_signal, estimator); % (num_channels*K, num_channels*K, num_samples)
    
    % 迹归一化
    for s = 1:num_samples
        tr_val = trace(Cov(:, :, s));
        if tr_val < 1e-10
            tr_val = 1e-10;
        end
        Cov(:, :, s) = Cov(:, :, s) / tr_val;
    end
    
    % 白化处理
    if is_train
        % 计算协方差均值
        meanCov = mean_covariances(Cov, metric);
        % 计算白化滤波器 (矩阵逆平方根)
        [U, S] = eig(meanCov);
        W = U * diag(1./sqrt(diag(S))) * U';
        whiten_filter{win_idx} = W;
    else
        W = whiten_filter{win_idx};
    end
    
    % 应用白化滤波器
    whitened_cov = zeros(size(Cov));
    for s = 1:num_samples
        whitened_cov(:, :, s) = W' * Cov(:, :, s) * W;
    end
    enhanced_covs{win_idx} = whitened_cov;
end

% 构建块对角矩阵
total_dim = num_channels * K * N;
final_covariances = zeros(total_dim, total_dim, num_samples);

for s = 1:num_samples
    blocks = cell(1, N);
    for win_idx = 1:N
        blocks{win_idx} = enhanced_covs{win_idx}(:, :, s);
    end
    final_covariances(:, :, s) = blkdiag(blocks{:});
end
end