clear all;
close all;
addpath('./csilibs') ;

server = CSIFile('/tmp/a') ;
n = 0 ;
while true
	csist = server.read_csi_st()  
    n
	if (isempty(csist))
		fprintf("* empty csist\n") ;
		break ;
	end
	n = n+1 ;

	csi = squeeze(csist.csi(1,:,:));
    csi(:,:) = csi(csist.perm,:);
    phaoff12 = unwrap(angle(csi(2,:) .* conj(csi(1,:))));
	plot(phaoff12); hold on;

end


