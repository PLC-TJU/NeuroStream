function [Zs, Zt, Wt] = MEKT_P(Xs, Xt, Ys, Yt, options)
    % =====================
    % Manifold Embedded Knowledge Transfer [Improved Version] (MEKT-P)
    
    % Author: LC Pan
    % Date: May. 4, 2025
    % [1] Lc Pan, et al. Cross-session motor imagery-electroencephalography 
    % decoding with Riemannian spatial filtering and domain adaptation[J]. 
    % Journal of Biomedical Engineering, 2025, 42(2):272-279. 
    
    % =====================
    % Input: Xs and Xt: source and target features. [特征数*样本数]
    %        Ys and Yt: source labels and target labels.
    %        Parameters: 
    %        d: subspace bases, [5,20],
    %        beta: the parameter for L, default=0.1,
    %        alpha: the parameter for Ps and Pt, [2^(-15),2^(-5)],
    %        rho: the parameter for Q, [5,40],

    % Output: Embeddings Zs, Zt. [特征数*样本数]
    %         Wt: Projection matrix.
    % =====================
    
    if nargin < 5 || isempty(options)
        options = struct();
    end
    if ~isfield(options, 'd'), options.d = 10; end
    if ~isfield(options, 'alpha_s'), options.alpha_s = 0.01; end
    if ~isfield(options, 'alpha_t'), options.alpha_t = 0.01; end
    if ~isfield(options, 'beta'), options.beta = 0.1; end
    if ~isfield(options, 'rho'), options.rho = 20; end

    % Set options
    d = options.d;
    alpha_s = options.alpha_s; 
    alpha_t = options.alpha_t; 
    beta = options.beta;
    rho = options.rho; 

    % Get variable sizes
    [ms,ns] = size(Xs); 
    [mt,nt] = size(Xt);
    class = unique(Ys); 
    C = length(class);

    if ~isequal(ms,mt)
        error('源域和目标域的特征维度不一致')
    end

    % Initialize Ps: source domain discriminability
    Xs_meanTotal = mean(Xs,2);
    Sw = zeros(ms);
    Sb = zeros(ms);
    for i=1:C
        Xsi = Xs(:,Ys==class(i));
        meanClass = mean(Xsi,2);
        Hi = eye(size(Xsi,2))-1/(size(Xsi,2))*ones(size(Xsi,2),size(Xsi,2));
        Sw = Sw + Xsi*Hi*Xsi';
        Sb = Sb + size(Xsi,2)*(meanClass-Xs_meanTotal)*(meanClass-Xs_meanTotal)';
    end
    Ps = [Sw, zeros(ms); zeros(ms), zeros(ms)];
    Vs = [Sb, zeros(ms); zeros(ms), zeros(ms)];
    
    % Initialize Pt: target domain discriminability
    Xt_meanTotal = mean(Xt,2);
    Tw = zeros(mt);
    Tb = zeros(mt);
    for i=1:C
        Xti = Xt(:,Yt==class(i));
        meanClass = mean(Xti,2);
        Hi = eye(size(Xti,2))-1/(size(Xti,2))*ones(size(Xti,2),size(Xti,2));
        Tw = Tw + Xti*Hi*Xti';
        Tb = Tb + size(Xti,2)*(meanClass-Xt_meanTotal)*(meanClass-Xt_meanTotal)';
    end
    Pt = [zeros(mt), zeros(mt); zeros(mt), Tw];
    Vt = [zeros(mt), zeros(mt); zeros(mt), Tb];

    % Initialize L: target data locality
    manifold.k = 10; % default set to 10
    manifold.NeighborMode = 'KNN';
    manifold.Metric='Euclidean';
    manifold.WeightMode = 'HeatKernel';
    W = lapgraph(Xt',manifold);
    D = full(diag(sum(W,2)));
    L = D-W;
    L = [zeros(ms),zeros(mt); zeros(ms),Xt*L*Xt'];

    % Initialize Q: parameter transfer and regularization |B-A|_F+|B|_F
    Q = [eye(ms),-eye(mt);-eye(ms),2*eye(mt)];

    % Initialize S: target components perservation
    Ht = eye(nt)-1/(nt)*ones(nt,nt);
    S = [zeros(ms),zeros(mt); zeros(ms),Xt*Ht*Xt'];

    % Calculate R: joint probability distribution shift
    Ns=1/ns*onehot(Ys,unique(Ys)); 
    Nt=1/nt*onehot(Yt,unique(Ys));
    M=[Ns*Ns',-Ns*Nt';-Nt*Ns',Nt*Nt'];  
    X = [Xs,zeros(size(Xt));zeros(size(Xs)),Xt];
    R = X*M*X';

    % Generalized eigendecompostion
    Emin = alpha_s*Ps + alpha_t*Pt +  beta*L + rho*Q + R; % alpha*P + beta*L + rho*Q + R;
    Emax = Vs + (S + Vt)/2;
    [W,~] = eigs(Emin+10^(-3)*eye(ms+mt), Emax, d, 'smallestabs'); % SM: smallestabs

    % Smallest magnitudes
    A = W(1:ms, :);
    B = W(ms+1:end, :);

    % Embeddings
    Zs = A'*Xs;
    Zt = B'*Xt;

    Wt = B';
end

function y_onehot=onehot(y,class)
    % Encode label to onehot form
    % Input:
    % y: label vector, N*1
    % Output:
    % y_onehot: onehot label matrix, N*C

    nc=length(class);
    num=length(y);
    y_onehot=zeros(num, nc);
    for i=1:num
        idx=nc-find(class==y(i))+1;
        y_onehot(i, idx)=1;
    end
end
