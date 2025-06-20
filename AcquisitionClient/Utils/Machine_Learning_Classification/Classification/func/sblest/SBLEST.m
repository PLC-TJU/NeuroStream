function [W, alpha, V, Wh] = SBLEST(X, Y)
% Syntax:
%  [W, alpha, V, Wh] = SBLEST(X, Y, K, tau)

% --- Inputs ---
% Y         : True label vector. [M, 1].
% X         : M trials of C (channel) x T (time) EEG signals. [C, T, M].
% K         : Order of FIR filter.
% tau       : Time delay parameter.

% --- Outputs ---
% W         : Estimated low-rank weight matrix. [K*C, K*C].
% alpha     : Classifier weights. [L, 1].
% V         : Spatio-temporal filter matrix. [K*C, L].
%             Each column of V represents a spatio-temporal filter.
% Wh        : Whitening matrix for enhancing covariance matrices (required 
%             for prediction on test set). [(K*C)^2, (K*C)^2].

% Compute enhanced covariace matrices and whitening matrix
[R_train, Wh] = Enhanced_cov(X);

%% Check properties of R
[M, D_R] = size(R_train); % M: # of samples; D_R: dimention of vec(R_m)
KC = round(sqrt(D_R));
Loss_old = 1e12;
threshold = 0.05; %

% Check if R is symmetric
for c = 1:M
    row_cov = reshape(R_train(c,:), KC, KC);
    if ( norm(row_cov - row_cov','fro') > 1e-4 )
        disp('ERROR: Measurement row does not form symmetric matrix');
        return
    end
end

%% Initializations
U = zeros(KC, KC); % estimated low-rank matrix W initialized to be Zeros
Psi = eye(KC); % covariance matrix of Gaussian prior distribution is initialized to be unit diagonal matrix
lambda = 1;% variance of the additive noise set to 1

%% Optimization loop
for i = 1:5000
    %% Update U
    RPR = zeros(M, M);
    B = zeros(KC^2, M);
    for c = 1:KC
        start = (c-1)*KC + 1; stop = start + KC - 1;
        Temp = Psi*R_train(:, start:stop)';
        B(start:stop,:) = Temp;
        RPR =  RPR + R_train(:, start:stop)*Temp;
    end
    
    Sigma_y = RPR + lambda*eye(M);
    uc = B*(Sigma_y\Y ); % maximum a posterior estimation of uc
    Uc = reshape(uc, KC, KC);
    U = (Uc + Uc')/2; 
    u = U(:);
    %% Update Phi (dual variable of Psi)
    Phi = cell(1, KC);
    SR = Sigma_y\R_train;
    for c = 1:KC
        start = (c-1)*KC + 1; stop = start + KC - 1;
        Phi{1,c} = Psi - Psi * ( R_train(:,start:stop)' * SR(:,start:stop) ) * Psi;
    end
    
    %% Update Psi
    PHI = 0;
    UU = 0;
    for c = 1:KC
        PHI = PHI +  Phi{1, c};
        UU = UU + U(:,c) * U(:,c)';
    end
    Psi = ((UU + UU')/2 + (PHI + PHI')/2 )/KC; % make sure Psi is symmetric
    
    %% Update theta (dual variable of lambda) and lambda
    theta = 0;
    for c = 1:KC
        start = (c-1)*KC + 1; stop = start + KC - 1;
        theta = theta +trace(Phi{1,c}* R_train(:,start:stop)'*R_train(:,start:stop)) ;
    end
    lambda = (sum((Y-R_train*u).^2) + theta)/M;
    
    %% Convergence check
    logdet_Sigma_y =  calculate_log_det(Sigma_y);
    Loss = Y'*Sigma_y^(-1)*Y + logdet_Sigma_y;
    delta_loss = abs(Loss_old-Loss)/abs( Loss_old);
    if (delta_loss < 2e-4)
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
V = V_all(:,index); alpha = alpha_all(index);
end