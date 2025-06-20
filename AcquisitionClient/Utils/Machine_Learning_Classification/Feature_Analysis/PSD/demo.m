% 生成测试信号
% 参数设置
fs = 1000; % 采样率
T = 1; % 信号时长（秒）
t = 0:1/fs:T-1/fs; % 时间向量
C = 3; % 通道数
M = 10; % 样本数

% 生成三维数据：3个通道，每个通道包含10个样本（50Hz正弦波+白噪声）
data = zeros(C, length(t), M);
for ch = 1:C
    for m = 1:M
        data(ch, :, m) = 2*sin(2*pi*50*t) + randn(size(t)); % 50Hz信号+高斯噪声
    end
end

%%
% 计算PSD
[PSD, f] = p_psd2(data, fs, 512, [1, 100], 'periodogram', hanning(length(t)));

%%
% 可视化验证
figure;
for ch = 1:C
    subplot(C, 1, ch);
    plot(f, PSD(:, ch));
    xlabel('频率 (Hz)');
    ylabel('PSD (dB/Hz)');
    title(['通道 ', num2str(ch), ' 的功率谱密度']);
    grid on;
    xlim([0, 100]);
end

