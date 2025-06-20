function I = ImageCapture2(monitorIdx, x0, y0, w0, h0)
    % ImageCapture   在指定显示器上截屏
    %   I = ImageCapture(monitorIdx, x0, y0, w0, h0)
    %     monitorIdx : 要截屏的显示器编号 (1,2,...)
    %     x0, y0     : 截取区域在该显示器上的左上角坐标 (逻辑像素)
    %     w0, h0     : 截取区域的宽度和高度 (逻辑像素)
    %
    %   返回：
    %     I : 大小为 h0×w0×3 的 uint8 RGB 图像矩阵

    import java.awt.GraphicsEnvironment

    % 1. 获取屏幕设备
    ge      = GraphicsEnvironment.getLocalGraphicsEnvironment();
    devices = ge.getScreenDevices();
    nDev    = numel(devices);
    assert(monitorIdx>=1 && monitorIdx<=nDev, ...
           'monitorIdx 必须在 1 到 %d 之间', nDev);

    % 2. 读取所选屏幕的边界和缩放
    gc     = devices(monitorIdx).getDefaultConfiguration();
    bounds = gc.getBounds();           
    tx     = gc.getDefaultTransform(); 
    sx     = tx.getScaleX();            
    sy     = tx.getScaleY();            

    % 3. 计算全局截屏区域（物理像素）
    gx = bounds.x + round(x0 * sx);
    gy = bounds.y + round(y0 * sy);
    gw = round(w0 * sx);
    gh = round(h0 * sy);

    % 4. 截屏
    robot    = java.awt.Robot();
    rect     = java.awt.Rectangle(gx, gy, gw, gh);
    bufImage = robot.createScreenCapture(rect);

    % 5. 转换为 MATLAB 图像
    % 获取 ARGB 整数数组（Java int[]）
    argbInts = bufImage.getRGB(0, 0, gw, gh, [], 0, gw);
    % 转成 uint32 向量
    pix = typecast(argbInts, 'uint32');

    % 分离 R、G、B 三个 8 位通道
    R = bitand(bitshift(pix, -16), uint32(255));   % 取 bits 16–23
    G = bitand(bitshift(pix, -8),  uint32(255));   % 取 bits 8–15
    B = bitand(pix,           uint32(255));        % 取 bits 0–7

    % 重塑并拼接
    R = reshape(uint8(R), [gw, gh])';
    G = reshape(uint8(G), [gw, gh])';
    B = reshape(uint8(B), [gw, gh])';
    I = cat(3, R, G, B);
end
