% LC.Pan <panlincong@tju.edu.cn>
% Data: 2025.6.2

function showEvaluationResults(results)
    % 创建结果展示窗口
    fig = uifigure('Name', ['模型评估结果: ',results.algorithm], ...
        'Position', [100 100 1000 700], ... % 增大窗口尺寸
        'Icon', 'app_icon_3.png');
    
    % 创建选项卡组
    tabGroup = uitabgroup(fig, 'Position', [20 20 960 660]);
    
    % 1. 时间点汇总选项卡
    summaryTab = uitab(tabGroup, 'Title', '时间点汇总');
    
    % 创建时间点汇总表格 (居中对齐)
    summaryData = cell(numel(results.timePoints), 9);
    for tIdx = 1:numel(results.timePoints)
        tp = results.timePoints(tIdx);
        sum = tp.summary;
        
        summaryData{tIdx, 1} = tp.feedbackTime;
        summaryData{tIdx, 2} = sprintf('%.2f ± %.2f', sum.accuracy.mean, sum.accuracy.std);
        summaryData{tIdx, 3} = sprintf('%.2f ± %.2f', sum.macroPrecision.mean, sum.macroPrecision.std);
        summaryData{tIdx, 4} = sprintf('%.2f ± %.2f', sum.macroRecall.mean, sum.macroRecall.std);
        summaryData{tIdx, 5} = sprintf('%.2f ± %.2f', sum.macroF1.mean, sum.macroF1.std);
        
        if ~isnan(sum.auc.mean)
            summaryData{tIdx, 6} = sprintf('%.3f ± %.3f', sum.auc.mean, sum.auc.std);
        else
            summaryData{tIdx, 6} = 'N/A';
        end
        
        if ~isnan(sum.kappa)
            summaryData{tIdx, 7} = sprintf('%.3f', sum.kappa);
        else
            summaryData{tIdx, 7} = 'N/A';
        end
        
        summaryData{tIdx, 8} = sprintf('%.2f ± %.2f', sum.gmean.mean, sum.gmean.std);
        summaryData{tIdx, 9} = sprintf('%.3f ± %.3f', sum.trainTime.mean, sum.trainTime.std);
    end
    
    % 创建表格并设置居中对齐
    colNames = {'时间点(s)', '准确率(%)', '精确率(%)', '召回率(%)', 'F1值(%)', ...
                'AUC', 'Kappa', 'G-Mean(%)', '训练时间(s)'};
    
    % 设置列格式为居中对齐
    colFormat = repmat({'char'}, 1, 9); % 所有列都使用字符格式
    colEditable = false(1, 9); % 所有列不可编辑
    
    uitable(summaryTab, 'Data', summaryData, ...
        'Position', [20 50 920 580], ...
        'ColumnName', colNames, ...
        'ColumnFormat', colFormat, ...
        'ColumnEditable', colEditable, ...
        'RowName', [], ...
        'FontName', 'Consolas', ... % 等宽字体更美观
        'FontSize', 13.5);
    
    % 2. 详细结果选项卡 (按时间点组织)
    detailTab = uitab(tabGroup, 'Title', '详细结果');
    
    % 创建子选项卡组用于不同时间点
    timeTabGroup = uitabgroup(detailTab, 'Position', [10 10 940 600]);
    
    for tIdx = 1:numel(results.timePoints)
        tp = results.timePoints(tIdx);
        timePoint = tp.feedbackTime;
        timeTab = uitab(timeTabGroup, 'Title', sprintf('%.1fs', timePoint));
        
        % 创建当前时间点的详细结果表格 (居中对齐)
        detailData = cell(numel(tp.accuracy), 7);
        for fold = 1:numel(tp.accuracy)
            detailData{fold, 1} = fold;
            detailData{fold, 2} = sprintf('%.2f', tp.accuracy(fold));
            detailData{fold, 3} = sprintf('%.2f', mean(tp.precision(fold, :))*100);
            detailData{fold, 4} = sprintf('%.2f', mean(tp.recall(fold, :))*100);
            detailData{fold, 5} = sprintf('%.2f', mean(tp.f1(fold, :))*100);
            
            if ~isnan(tp.auc(fold))
                detailData{fold, 6} = sprintf('%.3f', tp.auc(fold));
            else
                detailData{fold, 6} = 'N/A';
            end
            
            detailData{fold, 7} = sprintf('%.3f', tp.trainTime(fold));
        end
        
        colNames = {'折叠', '准确率(%)', '精确率(%)', '召回率(%)', 'F1值(%)', 'AUC', '训练时间(s)'};
        % colFormat = {'numeric', 'char', 'char', 'char', 'char', 'char', 'char'};
        colFormat = repmat({'char'}, 1, 7); % 所有列都使用字符格式
        colEditable = [false, false, false, false, false, false, false];
        
        uitable(timeTab, 'Data', detailData, ...
            'Position', [20 50 900 500], ...
            'ColumnName', colNames, ...
            'ColumnFormat', colFormat, ...
            'ColumnEditable', colEditable, ...
            'RowName', [], ...
            'FontName', 'Consolas', ...
            'FontSize', 13.5);
    end
    
    % 3. 混淆矩阵选项卡 (修复显示问题)
    matrixTab = uitab(tabGroup, 'Title', '混淆矩阵');
    matrixTabGroup = uitabgroup(matrixTab, 'Position', [10 10 940 600]);
    
    for tIdx = 1:numel(results.timePoints)
        tp = results.timePoints(tIdx);
        if isfield(tp, 'confusionMatrix') && ~isempty(tp.confusionMatrix)
            timePoint = tp.feedbackTime;
            timeTab = uitab(matrixTabGroup, 'Title', sprintf('%.1fs', timePoint));
            
            % === 修复方法：将混淆矩阵保存为图像再显示 ===
            % 创建临时 figure 绘制混淆矩阵
            fig = figure('Visible', 'off');
            c = confusionchart(fig, tp.confusionMatrix, results.classLabels);
            c.Title = sprintf('%.1fs 时间点混淆矩阵', timePoint);
            c.ColumnSummary = 'column-normalized';
            c.RowSummary = 'row-normalized';
            
            % 保存为临时图像文件
            imgFile = sprintf('confusion_temp_%d.png', randi(10000));
            saveas(fig, imgFile);
            close(fig);
            
            % 在 App 中显示图像
            ax = uiaxes(timeTab, 'Position', [50 50 800 500]);
            imshow(imread(imgFile), 'Parent', ax);
            title(ax, sprintf('%.1fs 时间点混淆矩阵', timePoint));
            
            % 删除临时文件
            delete(imgFile);
        end
    end
    
    % 4. ROC曲线选项卡 (按时间点组织)
    if any(arrayfun(@(x) isfield(x.summary, 'includeROC') && x.summary.includeROC, results.timePoints))
        rocTab = uitab(tabGroup, 'Title', 'ROC曲线');
        rocTabGroup = uitabgroup(rocTab, 'Position', [10 10 940 600]);
        
        for tIdx = 1:numel(results.timePoints)
            tp = results.timePoints(tIdx);
            if isfield(tp.summary, 'includeROC') && tp.summary.includeROC
                timePoint = tp.feedbackTime;
                timeTab = uitab(rocTabGroup, 'Title', sprintf('%.1fs', timePoint));
                ax = uiaxes(timeTab, 'Position', [50 50 800 500]);
                
                hold(ax, 'on');
                             
                % 收集所有折叠的ROC数据
                allX = {};
                allY = {};
                for fold = 1:numel(tp.rocCurves)
                    curve = tp.rocCurves{fold};
                    if ~isempty(curve) && ~isnan(tp.auc(fold)) && ...
                       numel(curve.x) > 1 && numel(curve.y) > 1
                        allX{end+1} = curve.x;
                        allY{end+1} = curve.y;
                        
                        % 绘制每个折叠的ROC曲线
                        plot(ax, curve.x, curve.y, ...
                            'DisplayName', ['fold-',num2str(fold)], ...
                            'Color', [0.7 0.7 0.7], ...
                            'LineWidth', 0.5);
                    end
                end
                
                % 计算并绘制平均ROC曲线
                if ~isempty(allX)
                    [meanX, meanY] = compute_mean_roc(allX, allY);
                    
                    if ~isempty(meanX)
                        % 计算当前时间点的平均AUC
                        validAUC = tp.auc(~isnan(tp.auc));
                        meanAUC = mean(validAUC);
                        
                        plot(ax, meanX, meanY, 'b', 'LineWidth', 2, ...
                            'DisplayName', sprintf('平均 (AUC=%.3f)', meanAUC));
                    end
                end
                
                plot(ax, [0 1], [0 1], 'k--', 'HandleVisibility', 'off');
                xlabel(ax, 'False Positive Rate');
                ylabel(ax, 'True Positive Rate');
                title(ax, sprintf('%.1fs 时间点ROC曲线', timePoint));
                
                if ~isempty(allX)
                    legend(ax, 'Location', 'southeast');
                end
                
                hold(ax, 'off');
            end
        end
    end
end

% 辅助函数：计算平均ROC曲线 (保持不变)
function [meanX, meanY] = compute_mean_roc(allX, allY)
    % 确保所有曲线都是行向量
    allX = cellfun(@(x) x(:)', allX, 'UniformOutput', false);
    allY = cellfun(@(y) y(:)', allY, 'UniformOutput', false);
    
    % 过滤掉空曲线和无效曲线
    validIdx = cellfun(@(x,y) numel(x) > 1 && numel(y) > 1, allX, allY);
    allX = allX(validIdx);
    allY = allY(validIdx);
    
    if isempty(allX)
        meanX = [];
        meanY = [];
        return;
    end
    
    % 确定最小点数（至少2个点）
    minPoints = max(2, min(cellfun(@numel, allX)));
    
    % 创建公共X轴
    commonX = linspace(0, 1, minPoints);
    
    % 处理单曲线情况
    if numel(allX) == 1
        meanX = allX{1};
        meanY = allY{1};
        return;
    end
    
    % 对每条曲线进行插值
    interpY = zeros(numel(allX), minPoints);
    for i = 1:numel(allX)
        x = allX{i};
        y = allY{i};
        
        % 确保x值唯一且单调
        [x_unique, idx] = unique(x);
        y_unique = y(idx);
        
        % 处理边界情况
        if numel(x_unique) < 2
            % 复制点以创建有效插值
            x_unique = [0, 1];
            y_unique = [0, 1];
        end
        
        % 线性插值
        interpY(i, :) = interp1(x_unique, y_unique, commonX, 'linear', 'extrap');
    end
    
    % 计算平均Y值
    meanY = mean(interpY, 1);
    meanX = commonX;
end