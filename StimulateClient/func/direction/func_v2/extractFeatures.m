%% 辅助函数：提取分割、颜色和方向特征
function [f, orientation] = extractFeatures(img)
    % 确保 double 范围 [0,1]
    if ~isfloat(img)
        img = im2double(img);
    end
    H = size(img,1); W = size(img,2);
    % 转 HSV 空间，排除灰度背景
    hsv = rgb2hsv(img);
    sat = hsv(:,:,2); val = hsv(:,:,3);
    maskColor = sat > 0.2 & val > 0.2;        % 彩色区域
    % 形态学去噪：去除小块
    maskClean = bwareaopen(maskColor, 500);
    % 保留最大连通区域（箭头）
    cc = bwconncomp(maskClean);
    if cc.NumObjects==0
        maskArrow = false(H,W);
    else
        areas = cellfun(@numel, cc.PixelIdxList);
        [~, idx] = max(areas);
        maskArrow = false(H,W);
        maskArrow(cc.PixelIdxList{idx}) = true;
    end
    % 提取主色：在箭头区域内
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
    meanR = mean(R(maskArrow),'all');
    meanG = mean(G(maskArrow),'all');
    meanB = mean(B(maskArrow),'all');
    % 计算颜色特征：H、S
    hVals = hsv(:,:,1);
    meanH = mean(hVals(maskArrow),'all');
    meanS = mean(sat(maskArrow),'all');
    % 方向特征：使用 regionprops 获取Orientation
    stats = regionprops(maskArrow, 'Centroid', 'Orientation');
    if isempty(stats)
        cx = W/2; orientation = 0;
    else
        cx = stats(1).Centroid(1);
        orientation = stats(1).Orientation; % -90~+90 相对于水平轴
    end
    x_centroid_norm = cx / W;
    % 特征向量：[质心X归一化, 平均色相, 平均饱和度, 方向]
    f = [x_centroid_norm, meanH, meanS, orientation];
end