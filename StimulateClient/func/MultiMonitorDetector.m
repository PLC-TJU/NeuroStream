classdef MultiMonitorDetector
    % MULTIMONITORDETECTOR 使用Java AWT检测多显示器位置和尺寸的工具
    %   该工具考虑了不同显示器的分辨率和缩放设置差异
    
    properties (Access = private)
        javaEnv
        javaDevices
    end
    
    methods
        function obj = MultiMonitorDetector()
            % 构造函数 - 初始化Java图形环境
            obj.javaEnv = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment();
            obj.javaDevices = obj.javaEnv.getScreenDevices();
        end
        
        function num = getMonitorCount(obj)
            % 获取显示器数量
            num = obj.javaDevices.length;
        end
        
        function [positions, sizes, bounds] = getAllMonitorInfo(obj)
            % 获取所有显示器的信息
            %   positions: 显示器左上角坐标 [x, y]
            %   sizes: 显示器尺寸 [width, height] (逻辑像素)
            %   bounds: 显示器边界 [x, y, width, height]
            
            numMonitors = obj.getMonitorCount();
            positions = zeros(numMonitors, 2);
            sizes = zeros(numMonitors, 2);
            bounds = zeros(numMonitors, 4);
            
            for i = 1:numMonitors
                config = obj.javaDevices(i).getDefaultConfiguration();
                boundsRect = config.getBounds();
                
                positions(i, :) = [boundsRect.x, boundsRect.y];
                sizes(i, :) = [boundsRect.width, boundsRect.height];
                bounds(i, :) = [boundsRect.x, boundsRect.y, boundsRect.width, boundsRect.height];
            end
        end
        
        function [xRange, yRange] = getMonitorRanges(obj, monitorIdx)
            % 获取特定显示器的坐标范围
            %   xRange: [x_min, x_max]
            %   yRange: [y_min, y_max]
            
            if monitorIdx < 1 || monitorIdx > obj.getMonitorCount()
                error('无效的显示器索引');
            end
            
            config = obj.javaDevices(monitorIdx).getDefaultConfiguration();
            boundsRect = config.getBounds();
            
            xRange = [boundsRect.x, boundsRect.x + boundsRect.width - 1];
            yRange = [boundsRect.y, boundsRect.y + boundsRect.height - 1];
        end
        
        function displayInfo(obj)
            % 显示所有显示器信息
            
            numMonitors = obj.getMonitorCount();
            fprintf('检测到 %d 个显示器:\n', numMonitors);
            fprintf('==================================================\n');
            
            [positions, sizes, bounds] = obj.getAllMonitorInfo();
            
            for i = 1:numMonitors
                [xRange, yRange] = obj.getMonitorRanges(i);
                
                fprintf('【显示器 %d】\n', i);
                fprintf('  位置坐标: [x=%d, y=%d]\n', positions(i, 1), positions(i, 2));
                fprintf('  尺寸: %d×%d 像素\n', sizes(i, 1), sizes(i, 2));
                fprintf('  X区间: [%d, %d]\n', xRange(1), xRange(2));
                fprintf('  Y区间: [%d, %d]\n', yRange(1), yRange(2));
                fprintf('  边界: [x=%d, y=%d, width=%d, height=%d]\n', ...
                    bounds(i, 1), bounds(i, 2), bounds(i, 3), bounds(i, 4));
                
                % 显示缩放信息
                try
                    % 尝试获取缩放因子（仅Windows）
                    if ispc
                        scaleFactor = obj.getWindowsScalingFactor(i);
                        fprintf('  缩放因子: %.0f%%\n', scaleFactor * 100);
                    end
                catch
                    % 其他平台可能不支持
                end
                
                fprintf('--------------------------------------------------\n');
            end
        end
        
        function plotMonitorLayout(obj)
            % 绘制显示器布局图
            
            figure('Name', '显示器布局', 'NumberTitle', 'off', ...
                'Position', [100, 100, 800, 500], 'Color', 'w');
            ax = axes('Position', [0.05, 0.05, 0.9, 0.9]);
            hold(ax, 'on');
            
            numMonitors = obj.getMonitorCount();
            [~, ~, bounds] = obj.getAllMonitorInfo();
            
            % 计算所有显示器的总范围
            allX = [bounds(:,1); bounds(:,1)+bounds(:,3)];
            allY = [bounds(:,2); bounds(:,2)+bounds(:,4)];
            xlim = [min(allX)-50, max(allX)+50];
            ylim = [min(allY)-50, max(allY)+50];
            
            % 设置坐标轴
            set(ax, 'XLim', xlim, 'YLim', ylim, 'YDir', 'reverse');
            grid(ax, 'on');
            box(ax, 'on');
            title(ax, '多显示器布局图');
            xlabel(ax, 'X 坐标 (像素)');
            ylabel(ax, 'Y 坐标 (像素)');
            
            % 绘制每个显示器
            colors = lines(numMonitors);
            for i = 1:numMonitors
                x = bounds(i, 1);
                y = bounds(i, 2);
                w = bounds(i, 3);
                h = bounds(i, 4);
                
                % 绘制显示器矩形
                rectangle(ax, 'Position', [x, y, w, h], ...
                    'FaceColor', [colors(i,:), 0.3], ...
                    'EdgeColor', colors(i,:), ...
                    'LineWidth', 2);
                
                % 添加标签
                text(ax, x + w/2, y + h/2, sprintf('显示器 %d\n%d×%d', i, w, h), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', ...
                    'FontSize', 12, ...
                    'Color', colors(i,:));
                
                % 绘制坐标原点
                plot(ax, x, y, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
                text(ax, x+15, y+15, sprintf('(%d,%d)', x, y), 'Color', 'r');
            end
            
            % 添加图例
            legend(ax, arrayfun(@(i) sprintf('显示器 %d', i), 1:numMonitors, 'UniformOutput', false), ...
                'Location', 'Best');
            
            hold(ax, 'off');
        end
    end
    
    methods (Access = private)
        function scaleFactor = getWindowsScalingFactor(~, monitorIdx)
            % 获取Windows系统的显示器缩放因子（实验性）
            % 注意：这个方法仅适用于Windows系统
            
            if ~ispc
                error('此功能仅支持Windows系统');
            end
            
            import java.awt.*
            
            % 获取屏幕设备
            ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
            devices = ge.getScreenDevices();
            
            if monitorIdx < 1 || monitorIdx > numel(devices)
                error('无效的显示器索引');
            end
            
            % 获取图形配置
            config = devices(monitorIdx).getDefaultConfiguration();
            
            % 获取缩放因子（在Java 9+中可用）
            try
                transform = config.getDefaultTransform();
                scaleFactor = transform.getScaleX();
            catch
                % 回退方法（可能不准确）
                screenSize = Toolkit.getDefaultToolkit().getScreenSize();
                actualSize = devices(monitorIdx).getDisplayMode().getWidth();
                scaleFactor = actualSize / screenSize.getWidth();
            end
        end
    end
    
    methods (Static)
        function demo()
            % 演示如何使用MultiMonitorDetector类
            
            fprintf('多显示器检测演示\n');
            fprintf('==================================================\n');
            
            % 创建检测器实例
            detector = MultiMonitorDetector();
            
            % 显示基本信息
            fprintf('检测到 %d 个显示器\n\n', detector.getMonitorCount());
            
            % 显示详细信息
            detector.displayInfo();
            
            % 可视化显示器布局
            detector.plotMonitorLayout();
        end
    end
end