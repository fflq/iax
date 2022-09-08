clear all ;
close all ;
addpath('./csilibs') ;

server = CSIServer() ;
%server = CSIFile("/tmp/csi.dat") ;
aoas = [] ;
while true
	csi_st = server.read_csi_st() ;
	if (isempty(csi_st))
		aoas
		pause(10) ; continue ;
	end
	%csi_st.pci=4000;
	fprintf("& pci/%d\n", csi_st.pci) ;
	if (csi_st.pci ~= 4000)
		continue ;
	end

    [aoa, ~] = spotfi(csi_st, gs().envs, -1);
	aoas(end+1) = aoa(1) ;
	len = length(aoas) ;
	fprintf("* mean(%f)\n", mean(aoas(max(end-100,1):end))) ;
	pause(0.0001) ;
end

