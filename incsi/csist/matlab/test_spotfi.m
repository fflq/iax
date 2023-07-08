clear all ;
close all ;
addpath('./csilibs') ;
addpath('/home/ubuntu/SpotFi/');
addpath('/home/ubuntu/CSI/algorithm/iaa/');


server = CSIServer() ;
%server = CSIFile("/tmp/a") ;
gn = 0;
while true
	csist = server.read_csi_st() 
	    
	handle_csist(csist);
	%input('');
	gn = gn + 1;
	if ~ mod(gn, 50)
		figure(3); close 3;
	end
end


function handle_csist(csist)
	csi = squeeze(csist.csi(1,:,:));

	%do_phaoff(csist, csi, 2);
	csi = calib_by_file(csi);
	do_aoa(csist, csi);
	do_phaoff(csist, csi);
end

function csi = calib_by_file(csi)
	persistent phaoff12 phaoff13;
	if isempty(phaoff12)
		phaoff12 = load('phaoff12.mat').phaoff12;
		phaoff13 = load('phaoff13.mat').phaoff13;
		figure(9); plot([phaoff12.',phaoff13.']);
		fprintf("******** load\n");
		input('');
	end
	csi(2,:) = csi(2,:) .* exp(-1j*phaoff12);
	csi(3,:) = csi(3,:) .* exp(-1j*phaoff13);
	%csi(2,:) = csi(2,:) * exp(-1j*0.35);
	%csi(3,:) = csi(3,:) * exp(-1j*-1.37);
end

function do_aoa(csist, csi)
	persistent aoas;
	
	only2 = true;
	envs = spotfi_envs();
	envs.fc = 5.2e9;
	envs.d = 0.028;
	if only2
		fprintf("***** only2\n");
		envs.nrx = 2;
		csi = csi(1:2,:);
	end
	aoa = spotfi(csi, envs, -1)
	plot_aoa(aoa, 11);

	envs = [];
	if only2
		envs.nrx = 2 ;
		envs.ntone = 30 ;
		envs.subcs = -58:4:58 ;
		envs.fc = 5.31e9 ;
		envs.d = 0.03 ;
		envs.f_space = 312.5e3 ;
		envs.fc_space = 4*envs.f_space ;
		csi = csi(1:2,:);
	end
	aoa = iaa(csi, envs)
	plot_aoa(aoa, 12);

	size(csi)
	aoas(end+1) = abs(aoa - 45);
	if ~ mod(length(aoas),50)
		figure(19); cdfplot(aoas());
		aoas = [];
	end
end


function plot_aoa(aoa, fid, holdon)
	if nargin < 3; holdon = false; end
	figaoa = 90 - aoa ;
	figure(fid) ;
	if holdon; hold on; else; hold off; end
	c = compass(cosd(figaoa), sind(figaoa)) ;
	c.LineWidth = 6 ;
	axis([-1, 1, 0, 1]) ;
end


function do_phaoff(csist, csi, savemask)
	if nargin < 3; savemask = 0; end

	phaoff12 = unwrap(angle(csi(2,:) .* conj(csi(1,:))));
	phaoff13 = unwrap(angle(csi(3,:) .* conj(csi(1,:))));
	phaoff23 = unwrap(angle(csi(3,:) .* conj(csi(2,:))));
	if bitand(savemask,1)
		save("phaoff12.mat", "phaoff12");
	end
	if bitand(savemask,2)
		save("phaoff13.mat", "phaoff13");
	end
	figure(3); hold on; 
	plot(phaoff12); plot(phaoff13,':o'); plot(phaoff23,':'); pause(0.1);
end





