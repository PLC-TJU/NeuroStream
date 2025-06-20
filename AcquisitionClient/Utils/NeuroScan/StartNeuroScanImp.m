function TCPHandle=StartNeuroScanImp(IPAdr,PortNum)
if ~exist('PortNum','var') || isempty(PortNum)
    PortNum = 4000;
end

TCPHandle=tcpip(IPAdr,PortNum, 'localport', 40999, 'NetworkRole', 'client',  'InputBufferSize', 400000);
fopen(TCPHandle);

%开始采集
B=[67,84,82,76,0,2,0,3,0,0,0,0];
fwrite(TCPHandle,B)
pause(0.0001);

a=fread(TCPHandle,24);