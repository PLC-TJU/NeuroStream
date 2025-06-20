% 共时-频-空间模式
% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.5.1
% Lincong Pan, et al. CTSSP: A Temporal-Spectral-Spatio Joint Optimization 
% Algorithm for Motor Imagery EEG Decoding. TechRxiv. April 10, 2025.

function model = ctssp_modeling(traindata, trainlabel, t_win, tau, ...
    classifierType, optimize, timeLimit)
if ~exist('t_win','var') 
    t_win = [];
end
if ~exist('tau','var')
    tau = [0, 3];
end
if ~exist('classifierType','var') || isempty(classifierType)
    classifierType = 'SIGN'; % 默认值：'SIGN'
end
if ~exist('optimize','var') || isempty(optimize)
    optimize = false;
end
if ~exist('timeLimit','var') || isempty(timeLimit)
    timeLimit = 30;
end

type = unique(trainlabel);

% 特征提取
[Covtrain, Wh] = p_enhanced_cov(traindata, t_win, tau);
Rtrain = get_vector(Covtrain);

% 稀疏贝叶斯学习
label = zeros(length(trainlabel),1);
label(trainlabel==type(1)) = -1;
label(trainlabel==type(2)) =  1;
[W, ~, V, fea] = sbl_kernel(Rtrain, label);

% 分类
switch upper(classifierType)
    case {'SVM','LDA','LOGISTIC'}
        classifier = train_classifier(fea, trainlabel, ...
            classifierType, optimize, timeLimit);
        model.V = V;
        model.classifier=classifier;
        model.optimized = optimize;
        model.timeLimit = timeLimit;
end

model.name='CTSSP';
model.t_win=t_win;
model.tau=tau;
model.type=type;
model.W=W;
model.Wh=Wh;
model.classifierType=classifierType;

end