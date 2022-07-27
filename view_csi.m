%{
    配intel5300pc, 是csi的client模式, 连接开热点的app手机
    csi: client[log_ro_remote.c], server[this]
    aoa: client[this], server[app]
%}
%clear ; close all; clc;
clear all ;
addpath('./csilibs') ;


run_from_tcp(gs().nets, gs().envs) ;

function aoas = run_from_tcp(nets, envs)
    sfd = wait_csi_client('localhost', nets.csi_port) ;
	tslows = [] ;
    
    n = 0 ;
    while true
        n = n + 1 ;
        gs().print("*%d pac\n", n) ;

        data = read_client_csi(sfd) ;
        if isempty(data); continue ; end

        % handle 1/10
        %if (0 ~= mod(n,2)); continue; end
        
        csi_trace = read_bf_packet(data) ;
	for i = 1:length(csi_trace)
		tslows(end+1) = csi_trace{i}.timestamp_low/1e6 
	end
	if (mod(length(tslows),50) == 1)
		save("tslows","tslows") ;
	end
        %[aoas, ~] = spotfi(csi_trace, envs, -1);
        %[aoas, tofs*1e9]

    end
    fclose(sfd) ;
end


function data = read_client_csi(sfd)
    data = [] ;
    try
        len = fread(sfd, 1, 'uint16') ;
        % datatype是数值类型的，返回的是double数组，手册说的
        data = uint8(fread(sfd, len, 'uint8')') ;
    catch E
        gs().print("*fread fail\n") ;
        gs().disp(E) ;
    end
end


function sfd = wait_csi_client(ip, port)
    %sfd = tcpserver(7020,"Timeout",20,"ByteOrder","big-endian") ;
    sfd = tcpip(ip, port, 'NetworkRole', 'server') ;
    fprintf("* [csi_server] wait csi client %s:%d\n", ip, port) ;
    fopen(sfd) ;
    fprintf("* [csi_server] get conn\n\n") ;
end

function draw_aoa(aoa)
    r = 1 ; win = 10 ;
    persistent aoas last_clock;
    if (isempty(aoas))
        aoas = zeros(1, win) ;
        last_clock = clock ;
    end

    aoas(end+1) = aoa ;
    aoas = smoothdata(aoas, 'movmean', win) ;
    aoa = aoas(end) ;


    if gs().aoafig
        figure(1) ;
        aoa = 90 - aoa ;
        c = compass(cosd(aoa), sind(aoa)) ;
        c.LineWidth = 6 ;
        axis([-1, 1, 0, 1]) ;
    end


    if (length(aoas) > win)
        aoas = aoas(end-win:end) ;
    end
end

