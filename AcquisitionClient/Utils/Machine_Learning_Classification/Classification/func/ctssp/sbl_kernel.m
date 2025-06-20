% 改进自SBLEST
function [W, alpha, V, features] = sbl_kernel(R, Y)
% 稀疏贝叶斯学习
% 输入
% R         : 特征矩阵（样本数×特征维度）.
% Y         : 标签向量（样本数×1）.

% 输出
% W         : 低秩投影矩阵. 
% alpha     : 特征权重向量. 
% V         : 特征向量矩阵（每一列为一个时-频-空滤波器）
% features  : 优化的特征矩阵（样本数×特征维度）.

%% Check properties of R
[M, D_R] = size(R); 
Dim = round(sqrt(D_R));
Loss_old = 1e12;
threshold = 0.05; 

% Check if R is symmetric
for c = 1:M
    row_cov = reshape(R(c,:), Dim, Dim);
    if ( norm(row_cov - row_cov','fro') > 1e-4 )
        disp('ERROR: Measurement row does not form symmetric matrix');
        return
    end
end

%% Initializations
U = zeros(Dim, Dim); % estimated low-rank matrix W initialized to be Zeros
Psi = eye(Dim); % covariance matrix of Gaussian prior distribution is initialized to be unit diagonal matrix
lambda = 1;% variance of the additive noise set to 1

%% Optimization loop
for i = 1:5000
    %% Update U
    RPR = zeros(M, M);
    B = zeros(Dim^2, M);
    for c = 1:Dim
        start = (c-1)*Dim + 1; stop = start + Dim - 1;
        Temp = Psi*R(:, start:stop)';
        B(start:stop,:) = Temp;
        RPR =  RPR + R(:, start:stop)*Temp;
    end
    
    Sigma_y = RPR + lambda*eye(M);
    uc = B*(Sigma_y\Y ); % maximum a posterior estimation of uc
    Uc = reshape(uc, Dim, Dim);
    U = (Uc + Uc')/2; 
    u = U(:);
    %% Update Phi (dual variable of Psi)
    Phi = cell(1, Dim);
    SR = Sigma_y\R;
    for c = 1:Dim
        start = (c-1)*Dim + 1; stop = start + Dim - 1;
        Phi{1,c} = Psi - Psi * ( R(:,start:stop)' * SR(:,start:stop) ) * Psi;
    end
    
    %% Update Psi
    PHI = 0;
    UU = 0;
    for c = 1:Dim
        PHI = PHI +  Phi{1, c};
        UU = UU + U(:,c) * U(:,c)';
    end
    Psi = ((UU + UU')/2 + (PHI + PHI')/2 )/Dim; % make sure Psi is symmetric
    
    %% Update theta (dual variable of lambda) and lambda
    theta = 0;
    for c = 1:Dim
        start = (c-1)*Dim + 1; stop = start + Dim - 1;
        theta = theta +trace(Phi{1,c}* R(:,start:stop)'*R(:,start:stop)) ;
    end
    lambda = (sum((Y-R*u).^2) + theta)/M;
    
    %% Convergence check
    logdet_Sigma_y =  calculate_log_det(Sigma_y);
    Loss = Y'*Sigma_y^(-1)*Y + logdet_Sigma_y;
    delta_loss = abs(Loss_old-Loss)/abs( Loss_old);
    if (delta_loss < 1e-4)
%         disp('EXIT: Change in loss below threshold');
        break;
    end
    Loss_old = Loss;
%     if (~rem(i,100))
%         disp(['Iterations: ', num2str(i),  '  lambda: ', num2str(lambda),'  Loss: ', num2str(Loss), '  Delta_Loss: ', num2str(delta_loss)]);
%     end
end
%% Eigendecomposition of W
W = U;
[~, D, V_all] = eig(W); % each column of V represents a spatio-temporal filter
alpha_all = diag(D); % classifier weights

%% Determine spatio-temporal filters V and classifier weights alpha
d = abs(diag(D)); d_max = max(d);
w_norm = d/d_max; % normalize eigenvalues of W by the maximum eigenvalue
index = find(w_norm > threshold); % indices of selected V according to a pre-defined threshold,.e.g., 0.05
V = V_all(:,index); 
alpha = alpha_all(index);

%% 计算所有样本的特征投影
features = zeros(size(R,1), size(V,2));
for i = 1:size(R,1)
    % 将样本特征重塑为矩阵
    sample_mat = reshape(R(i,:), sqrt(size(R,2)), []);
    features(i,:) = diag(V'*sample_mat*V);
end

end