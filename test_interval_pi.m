clear all;
close all;
addpath('./csilibs') ;

global g_phaseoff g_perms ;
g_phaseoff = [] ;
g_perms = [] ;
angles = [] ;

%server = CSIFIle('/tmp/csi.log') ;
server = CSIServer() ;
n = 0 ;
while true
	csi_st = server.read_csi_st()  
	if (isempty(csi_st))
		fprintf("* empty csi_st\n") ;
		pause(2) ; continue ;
		%break ;
	end

	n = n+1 ;
	fprintf("* %d, pci(%d), %s\n", n, csi_st.pci, mat2str(csi_st.perm)) ;
	if (csi_st.pci == 4000)
		%r = calc_rc12(csi_st) ;
		r = calc_phaseoff(csi_st) ;
		fprintf("- %d, %d, 12(%f), 13(%f), 23(%f) %s\n", n, length(g_phaseoff), mean(g_phaseoff(:,1)), mean(g_phaseoff(:,2)), mean(g_phaseoff(:,3)), mat2str(csi_st.perm)) ;
		if (r > 0)
			Util.plot_realtime1(1, g_phaseoff(:,1)) ;
			%Util.plot_realtime1(1, g_phaseoff(:,2), 'c--o') ;
			%Util.plot_realtime1(1, g_phaseoff(:,3), 'y--o') ;
		end
	end
end

function save_rc12(data)
	%fp = fopen('/tmp/flqpi.log', 'w') ;
	%fwrite(fp, length(data), 'uint16', 'b') ;
	%fwrite(fp, data, 'uint8') ;
end

function r = calc_phaseoff(csi_st)
	r = -1 ;
	global g_phaseoff g_perms 

	csi = Util.get_csi(csi_st) ;
	%fprintf("* calb\n") ;
	%csi = Util.cabl_phase(csi, 0.06, -2.95) ;
	perm = csi_st.perm ;
	g_perms(end+1,:) = csi_st.perm ;

	if (true)
	%if (perm(1)+perm(2) == 3)
		%db(sum(abs(csi),2))
		%csi(perm(1:3),:) = csi(1:3,:) ;
		%db(sum(abs(csi),2)) ;
		%angleoffs = angle(csi(2,:)) - angle(csi(1,:)); % has +k2pi offset 
		angleoffs12 = angle( csi(2,:) .* conj(csi(1,:)) ) ;  
		angleoffs13 = angle( csi(3,:) .* conj(csi(1,:)) ) ;  
		angleoffs23 = angle( csi(3,:) .* conj(csi(2,:)) ) ;  
		g_phaseoff(end+1,1) = mean(angleoffs12) ;
		g_phaseoff(end,2) = mean(angleoffs13) ;
		g_phaseoff(end,3) = mean(angleoffs23) ;
		r = 1 ;
	end
	%g_perms
end



