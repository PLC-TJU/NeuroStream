function R = get_vector(Cov)
% 协方差矩阵的特征转换与向量化
% 功能：对协方差矩阵进行白化、对数变换和向量化操作

% 输入：
%   Cov - 协方差矩阵（通道数×通道数×样本数）

% 输出：
%   R - 特征向量矩阵（样本数×特征维度）
%       特征维度 = 通道数^2（全向量化）

[channels, ~, num_samples] = size(Cov);
feature_dim = channels * channels;
R = zeros(num_samples, feature_dim);

% 处理每个样本
for s = 1:num_samples
    cov_mat = Cov(:, :, s);
       
    % 矩阵对数变换
    log_cov = logm(cov_mat);
    
    % 向量化
    R(s, :) = log_cov(:)';
end
end