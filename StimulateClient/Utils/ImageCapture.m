function I=ImageCapture(Abscissa,ordinate,width,height)
abscissa=Abscissa(1);
if nargin == 1
    ordinate=Abscissa(2);
    if length(Abscissa)<4
        width=20;
        height=20;
    else
        width=Abscissa(3);
        height=Abscissa(4);
    end
else    
    if nargin < 4
        width=20;
        height=20;
    end
end

robot = java.awt.Robot();
rectangle = java.awt.Rectangle();

rectangle.x = abscissa;
rectangle.y = ordinate;
rectangle.width = width; % ��ȣ���Ļ�����Ͻ�Ϊԭ�㣩
rectangle.height = height; % �߶ȣ���Ļ�����Ͻ�Ϊԭ�㣩

image = robot.createScreenCapture(rectangle); %������������Ļ�ж�ȡ�����ص�ͼ��
w = image.getWidth(); %��ȡͼ����
h = image.getHeight(); %��ȡͼ��߶�
raster = image.getData(); %��ȡͼ��RGB���ݣ�����Raster��Ķ���
I = zeros(w*h*3,1); %�����洢RGB������Ϣ��double����
I = raster.getPixels(0,0,w,h,I); %��ȡͼ��һάRGB��ɫ����
I = uint8(I); %ת����uint8��������
I1 = I(1:3:length(I)); %��ȡRɫһά����
I1 = reshape(I1,w,h); %ת��ΪRɫ��ά����
I2 = I(2:3:length(I)); %��ȡGɫһά����
I2 = reshape(I2,w,h); %ת��ΪGɫ��ά����
I3 = I(3:3:length(I)); %��ȡBɫһά����
I3 = reshape(I3,w,h); %ת��ΪBɫ��ά����
I = uint8(zeros(w,h,3)); %�����洢RGBͼ����Ϣ��ά����
I(1:w,1:h,1) = I1; %����Rɫ����
I(1:w,1:h,2) = I2; %����Gɫ����
I(1:w,1:h,3) = I3; %����Bɫ����
I = imrotate(I,-90,'nearest'); %ͼ��˳ʱ����ת90��
I = flipdim(I,2); %ͼ����ֱ����
end