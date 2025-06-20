function Xnew = Augmented_data(X, K, tau)
% Inputs    :
% X         : M trials of C (channel) x T (time) EEG signals. [C, T, M].
% K         : Order of FIR filter
% tau       : Time delay parameter

% Outputs   :
% Xnew      : M trials of K*C (channel) x T (time) EEG signals. [K*C, T, M].

if ismatrix(X)
    X = reshape(X, size(X,1), size(X,2), 1);
end

%  Initializaiton
[C, T, M] = size(X);
KC = K*C; % [KC, KC]: dimension of augmented covariance matrix

Xnew =zeros(KC,T,M);
for m = 1:M
    X_m = X(:,:,m);
    X_m_hat = [];

    % Generate augumented EEG data
    for k = 1 : K
        n_delay = (k-1)*tau;
        if n_delay == 0
            X_order_k = X_m;
        else
            X_order_k(:,1:n_delay) = 0;
            X_order_k(:,n_delay+1:T) = X_m(:,1:T-n_delay);
        end
        X_m_hat = cat(1, X_m_hat, X_order_k);
    end
    Xnew(:,:,m) = X_m_hat;
end
end