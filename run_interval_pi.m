clear all;
close all;
addpath('./csilibs') ;

global rc12 perms angles ;
rc12 = [] ;
perms = [] ;
angles = [] ;

local=true;
local=false;
if (local)
	filename = '/tmp/flqpi.log' ;
	csi_sts = read_bf_file(filename) ; 
	for i = 1:length(csi_sts)
		calc_rc12(csi_sts{i}) ;
	end
	figure(1); hold on ; plot(rc12, '--o') ;
	%figure(2); plot(angles) ; legend('1','2','3') ;
else
	server = CSIServer() ;
	n = 1 ;
	while true
		csi_st = server.read_csi() ; 
		if (isempty(csi_st))
			pause(2) ;
			continue ;
		end
		if (csi_st.pci ~= 4000)
			continue ;
		end
		%fp = fopen('/tmp/flqpi.log', 'w') ;
		%fwrite(fp, length(data), 'uint16', 'b') ;
		%fwrite(fp, data, 'uint8') ;
		r = calc_rc12(csi_st) ;
		if (r > 0)
			figure(1); hold on ;
			plot(n, rc12(end), '--o') ;
			n = n+1 ;
		end
		pause(0.0001) ;
	end
end


function r = calc_rc12(csi_st)
	r = -1 ;
	global rc12 perms angles

	csi = get_scaled_csi(csi_st) ;
	csi = squeeze(csi(1,:,:)) ; 
	perm = csi_st.perm ;
	perms(end+1,:) = csi_st.perm ;

	fprintf("- %d, %s\n", i, mat2str(perm)) ;
	if (perm(1)+perm(2) == 3)
		%db(sum(abs(csi),2))
		%csi(perm(1:3),:) = csi(1:3,:) ;
		db(sum(abs(csi),2)) ;
		%angleoffs = angle(csi(2,:)) - angle(csi(1,:)); % has +k2pi offset 
		angleoffs = angle( csi(2,:) .* conj(csi(1,:)) ) ;  
		rc12(end+1) = mean(angleoffs) ;
		angles(end+1,:) = mean(angle(csi), 2) ;
		r = 1 ;
	end
	%perms
end


