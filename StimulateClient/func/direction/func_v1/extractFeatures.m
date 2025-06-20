%% 辅助函数：特征提取
function f = extractFeatures(img)
    % img: HxWx3 uint8 或 double
    % 特征: [x_centroid_norm, meanR, meanG, meanB]
    if ~isfloat(img)
        img = double(img);
    end
    H = size(img,1);
    W = size(img,2);
    % 平均颜色
    meanR = mean(img(:,:,1),'all') / 255;
    meanG = mean(img(:,:,2),'all') / 255;
    meanB = mean(img(:,:,3),'all') / 255;
    % 颜色掩码: 红色或绿色显著区域
    maskR = img(:,:,1) > img(:,:,2) & img(:,:,1) > img(:,:,3);
    maskG = img(:,:,2) > img(:,:,1) & img(:,:,2) > img(:,:,3);
    mask = maskR | maskG;
    % 计算质心
    stats = regionprops(mask, 'Centroid');
    if isempty(stats)
        cx = W/2;
    else
        c = cat(1, stats.Centroid);
        cx = mean(c(:,1));
    end
    x_centroid_norm = cx / W;
    % 返回特征向量
    f = [x_centroid_norm, meanR, meanG, meanB];
end