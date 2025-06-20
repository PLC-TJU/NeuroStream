function TCPHandle=StartNeuroScanAcq(IPAdr,PortNum)
if ~exist('PortNum','var') || isempty(PortNum)
    PortNum = 4000;
end

TCPHandle=tcpip(IPAdr,PortNum, 'localport', 40999, ...
    'NetworkRole', 'client', 'InputBufferSize', 400000);

% ���ӽ����뻺��������
try
    fopen(TCPHandle);
    while TCPHandle.BytesAvailable > 0
        fread(TCPHandle, TCPHandle.BytesAvailable);
    end
catch ME
    fclose(TCPHandle);
    error('TCP����ʧ��: %s', ME.message);
end


%��ʼ�ɼ�
B=[67,84,82,76,0,2,0,1,0,0,0,0];
fwrite(TCPHandle,B)
pause(0.0001);

fread(TCPHandle,24);

%��ʼ��ȡ����
B=[67,84,82,76,0,3,0,3,0,0,0,0];
fwrite(TCPHandle,B)
end
