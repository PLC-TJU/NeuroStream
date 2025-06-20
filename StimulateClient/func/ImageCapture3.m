function I = ImageCapture3(monitorIdx, x0, y0, w0, h0)
% ImageCapture   截取指定显示器上逻辑坐标区间的屏幕图像
%
%   I = ImageCapture(monitorIdx, x0, y0, w0, h0)
%     monitorIdx : 显示器编号（1,2,3,…），对应 get(0,'MonitorPositions') 的行号
%     x0, y0     : 区域左上角在该显示器逻辑坐标系下的 (x,y)，以像素为单位
%     w0, h0     : 区域宽度和高度（逻辑像素）
%
%   返回：
%     I : 大小 h0×w0×3 的 uint8 RGB 图像

    %--- 1. 读取 MATLAB 逻辑像素下的各显示器位置和尺寸 ---%
    mons = get(0, 'MonitorPositions');
    nMon = size(mons,1);
    assert(monitorIdx>=1 && monitorIdx<=nMon, ...
           'monitorIdx 必须在 1 到 %d 之间', nMon);
    % mons(i,:) = [lx, ly, lw, lh]，其中 (lx,ly) 是逻辑坐标系下左上角，相对于 (1,1)

    %--- 2. 读取 Java AWT 提供的物理边界和缩放因子 ---%
    import java.awt.GraphicsEnvironment
    ge      = GraphicsEnvironment.getLocalGraphicsEnvironment();
    devices = ge.getScreenDevices();
    assert(numel(devices)==nMon, ...
           'MATLAB monitor count 与 Java AWT 返回的屏幕数不一致');
    gc     = devices(monitorIdx).getDefaultConfiguration();
    bounds = gc.getBounds();           % [px, py, pw, ph] 物理坐标／尺寸
    tx     = gc.getDefaultTransform(); % 缩放变换
    sx     = tx.getScaleX();
    sy     = tx.getScaleY();

    %--- 3. 计算截屏区域在物理像素下的全局坐标 ---%
    % 将逻辑偏移 (mons(m,1),mons(m,2)) 映射到物理坐标：
    phys_x0_of_monitor = bounds.x + round((mons(monitorIdx,1)-1) * sx);
    phys_y0_of_monitor = bounds.y + round((mons(monitorIdx,2)-1) * sy);
    % 再加上区域内部的逻辑偏移 (x0,y0)，并乘以缩放：
    gx = phys_x0_of_monitor + round(x0 * sx);
    gy = phys_y0_of_monitor + round(y0 * sy);
    gw = round(w0 * sx);
    gh = round(h0 * sy);

    %--- 4. 调用 Java Robot 截屏 ---%
    robot    = java.awt.Robot();
    rect     = java.awt.Rectangle(gx, gy, gw, gh);
    bufImage = robot.createScreenCapture(rect);

    %--- 5. 将 BufferedImage 转为 MATLAB RGB 图像 ---%
    argbInts = bufImage.getRGB(0, 0, gw, gh, [], 0, gw);
    pix      = typecast(argbInts, 'uint32');
    R = bitand(bitshift(pix, -16), uint32(255));
    G = bitand(bitshift(pix, -8),  uint32(255));
    B = bitand(           pix,      uint32(255));
    R = reshape(uint8(R), [gw, gh])';
    G = reshape(uint8(G), [gw, gh])';
    B = reshape(uint8(B), [gw, gh])';
    I = cat(3, R, G, B);
end
