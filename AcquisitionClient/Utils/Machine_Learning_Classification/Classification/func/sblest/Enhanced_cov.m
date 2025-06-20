function [R, Wh] = Enhanced_cov(Xnew, Wh)
% Compute enhanced covariace matrices of train set

% Inputs    :
% X         : M trials of C (channel) x T (time) EEG signals. [C, T, M].
% K         : Order of FIR filter
% tau       : Time delay parameter

% Outputs   :
% R         : Enhanced covariace matrices. [M,(K*C)^2*(K*C)^2 ]
% Wh        : Whitening matrix. [K*C, K*C].

% Compute Whitening matrix
% Cov = covariances(Xnew,'ntrace');
Cov = covariances(Xnew);

if ~exist('Wh','var') || isempty(Wh)
    Wh = mean_covariances(Cov);
end

% Whitening, logarithm transform, and Vectorization
R = zeros(size(Xnew,3),size(Xnew,1)^2);
for m = 1:size(Xnew,3)
    temp_cov = Wh^(-1/2)*Cov(:,:,m)*Wh^(-1/2);% whitening
    Cov_whiten  = (temp_cov + temp_cov')/2;
    R_m = logm(squeeze(Cov_whiten)); % logarithm transform
    R_m = R_m(:); % column-wise vectorization
    R(m,:) = R_m';
end
end