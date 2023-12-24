%{
    配intel5300pc, 是csi的client模式, 连接开热点的app手机
    csi: client[log_ro_remote.c], server[this]
    aoa: client[this], server[app]
%}
%clear ; close all; clc;
clear all ;
addpath('./csilibs') ;


%server = CSIFile('./data/csi.dat') ;
server = CSIServer() ;
%server = CSIFile('/tmp/a.csi')
while true
	csi_st = server.read_csi_st() 
	if (isempty(csi_st))
		pause(2) ; continue ;
	end
	handle_csist(csi_st) ;
end


function handle_csist(csi_st)
	persistent angles
	csi = Util.get_csi(csi_st) ;
	%angles(end+1,1) = angle(csi(1,1)) ;
	%angles(end,2) = angle(csi(2,1)) ;
	%angles(end,3) = angle(csi(3,1)) ;
	angles(end+1,1) = mean(angle(csi(1,:))) ;
	angles(end,2) = mean(angle(csi(2,:))) ;
	angles(end,3) = mean(angle(csi(3,:))) ;
	Util.plot_realtime1(1, angles(:,1)) ;
	Util.plot_realtime1(1, angles(:,2), 'c--o') ;
	Util.plot_realtime1(1, angles(:,3), 'y--o') ;
end
