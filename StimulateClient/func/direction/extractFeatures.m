%% 辅助函数：提取分割、颜色和方向特征
function [f, angleDeg] = extractFeatures(img)
    % 输入RGB图像，输出7维特征 + 精确方位角（-180~180）
    img = im2double(img);
    [H, W, ~] = size(img);

    % 1. HSV 分割及最大连通区
    hsv = rgb2hsv(img);
    sat = hsv(:,:,2);
    val = hsv(:,:,3);
    mask = sat > 0.2 & val > 0.2;
    mask = bwareaopen(mask, 500);
    cc = bwconncomp(mask);
    if cc.NumObjects > 0
        [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
        m = false(H, W);
        m(cc.PixelIdxList{idx}) = true;
        mask = m;
    end

    % 2. 主轴分析（PCA）分离端点
    [y, x] = find(mask);
    coords = double([x, y]);      % 确保数值
    % 仅提取第一主分量得到方向向量
    coeff = pca(coords, 'NumComponents', 1);  % 返回2x1向量
    proj = coords * coeff;                    % Mx1
    [~, i1] = min(proj);
    [~, i2] = max(proj);
    end1 = coords(i1, :);
    end2 = coords(i2, :);

    % 3. 曲率分析确定 head 端
    bdy = bwboundaries(mask);
    pts = bdy{1};  % Mx2
    k1 = localCurvature(pts, end1);
    k2 = localCurvature(pts, end2);
    if k1 > k2
        head = end1;
        tail = end2;
    else
        head = end2;
        tail = end1;
    end

    % 4. 方向角：从质心指向 head
    c = mean(coords, 1);  % 1x2
    v = head - c;        % 1x2
    angleDeg = atan2d(-(v(2)), v(1));  % -180~180

    % 5. 位置特征
    xCent = c(1) / W;
    yCent = c(2) / H;

    % 6. 颜色特征
    hue = hsv(:,:,1);
    maskIdx = mask;
    meanH = mean(hue(maskIdx));
    stdH  = std(hue(maskIdx));

    % 7. 曲率比
    curvR = k1 / (k2 + eps);

    % 8. 颜色-角度耦合
    hcpl = meanH * (abs(angleDeg) / 180);

    % 特征向量
    f = [xCent, yCent, meanH, stdH, angleDeg/180, curvR, hcpl];
end

%% 辅助：计算某点处的局部曲率
function k = localCurvature(boundaryPts, pt)
    % boundaryPts: Mx2, pt: 1x2
    M = size(boundaryPts, 1);
    % 批量计算点差
    dif = boundaryPts - repmat(pt, M, 1);
    d2 = sum(dif.^2, 2);
    [~, idx] = min(d2);
    w = 5;
    N = M;
    prevIdx = mod(idx - w - 1, N) + 1;
    nextIdx = mod(idx + w - 1, N) + 1;
    p_prev = boundaryPts(prevIdx, :);
    p     = boundaryPts(idx, :);
    p_next= boundaryPts(nextIdx, :);
    a = p_prev - p;
    b = p_next - p;
    c = p_next - p_prev;
    k = abs(det([a; b])) / (norm(a) * norm(b) * norm(c) + eps);
end