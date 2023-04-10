%clear all;
%close all;
addpath('/home/flq/ws/git/SpotFi')
addpath('/home/flq/ws/git/CSI/algorithm/iaa')

inputname='/flqtmp/data/ax210_air_10cm_40ht20.csi';
inputname='../../data/ax210_split_40ht20.csi' ;
inputname='/tmp/a';
inputname=7120;

ax = axcsi(inputname) ;
while true
	try
		st = ax.read() ;
	catch
		if ax.is_net
			fprintf("* net reconn\n"); pause(2) ;
			ax = axcsi(inputname);
			continue;
		end
	end
	if isempty(st); break ; end
	handle_csist_func(st) ;
end


function handle_csist_func(csist)
	%csist 
	if ~csi_filter(csist); return; end

	csist = preprocess(csist) ;
	%plot_attack(csist) ;
	%plot_csi(csist.csi);
	%plot_mag(csist) ;
	%plot_phase(csist) ;
	%plot_phase_offset(csist, true) ;
	plot_phase_offset(csist) ;
	%plot_cir(csist) ;
	do_spotfi(csist) ;
	%do_iaa(csist) ;
end


function old_view_csi_func(filename, reload)
	if (nargin < 2); reload = true ; end
	sts = load_csi(filename, reload) ;

	len = length(sts) ;
	for i = 1:len
		if ~mod(i, 1000); fprintf("- %d/%d\n", i, len) ; end
		handle_csist_func(sts{1,i}) ;
		pause
	end
	%stats_macs([], true) ;
end


function plot_attack(csist)
	persistent aks;
	if isempty(aks); aks = []; end 
	aks(end+1) = abs(csist.scsi(1,1,10)) ;
	range = max(length(aks)-2,1):length(aks) ;
	hold on; plot(range, aks(range)) ;
end

function csist = simu_aoa(aoa, csist, envs)
	lambda = 3e8 / envs.fc;
	addpha = envs.d*sin(aoa)*2*pi/lambda ;
	csist.scsi(2,:) = csist.scsi(1,:)*exp(-1j*addpha);
end

function do_iaa(csist)
	envs.nrx = csist.nrx ;
	envs.ntone = csist.nstone ;
	envs.subcs = csist.subc.subcs ;
	envs.fc = 5.2e9 ;
	envs.d = 0.013 ;
	envs.d = 0.026 ;
	envs.f_space = 312.5e3 ;
	envs.fc_space = envs.f_space ;

	%csist = simu_aoa(-pi/3, csist, envs) ;
	csi = squeeze(csist.scsi(:,1,:)) ;
	%{
	%}
	persistent iaacsis ;
	if size(iaacsis,2) < 5
		fprintf("* iaacsis size2 %d\n", size(iaacsis,2)) ;
		iaacsis(:,end+1) = csi(:) ;
		return;
	else
		iaoa = iaa(iaacsis, envs)
		iaacsis = [];
		plot_aoa(iaoa, 12);
		return;
	end

	%csi(2,1) = csi(2,1) * exp(-1j*1.5) ;
	iaoa = iaa(csi, envs)
	plot_aoa(iaoa, 12);
	csi(2,1) = csi(2,1) * exp(-1j*(pi)) ;
	iaoa2 = iaa(csi, envs)
	plot_aoa(iaoa2, 14);
end

function do_spotfi(csist)
	envs = spotfi_envs() ;
	envs.fc = 5.2e9 ;
	envs.lambda = envs.c / envs.fc ;
	envs.d = 0.013 ;
	envs.d = 0.026 ;
	envs.nrx = csist.nrx ;
	envs.ntx = csist.ntx ;
	envs.ntone = csist.ntone ;
	envs.ntone_sm = floor(envs.ntone/2) ;
	envs.subc_idxs = csist.subc.subcs ;

	%csist = simu_aoa(-pi/3, csist, envs) ;
	csi = squeeze(csist.scsi(:,1,:)) ;
	csi(2,1) = csi(2,1) * exp(-1j*2.2) ;
	saoa = spotfi(csi, envs, -1) 
	plot_aoa(saoa, 11);

	csi(2,1) = csi(2,1) * exp(-1j*(pi)) ;
	saoa = spotfi(csi, envs, -1) 
	%plot_aoa(saoa, 13);
end

function plot_aoa(aoa, fid)
	figaoa = 90 - aoa ;
	figure(fid) ;
	c = compass(cosd(figaoa), sind(figaoa)) ;
	c.LineWidth = 6 ;
	axis([-1, 1, 0, 1]) ;
end

function [k, b, tones] = fit_csi(tones)
	tones = squeeze(tones) ;
	mag = abs(tones) ;
    uwphase = unwrap(angle(tones)) ;
	xs = 1:length(tones) ;
    z = polyfit(xs, uwphase, 1) ;
    k = z(1) ;
	b = z(2) ;
    fprintf("* k(%f) b(%f)\n", k, b) ;
    pha = uwphase - k*xs;
    pha = uwphase - k*xs - b;
    pha = uwphase - b;
    %sns.lineplot(x=xs, y=pha)
    tones = mag.*exp(1j*pha);
end


function csist = calib_scsi_by_phaoff12(csist, first_phaoff, offs)
	if nargin < 3; offs = 0; end
	for i = 1:csist.ntx
		csist.scsi(2,i,:) = csist.scsi(2,i,:) * exp(-1j*(first_phaoff+offs));
	end
end

function csist = calib_scsi_by_phaoff12_tones(csist, first_phaoff, offs)
	if nargin < 3; offs = 0; end
	for i = 1:csist.ntx
		csist.scsi(2,i,:) = squeeze(csist.scsi(2,i,:)) .* exp(-1j*(first_phaoff+offs));
	end
end

function csist = calib_scsi_by_first_phaoff12(csist, first_phaoff)
	%csist.scsi(2,1,:) = csist.scsi(2,1,:) * exp(-1j*phaoff12) ;
	first_phaoff_ranges = [-pi/2, pi/2] + first_phaoff ;
	phaoff12 = unwrap(angle(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)))) ;
	avg_phaoff12 = mean(phaoff12) ;
	if avg_phaoff12 <= 0
		avg_phaoff12 = avg_phaoff12 + 2*pi ;
	end
	%print('before avg_phaoff12 {}'.format(avg_phaoff12))
	% judge a or a-pi
	if ~(first_phaoff_ranges(1) < avg_phaoff12 < first_phaoff_ranges(2))
		first_phaoff = first_phaoff - pi;
	end
	for i = 1:csist.ntx
		csist.scsi(2,i,:) = csist.scsi(2,i,:) * exp(-1j*first_phaoff);
	end
end


function csist = calib_scsi_by_delta(csist, deltak, deltab)
	delta = csist.subc.subcs*deltak + deltab;
	csist.scsi(2,1,:) =  squeeze(csist.scsi(2,1,:)) .* exp(-1j*delta.') ;
end


function csist = preprocess(csist)
    csi = csist.scsi;
    subcs = csist.subc.subcs;

    [k1, b1, tone1] = fit_csi(csi(1,1,:));
    [k2, b2, tone2] = fit_csi(csi(2,1,:));
    pha12 = unwrap(angle(tone2 .* conj(tone1)));
	%figure(21); hold on; plot(subcs, pha12, ':o') ;
    %deltab = mod(b2-b1, 2*pi) ;
	deltak = k2 - k1 ;
	deltab = b2 - b1 ;
	calib_phaoff = deltab ;
	calib_phaoff = deltab + deltak*length(subcs)/2;
	if(calib_phaoff <= 0); calib_phaoff = calib_phaoff+2*pi; end
    fprintf("* calib_phaoff %f\n", calib_phaoff);
	%calib_phaoff = 2;
    %csist = calib_scsi_by_first_phaoff12(csist, calib_phaoff);
    %csist = calib_scsi_by_delta(csist, deltak, deltab);
	%hold on; plot(subcs, unwrap(angle(squeeze(csist.scsi(:,1,:))), [], 2)) ;
	%csist.scsi(:,1,:) = [tone1.'; tone2.'] ;

	calib_phaoff = 0.5 ;
	offs = 0;
	%new
    persistent last_deltab;
	if isempty(last_deltab); last_deltab = deltab; end
    fprintf("****** last_deltab(%f) deltab(%f) %f\n", last_deltab, deltab, angle_mod(last_deltab-deltab));
    if ~ (abs(angle_mod(last_deltab - deltab)) < pi/2)
        fprintf("* last_deltab(%f) - deltab(%f) > x\n", last_deltab, deltab) ;
        deltab = deltab - pi ;
        %calib_phaoff = calib_phaoff - pi ;
		offs = pi ;
	end
    last_deltab = deltab ;

    csist = calib_scsi_by_phaoff12(csist, calib_phaoff, offs) ; return ;
	init_phaoff12_file = ('/tmp/init_phaoff12.mat') ;
	if exist(init_phaoff12_file)
		phaoff12 = load(init_phaoff12_file).phaoff12 ;
		csist = calib_scsi_by_phaoff12_tones(csist, phaoff12.', offs) ; return ;
	end
end

%once change is less than
function r = angle_mod(ang)
	r = mod(ang, 2*pi) ;
	if (r > pi)
		r = r - 2*pi ;
	end
end


function r = csi_filter(csist)
	r = false;
	if (csist.nrx < 2); return; end

    pw1 = sum(abs(csist.csi(1,1,:)).^2)/1e4;
    pw2 = sum(abs(csist.csi(2,1,:)).^2)/1e4;
    if (csist.rssi(1) <= csist.rssi(2) || pw1 <= pw2); return; end

	r = true ;
end

function plot_cir(csist)
	csist
	cfr = squeeze(csist.csi(1,1,:)) ;
	cir = ifft(cfr) ;
	cir = cir(1:10) ;
	dt = 1 / (csist.chan_width * 1e6) ;
	dt = dt * 1e9 ; %ns
	xs = (0:length(cir)-1)*dt ; 
	[v, i] = max(real(cir)) ;
	[xs(i), xs(i)*0.3]
	hold on ;
	plot(xs, real(cir), ':o', 'LineWidth', 2) ;
end


function plot_phase(csist)
	subc = csist.subc ;
	csi = squeeze(csist.scsi(:,1,:)) ;
	tones = squeeze(csist.csi(1,1,:)) ;
	stones = squeeze(csist.scsi(1,1,:)) ;

	title(csist.chan_type_str);
	%hold off;
	figure(1); hold on;
	plot(subc.subcs, unwrap(angle(csi.')), 'LineWidth',2) ; 
	%plot(subc.subcs, angle(stones)+20, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), unwrap(angle(tones))-20, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), angle(tones)-50, 'LineWidth',2) ; 
end


function plot_mag(csist)
	subc = csist.subc ;
	tones = squeeze(csist.csi(:,1,:)) ;
	stones = squeeze(csist.scsi(:,1,:)) ;

	title(csist.chan_type_str);
	figure(1); hold off;
	plot(subc.subcs, abs(stones(1,:)).', 'LineWidth',2) ; 
	figure(1); hold on;
	plot(subc.subcs, abs(stones(2,:)).', ':o', 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; 
end


function plot_phase_offset(csist, adjust)
	if nargin < 2; adjust = false; end
	persistent phaseoffs
	if isempty(phaseoffs); phaseoffs = [] ; end

	subc = csist.subc ;
	scsi = squeeze(csist.scsi(:,1,:)) ;
	phaoff12 = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
	if (adjust)
	save("/tmp/init_phaoff12.mat", "phaoff12");
	end
	%phaseoffs(end+1) = mean(phaoff12) ;
	%phaseoffs(end+1) = phaoff12(1) ;
	phaseoffs(end+1,:) = phaoff12 ;
	%fprintf("- %d, %d, 12(%f)\n", i, length(phaseoffs), mean(phaseoffs)) ;
	%Util.plot_realtime1(1, phaseoffs) ;
	figure(2); hold on;
	plot(csist.subc.subcs, phaoff12, 'LineWidth',2) ;
	%csist
	%input('-')
	return

    pof_len = length(phaseoffs) ;
    if ~mod(pof_len, 100)
		csist
        grid on ;
        hold off ;
        %by tones
        %plot3(100*repmat(1:pof_len,[subc.subcs_len,1]), repmat(subc.subcs, [pof_len,1]).', phaseoffs.', 'LineWidth',2) ;
        %by num
        plot3(1*repmat(1:pof_len,[subc.subcs_len,1]).', repmat(subc.subcs, [pof_len,1]), phaseoffs, 'LineWidth',2) ;
        %input('a');
    end
end
		


function sts = load_csi(filename, reload)
	%filename = "../netlink/ax.csi" ;
	savename = "./axcsi.mat" ;
	if reload || ~exist(savename)
		fprintf("* reload %s\n", filename) ;
		sts = read_axcsi(filename, savename) ;
	else
		sts = load(savename).sts ;
	end
end


function stats_macs(st, print)
	persistent map ;
	if isempty(map)
		map = containers.Map() ;
	end
	if (print)
		macs = keys(map) ;
		macns = values(map) ; 
		for i = 1:length(macs)
			fprintf("-%d. %s %d\n", i, macs{1,i}, macns{1,i});
		end
		return ;
	end

	key = st.mac ;
	if any(strcmp(keys(map),key))
		map(key) = map(key) + 1 ;
	else
		map(key) = 1 ;
	end
end


function plot_csi(csi)
	csi = squeeze(csi(:,1,:)) ;
	csi_phase = unwrap(angle(csi.')) ;
	%csi_phase = angle(csi.') ;
	csi_mag = abs(csi.') ;
	plot(csi_phase) ;
	%plot(csi_mag) ;
	pause(0.01) ;
	input('-') ;
end


function map_sts(sts)
	map = containers.Map() ;
	for i = 1:length(sts)
		st = sts{i} ;
		csi_len_str = int2str(st.csi_len) ;
		if any(strcmp(keys(map),csi_len_str))
			map(csi_len_str) = [map(csi_len_str); st] ;
		else
			map(csi_len_str) = st ;
		end
	end
	map_keys = keys(map) ;
	map_vals = values(map) ;
	for i = 1:length(map_keys)
		[str2num(map_keys{i}), length(map_vals{i})]
	end
	sts = map('416') ;
	save("axcsi_nonht20.mat", 'sts');
	sts = map('448') ;
	save("axcsi_ht20.mat", 'sts');
	sts = map('1824') ;
	save("axcsi_ht40.mat", 'sts');
	sts = map('3872') ;
	save("axcsi_vht80.mat", 'sts');
end



