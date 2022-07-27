clear all;
close all;
addpath('./csilibs') ;

run_apmode(gs().nets, gs().envs) ;

function aoas = run_apmode(nets, envs)
	global rc12 ;
    csi_clientfd = wait_conn(nets.csi_ip, nets.csi_port) ;

    n = 0 ;
    while true
        n = n + 1 ;
        fprintf("*%d pac\n", n) ;

        [data, r] = recv_csi(csi_clientfd) ;
        if (0 > r); continue ; end

        % handle 1/10
        %if (0 ~= mod(n,2)); continue; end
        csi_trace = read_bf_packet(data) ; 
		csi_trace = csi_trace{1} 
		perm = csi_trace.perm ;
		csi = get_scaled_csi(csi_trace) ;
		csi = squeeze(csi(1,:,:)) ;
		db(sum(abs(csi),2))
		csi(perm(1:3),:) = csi(1:3,:) ;
		db(sum(abs(csi),2))
		disp('------') ;
    end
    %fclose(...) ;
end


function [data, r] = recv_csi(sfd)
    data = [] ;
    r = 1 ;
    try
        len = fread(sfd, 1, 'uint16') ;
        % datatype是数值类型的，返回的是double数组，手册说的
        data = uint8(fread(sfd, len, 'uint8')') ;
    catch E
        r = -1 ;
        gs().disp(E) ;
        gs().print("* recv csi fail, again\n") ;
    end
end



function sfd = wait_conn(ip, port)
    %sfd = tcpserver(7020,"Timeout",20,"ByteOrder","big-endian") ;
    sfd = tcpip(ip, port, 'NetworkRole', 'server') ;
    fprintf("* [csi_server][%s:%d] accept...\n", ip, port) ;
    fopen(sfd) ;
    fprintf("* [csi_server] got\n\n") ;
end



