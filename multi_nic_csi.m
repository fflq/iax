clear all ;
close all ;
addpath('./csilibs') ;

server = CSIServer() ;
while true
	csi_st = server.read_csi() 
	if (isempty(csi_st))
		pause(2) ;
		continue ;
	end
	csi = get_scaled_csi(csi_st) ;
	csi = squeeze(csi) ;
	draw_db(csi_st.pci/1000, csi(1,10)) ;
	pause(0.0001) ;
end

function draw_db(fid, csi)
	persistent n csis ;
	if (isempty(n))
		n = 0 ;
		csis = cell(10,1) ;
	end
	csis{fid}(end+1,:) = angle(csi) + fid*10;
	n = size(csis{fid},1) ;

	figure(1) ; hold on ;
	%plot(db(abs(csi).')) ;
	%plot(n, angle(csi)) ;
	skip = 5 ;
	if (n > skip)
		plot(n-skip:n, csis{fid}(n-skip:n,:)) ;
	end
	%legend('RA', 'RB', 'RC') ;
end
