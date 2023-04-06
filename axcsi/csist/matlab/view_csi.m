%clear all;
%close all;
addpath('/home/flq/ws/git/SpotFi')

view_csi_func('/flqtmp/data/ax210_air_10cm_40ht20.csi');
%view_csi_func('../../data/ax210_split_40ht20.csi') ;
%view_csi_func('/tmp/a');

function view_csi_func(filename, reload)
	if (nargin < 2); reload = true ; end
	sts = load_csi(filename, reload) ;

	len = length(sts) ;
	for i = 1:len
		if ~mod(i, 1000); fprintf("- %d/%d\n", i, len) ; end
		csist = sts{1,i} ;
		if ~csi_filter(csist); continue; end

		csist 
		%csist = preprocess(csist) ;
		%plot_attack(csist) ;
		%plot_csi(csist.csi);
		%plot_mag(csist) ;
		%plot_phase(csist) ;
		%plot_phase_offset(csist) ;
		%plot_cir(csist) ;
		do_spotfi(csist) ;
	
		input('a') ;
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

function do_spotfi(csist)
	envs = spotfi_envs() ;
	envs.nant_rx = csist.nrx ;
	envs.nant_tx = csist.ntx ;
	envs.ntone = csist.ntone ;
	envs.ntone_sm = floor(envs.ntone/2) ;
	envs.subc_idxs = csist.subc.subcs ;
	envs.en = true ;
	[aoa, aoatofs] = spotfi(squeeze(csist.scsi(:,1,:)), envs, -1) 
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

function csist = calib_scsi_by_phaoff12(csist, phaoff12)
	csist.scsi(2,1,:) = csist.scsi(2,1,:) * exp(-1j*phaoff12) ;
end

function csist = preprocess(csist)
    csi = csist.scsi;
    subcs = csist.subc.subcs;

    [k2, b2, tone2] = fit_csi(csi(2,1,:));
    [k1, b1, tone1] = fit_csi(csi(1,1,:));
    pha12 = unwrap(angle(tone2 .* conj(tone1)));
	figure(1); plot(subcs, pha12, '-o') ;
    deltab = mod(b2-b1, 2*pi) ;
	if(deltab > pi); deltab = deltab-2*pi; end
    fprintf("* deltab %f\n", deltab);
	deltab=1.6
    csist = calib_scsi_by_phaoff12(csist, deltab);
	hold on; plot(subcs, unwrap(angle(squeeze(csist.scsi(:,1,:))), [], 2)) ;
	%csist.scsi(:,1,:) = [tone1.'; tone2.'] ;
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
	tones = squeeze(csist.csi(1,1,:)) ;
	stones = squeeze(csist.scsi(1,1,:)) ;

	title(csist.chan_type_str);
	%hold off;
	hold on;
	plot(subc.subcs, unwrap(angle(stones))-2, 'LineWidth',2) ; 
	%plot(subc.subcs, angle(stones)+20, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), unwrap(angle(tones))-20, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), angle(tones)-50, 'LineWidth',2) ; 
end


function plot_mag(csist)
	subc = csist.subc ;
	tones = squeeze(csist.csi(1,1,:)) ;
	stones = squeeze(csist.scsi(1,1,:)) ;

	title(csist.chan_type_str);
	hold on;
	plot(subc.subcs, abs(stones)-2, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; 
	input('a') ;
end


function plot_phase_offset(csist)
	persistent phaseoffs
	if isempty(phaseoffs); phaseoffs = [] ; end

	subc = csist.subc ;
	scsi = squeeze(csist.scsi(:,1,:)) ;
	angleoffs12 = angle( scsi(2,:) .* conj(scsi(1,:)) ) ;  
	%phaseoffs(end+1) = mean(angleoffs12) ;
	%phaseoffs(end+1) = angleoffs12(1) ;
	phaseoffs(end+1,:) = angleoffs12 ;
	%fprintf("- %d, %d, 12(%f)\n", i, length(phaseoffs), mean(phaseoffs)) ;
	%Util.plot_realtime1(1, phaseoffs) ;
	hold on;
	plot(csist.subc.subcs, angleoffs12, 'o', 'LineWidth',2) ;
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



