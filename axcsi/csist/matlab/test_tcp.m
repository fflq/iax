
%cfd = tcpip('localhost', 7120, 'InputBufferSize', 4096) ;
%fopen(cfd) ;
%msg_len = fread(cfd, 1, 'int32', 'b') 
%data = fread(cfd, msg_len, 'uint8') ;
cfd = tcpclient('localhost', 7120) ;
msg_len = read(cfd, 1, 'int32')

%fclose(cfd) ;