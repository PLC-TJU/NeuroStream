function StopNeuroScanImp(TCPHandle)
%�����ɼ�
B=[67,84,82,76,0,2,0,2,0,0,0,0];
fwrite(TCPHandle,B)

%�ر�����
B=[67,84,82,76,0,1,0,2,0,0,0,0];
fwrite(TCPHandle,B)

fclose(TCPHandle);
delete(TCPHandle)
