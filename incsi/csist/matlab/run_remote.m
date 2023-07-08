%{
    run_remote_apmode.m
    配intel5300pc, 是csi的ap模式, 使用kde5-nm-connection-editor, 手机连pc热点
    csi: client[log_ro_remote.c], server[this]
    aoa: client[app], server[this]
Instrument Tools
Signal Processing Toolbox
%}
%clear ; close all; clc;
clear all ;
addpath('./csilibs') ;

envs = gs().envs ;
envs.niter = 1 ;

run_apmode(gs().nets, envs) ;

function aoas = run_apmode(nets, envs)
    csi_clientfd = wait_conn(nets.csi_ip, nets.csi_port) ;
    sendaoa = gs().sendaoa ;
    if sendaoa
        aoa_clientfd = wait_conn(nets.aoa_ip, nets.aoa_port) ;
    end

    n = 0 ;
    while true
        n = n + 1 ;
        gs().print("*%d pac\n", n) ;

        [data, r] = recv_csi(csi_clientfd) ;
        if (0 > r); continue ; end

        % handle 1/10
        %if (0 ~= mod(n,2)); continue; end
        
        csi_trace = read_bf_packet(data) ;
        [aoas, ~] = spotfi(csi_trace, envs, -1);
        if isfield(gs(),'saveaoa') && gs().saveaoa; saveaoas(aoas(1)); end

        if sendaoa
            r = send_aoa(aoa_clientfd, aoas(1)) ;
            if (0 > r); sendaoa = false ; end
        end
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


function draw_aoa(aoa)
    if gs().aoafig
        figure(1) ;
        aoa = 90 - aoa ;
        c = compass(cosd(aoa), sind(aoa)) ;
        c.LineWidth = 6 ;
        axis([-1, 1, 0, 1]) ;
    end
end


function r = send_aoa(sfd, aoa)
    r = 1 ; win = 10 ;
    persistent aoas last_clock;
    if (isempty(aoas))
        aoas = zeros(1, win) ;
        last_clock = clock ;
    end

    aoas(end+1) = aoa ;
    aoas = smoothdata(aoas, 'movmean', win) ;
    aoa = aoas(end) ;

    draw_aoa(aoa) ;

    % 间隔时发,但还是要发,数据出发持续csi
    if (etime(clock ,last_clock) < 0.05)
        %a=clock;a(6)
        pause(0.1) ;
    end
    last_clock = clock ;

    try
        fwrite(sfd, aoa, 'int32') ;
        %pause(1)
    catch E
        gs().disp(E) ;
        gs().print("* send fail, stop\n") ;
        r = -1 ;
    end
    if (length(aoas) > win)
        aoas = aoas(end-win:end) ;
    end
end



function sfd = wait_conn(ip, port)
    %sfd = tcpserver(7020,"Timeout",20,"ByteOrder","big-endian") ;
    sfd = tcpip(ip, port, 'NetworkRole', 'server') ;
    fprintf("* [csi_server][%s:%d] accept...\n", ip, port) ;
    fopen(sfd) ;
    fprintf("* [csi_server] got\n\n") ;
end



function saveaoas(aoa)
    persistent aoas n ;
    if (isempty(aoas))
        aoas = zeros(1000,1) ;
        n = 1 ;
    end

    skip = 100 ;
    maxn = 200 ;
    if (skip < n && n < maxn+skip)
        aoas(n) = aoa ;
    elseif (n == maxn+skip)
        save('aoas', 'aoas') ;
    end
    n = n + 1 ;
end


%{
function r = send_aoa_old(sfd, aoa)
    win = 10 ;
    persistent aoas n ;
    if (isempty(aoas))
        aoas = zeros(win,1) ;
        n = 1 ;
    end

    aoas(n) = aoa ;
    n = n + 1 ;
    if (n <= win); return ; end
    n = 1 ;
    r = 1 ;
    aoas = smoothdata(aoas, 'movmean', win) ;

    for i = 1:length(aoas)
        aoa = aoas(i) ;
        try
            fwrite(sfd, aoa, 'int32') ;
            %pause(1)
        catch E
            gs().disp(E) ;
            gs().print("* send fail, stop\n") ;
            r = -1 ;
            break ;
        end
    end
end
%}
