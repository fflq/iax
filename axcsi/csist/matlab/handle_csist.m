%clear all;
%close all;
addpath('/home/flq/ws/git/SpotFi')
addpath('/home/flq/ws/git/CSI/algorithm/iaa')

inputname='/flqtmp/data/ax210_air_10cm_40ht20.csi';
inputname='../../data/ax210_split_40ht20.csi' ;
inputname='/tmp/ax210_40ht20_k_0.csi';
inputname='/tmp/a';
inputname=7120;

ax = axcsi(inputname) ;
gn = 1 ;
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
	%input('')
	if ~mod(gn, 50)
		fprintf("******* gn %d\n", gn) ;
		figure(3); close 3;
	end
	gn = gn + 1;
end


function handle_csist_func(csist)
	%csist 
	if ~csi_filter(csist); fprintf("*** pass\n"); return; end

	csist = preprocess(csist) ;
	%plot_attack(csist) ;
	%plot_csi(csist.csi);
	%plot_mag(csist) ;
	%plot_phase(csist) ;
	%plot_phase_offset(csist) ;
	%plot_cir(csist) ;
	%save_calib(csist);
	do_aoa(csist) ;
end

function save_calib(csist)
	persistent phaoffs;
	if isempty(phaoffs)
	end
		scsi = squeeze(csist.scsi(:,1,:)) ;
		po = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
		if (mean(po) > 0)
			phaoffs = po;
			save("/flqtmp/phaoffs.mat", "phaoffs");
		end
		input("ok?")
end

function do_aoa(csist)
	persistent aoas;
	calc_aoa = @do_spotfi ;
	calc_aoa = @do_iaa ;

    %csist = calib_scsi_by_delta(csist, 0.012, pi) ; 
    %csist = calib_scsi_by_delta(csist, -0.001, 3) ; 
    csist = calib_scsi_by_file(csist) ;
	plot_phase_offset(csist) ;
	aoa1 = calc_aoa(csist) ;
    csist = calib_scsi_by_phaoff12(csist, pi) ; 
	aoa2 = calc_aoa(csist) ;
	plot_aoa(aoa1, 11, false); plot_aoa(aoa2, 11, true); 

	truthaoa = -30 ;
	aoas(end+1) = min(abs(aoa1-truthaoa), abs(aoa2-truthaoa));
	if ~ mod(length(aoas), 20)
		figure(99); p=cdfplot(abs(aoas(20:end))); p.LineWidth=2;
		save(['/flqtmp/aoas', num2str(truthaoa),'.mat'], "aoas");
		pause(0.1)
	end

	return;

    %csist = calib_scsi_by_phaoff12(csist, 0.4) ; 
    %csist = calib_scsi_by_delta(csist, -0.012, 1.0) ; 
    csist = calib_scsi_by_delta(csist, -0.001, 3) ; 
	plot_phase_offset(csist) ;
	aoa = calc_aoa(csist) ;
	if (aoa < -20) || (aoa > 75) 
		maoa = aoa ;
    	csist = calib_scsi_by_phaoff12(csist, pi) ; 
		aoa = calc_aoa(csist) ;
		fprintf("***** maoa(%f) => aoa(%f)\n", maoa, aoa);
		%input("")
	end
	plot_aoa(aoa, 11); return;
	aoas(end+1) = aoa;
	if length(aoas) > 20
		figure(99); cdfplot(abs(aoas(20:end)))
		pause(0.1)
	end
end

function csist = simu_aoa(aoa, csist, envs)
	lambda = 3e8 / envs.fc;
	addpha = envs.d*sin(aoa)*2*pi/lambda ;
	csist.scsi(2,:) = csist.scsi(1,:)*exp(-1j*addpha);
end

function aoa = do_iaa(csist)
	envs.nrx = csist.nrx ;
	envs.ntone = csist.nstone ;
	envs.subcs = csist.subc.subcs ;
	envs.fc = 5.2e9 ;
	envs.d = 0.013 ;
	envs.d = 0.026 ;
	envs.d = 0.03 ;
	envs.f_space = 312.5e3 ;
	envs.fc_space = envs.f_space ;

	%csist = simu_aoa(-pi/3, csist, envs) ;
	aoa = iaa(squeeze(csist.scsi(:,1,:)), envs)
	return ;
	%{
	%}
	persistent iaacsis ;
	if size(iaacsis,2) < 5
		fprintf("* iaacsis size2 %d\n", size(iaacsis,2)) ;
		iaacsis(:,end+1) = csi(:) ;
		return;
	else
		aoa = iaa(iaacsis, envs)
		iaacsis = [];
		%plot_aoa(iaoa, 12);
		return;
	end

	%csi(2,1) = csi(2,1) * exp(-1j*1.5) ;
	aoa = iaa(csi, envs)
	%plot_aoa(iaoa, 12);
end

function aoa = do_spotfi(csist)
	envs = spotfi_envs() ;
	envs.fc = 5.2e9 ;
	envs.lambda = envs.c / envs.fc ;
	envs.d = 0.013 ;
	envs.d = 0.026 ;
	envs.d = 0.03 ;
	envs.nrx = csist.nrx ;
	envs.ntx = csist.ntx ;
	envs.ntone = csist.ntone ;
	envs.ntone_sm = floor(envs.ntone/2) ;
	envs.subc_idxs = csist.subc.subcs ;

	aoa = spotfi(squeeze(csist.scsi(:,1,:)), envs, -1) 
	return ;

	%csist = simu_aoa(-pi/3, csist, envs) ;
	%csist = calib_by_last_delta_kb(csist, 1.7) ;
	csi = squeeze(csist.scsi(:,1,:)) ;
	saoa = spotfi(csi, envs, -1) 
	plot_aoa(saoa, 11);
	%csist = calib_by_last_delta_kb(csist, pi) ;
	%csi = squeeze(csist.scsi(:,1,:)) ;
	%saoa = spotfi(csi, envs, -1) 
	%plot_aoa(saoa, 21);

	persistent first;
	%if isempty(first); first = false ; saoa = -1 ; end
	global gdeltab goffs;
	goffs = 0;
	%(gdeltab > 0) ~= (saoa > 0), means right, nonedd goffs
	if (abs(gdeltab)>0.2) && ((gdeltab > 0) == (saoa > 0))
		goffs = pi;
	end
	if (abs(saoa)>80) 
		goffs = pi - goffs;
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

function [k, b, tones] = fit_csi(tones, xs)
	tones = squeeze(tones) ;
	mag = abs(tones) ;
    uwphase = unwrap(angle(tones)) ;
	%xs = 1:length(tones) ;
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

function csist = calib_scsi_by_file(csist)
	persistent phaoffs;
	if isempty(phaoffs)
		phaoffs = load('/flqtmp/phaoffs.mat').phaoffs.';
	end
    csist = calib_scsi_by_phaoff12_tones(csist, phaoffs);
end

function csist = calib_scsi_by_delta(csist, deltak, deltab)
	tones = csist.subc.subcs*deltak + deltab;
	csist = calib_scsi_by_phaoff12_tones(csist, tones.', 0);
	%csist.scsi(2,1,:) =  squeeze(csist.scsi(2,1,:)) .* exp(-1j*delta.') ;
end

function csist = calib_scsi_by_phaoff12_tones(csist, tones, offs)
	if nargin < 3; offs = 0; end
	for i = 1:csist.ntx
		csist.scsi(2,i,:) = squeeze(csist.scsi(2,i,:)) .* exp(-1j*(tones+offs));
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


function csist = calib_by_last_delta_kb(csist, calib_phaoff)
	persistent last_deltab;
	offs = 0;
	[dk, deltab, tones] = fit_csi(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)), csist.subc.subcs);
	if last_deltab == 0; last_deltab = deltab; end
	fprintf("*** last_deltab(%f) deltab(%f) %f\n", last_deltab, deltab, angle_mod(last_deltab-deltab));
	if ~ (abs(angle_mod(last_deltab - deltab)) < pi/3)
		fprintf("* last_deltab(%f) - deltab(%f) > x\n", last_deltab, deltab);
		deltab = deltab - pi;
		%calib_phaoff = calib_phaoff - pi
		offs = pi;
	end
	last_deltab = deltab;
	global gdeltab goffs;
	if isempty(goffs); goffs = 0; end
    csist = calib_scsi_by_phaoff12(csist, calib_phaoff, offs+goffs) ; 
	%use deltab after calib
	[~, gdeltab, ~] = fit_csi(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)), csist.subc.subcs);
	[gdeltab, goffs, offs]
end


function csist = preprocess(csist)
    scsi = csist.scsi;
    subcs = csist.subc.subcs;

	phaoff12 = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
	fprintf("* prep phaoff12 %f\n", mean(phaoff12))

	%csist = calib_by_last_delta_kb(csist, 3.5) ;
	%csist = calib_by_last_delta_kb(csist, 2.7) ;
	%csist = calib_by_last_delta_kb(csist, pi) ;

	phaoff12 = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
	fprintf("* prep phaoff12 %f\n", mean(phaoff12))
	return 

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

	%% calib by file
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
	%if (r > pi); r = r - 2*pi ; end
    while r > pi; r = r - 2*pi; end
    while r < -pi; r = r + 2*pi; end
end


function r = csi_filter(csist)
	r = false;
	if (csist.nrx < 2); return; end

	persistent pw1_sum pw2_sum ;
	if isempty(pw1_sum)
		pw1_sum = 0; pw2_sum = 0; 
	end
    pw1 = sum(abs(csist.csi(1,1,:)).^2)/1e4;
    pw2 = sum(abs(csist.csi(2,1,:)).^2)/1e4;
	%pw1_sum = pw1_sum + pw1 ; pw2_sum = pw2_sum + pw2 ;
	%[pw1_sum, pw2_sum]
    if (abs(pw1-pw2)/pw1 < 0.2); return; end
    if abs(csist.rssi(1)-csist.rssi(2)) < 3; return; end 
    if (csist.rssi(1) <= csist.rssi(2) || pw1 <= pw2); return; end

	[deltabk, deltab] = fit_csi(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)), csist.subc.subcs)
    %if abs(dk) > 0.1; return ; end
    %if abs(dk) > 0.05; return ; end

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
	figure(2); hold on;
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
	fprintf("* phaoff12 %f\n", mean(phaoff12))
	if (adjust)
	save("/tmp/init_phaoff12.mat", "phaoff12");
	end
	%phaseoffs(end+1) = mean(phaoff12) ;
	%phaseoffs(end+1) = phaoff12(1) ;
	phaseoffs(end+1,:) = phaoff12 ;
	%fprintf("- %d, %d, 12(%f)\n", i, length(phaseoffs), mean(phaseoffs)) ;
	%Util.plot_realtime1(1, phaseoffs) ;
	figure(3); hold on;
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



