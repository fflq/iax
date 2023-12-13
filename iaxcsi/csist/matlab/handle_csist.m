clear all;
close all;

addpath('/flqtmp')
root_dir = 'C:/Users/flq/OneDrive/papers/iax/data/paper/';
addpath(root_dir);
addpath([root_dir, 'aoa']);
algorithm_dir = '../../../algorithm/';
addpath([algorithm_dir, 'dbf']);
addpath([algorithm_dir, 'music']);
addpath([algorithm_dir, 'iaa']);
addpath([algorithm_dir, 'spotfi']);
addpath("/home/flq/ws/git/SpotFi");


inputname='/flqtmp/attack_5m_20spm_130-3400.csi'; use_net = false;
inputname='/flqtmp/data/ax210_40ht20_air_10cm_same_rx.csi'; use_net = false;
inputname='/flqtmp/paper/ax210_40vht160_cir.csi'; use_net=false;
inputname='/flqtmp/ax210_40ht20_-60.csi'; use_net=false;
inputname='/flqtmp/paper/ax210_40vht160_split.csi'; use_net = false;
inputname='/tmp/a'; use_net = false;
inputname='/flqtmp/mon2.csi'; use_net = false;
inputname='/flqtmp/paper/ax210_40ht40_split.csi'; use_net = false;
inputname='/flqtmp/paper/ax210_40vht160_split.csi'; use_net = false;
inputname='ax210_40ht20_split.csi'; use_net = false;
inputname='ax210_40vht80_split.csi'; use_net = false;
inputname='ax210_40he20_split.csi'; use_net = false;
inputname='iax200_40ht20.csi'; use_net = false;
inputname='iax200_40vht160.csi'; use_net = false;
inputname='ax210_40vht160_air_noatt.csi'; use_net = false;
inputname='ax210_40ht40_split.csi'; use_net = false;
inputname='ax210_40ht20_60.csi'; use_net=false;
inputname='ax210_40ht20_-60.csi'; use_net=false;
inputname='ax210_40ht20_-30.csi'; use_net=false;
inputname='ax210_40ht20_0.csi'; use_net=false;
inputname='ax210_40ht20_30.csi'; use_net=false;
inputname='ax210_40ht20_45.csi'; use_net=false;
inputname='192.168.1.10:7120'; use_net = true;
inputname='127.0.0.1:7120'; use_net = true;

handle_all = true;
handle_all = false;
if handle_all
	sts = iaxcsi(inputname).read_cached();
	handle_all_csist_func(sts);
	return;
end
%handle_aoa_cdf(); return;

gn = 1 ;
ax = [] ;
while true
	try
		if isempty(ax); ax = iaxcsi(inputname) ; end
		st = ax.read_once() ;
	catch ME
		ME.identifier
		if isempty(ax) || ax.test()
			fprintf("* wait conn/read\n") ;
		else
			fprintf("* reconn\n"); ax = [] ;
		end
		pause(3); continue;
	end

	if isempty(st); break; end
	handle_csist_func(st) ;
	if ~mod(gn, 100)
		fprintf("*** gn %d\n", gn) ;
		%figure(3); close 3;
	end
	gn = gn + 1;
end


function set_style(h)
	if nargin < 1; return; end
	h.LineWidth = 1.5;
	set(gca,'FontName','Times New Roman','FontSize',15,'FontWeight','bold','LineWidth',1.5); 
	return;
	%margin 0
	set(gca, 'LooseInset', [0.01,0.01,0.01,0.01]); box on;
end


function handle_csist_func(csist)
	%csist 
	if ~csi_filter(csist); 
		%fprintf("*** pass\n"); 
		return; 
	end
	
	csist
	%csist = preprocess(csist) ; %nouse
	%plot_attack(csist) ;
	%plot_csi(csist.csi);
	%plot_mag(csist) ;
	%plot_phase(csist) ;
	%plot_phase_offset(csist) ;
	%do_cir(csist) ;
	%save_calib(csist);
	do_aoa(csist) ;
	%stats_macs(csist, false) ;
	%plot_breath(csist) ;
	%do_pdd(csist);
end


function handle_all_csist_func(sts)
	nsts = {} ;
	for i = 1:length(sts)
		%if ~csi_filter(sts{i}); fprintf("*** pass\n"); continue; end
		%if strcmpi(sts{i}.chan_type_str, "HT20")
		if true
			%remove -b, cause dont effect in cir.
			st = sts{i};
			csi1 = squeeze(st.scsi(1,1,:));
			[k, b, csi1] = iaxcsi.fit_csi(csi1, st.subc.subcs);
			st.scsi(1,1,:) = csi1;
			%plot(unwrap(angle(csi1)),'-o'); hold on;
			csi2 = squeeze(st.scsi(2,1,:));
			[k, b, csi2] = iaxcsi.fit_csi(csi2, st.subc.subcs);
			st.scsi(2,1,:) = csi2;
			%plot(10+unwrap(angle(csi2)),'-o'); hold on;
			nsts{end+1} = st;
		end
	end
	sts = nsts;

	%do_pdd_sts(sts);
	do_sfo_sts(sts);
end


function do_pdd_sts(sts)
	sumk = 0;
	ks = [];
	%for i = 1:length(sts)-1
	for i = 1:100
		csi1 = squeeze(sts{i}.scsi(1,1,:));
		%[k, b, csi1] = iaxcsi.fit_csi(csi1, sts{i}.subc.subcs);
		csi2 = squeeze(sts{i+1}.scsi(1,1,:));
		%[k, b, csi2] = iaxcsi.fit_csi(csi2, sts{i}.subc.subcs);
		uwa = unwrap(angle(csi2 .* conj(csi1)).');
		[uwa,k,~] = fit(uwa, sts{i}.subc.subcs);
		figure(41); hold on; set_style(plot(uwa)); title("packet diff");

		ks(end+1) = k;
		figure(42); hold on; set_style(scatter(i, mean(ks))); title("mean");
		figure(43); hold on; set_style(scatter(i, var(ks))); title("var");
		sumk = sumk + k;
		fprintf("* no.%d: k %f, sumk/n %f\n", i, k, sumk/i);
		%pause
	end
	[mean(ks), var(ks)]
end


function do_sfo_sts(sts)
	csis = {};
	csis2 = {};
	for i = 1:length(sts)
		csi = squeeze(sts{i}.scsi(1,1,:));
		csis{end+1} = csi.';
		csi2 = squeeze(sts{i}.scsi(2,1,:));
		csis2{end+1} = csi.';
		if i > 50
			set_style(plot(fit(unwrap(angle(csi).')))); hold on;
		end
	end
	csis = mean_csis(csis, 20);
	csis2 = mean_csis(csis2, 20);
	%for i = 1:length(sts)
	for i = 1:20
		%plot_cir(squeeze(sts{i}.scsi(:,1,:)), sts{1}.chan_width); continue;
		plot_cir(csis{i}, sts{1}.chan_width);
		plot_cir(csis2{i}, sts{1}.chan_width);
	end

	for e = -0.1:0.2/200:0.1
		ee = exp(1j*e);
	end
end


function rcsis = mean_csis(csis, w)
	rcsis = {};
	mags = [];
	angs = [];
	for i = 1:length(csis)
		csi = csis{i};
		mags(end+1,:) = abs(csi);
		angs(end+1,:) = unwrap(angle(csi));
		if i > w
			mag = mean(mags(i-w:i,:));
			ang = mean(angs(i-w:i,:));
			ncsi = mag.*exp(1j*ang);
			set_style(plot(10+fit(unwrap(angle(ncsi).')), '-o')); hold on;
			rcsis{end+1} = ncsi; 
		end
	end
end


function [ys,k,b] = fit(ys, xs)
	if nargin < 2; xs = 1:length(ys); end
	z = polyfit(xs, ys, 1) ;
	k = z(1) ;
	b = z(2) ;
	ys = ys - b;
end


function do_pdd(csist)
	csist
	csi = squeeze(csist.scsi(:,1,:));
	if (false)
		[k, b, csi(1,:)] = iaxcsi.fit_csi(csi(1,:), csist.subc.subcs);
		[k, b, csi(2,:)] = iaxcsi.fit_csi(csi(2,:), csist.subc.subcs);
		uwa = unwrap(angle(csi.'));
		figure(30); plot(uwa); hold on;
		plot_phase_offset(csist);
	end
	%aoa = do_spotfi(csist) 
	csist.scsi(:,1,:) = csi;
	do_cir(csist);
	%amp and phase dont effect cir relative. so noneed fit_csi to -b.
	%csist.scsi(:,1,:) = csi*5*exp(1j*3); plot_cir(csist,25);
	pause
end


function plot_breath(csist)
	persistent h x;
	if isempty(h)
		h = animatedline ;
		h.LineWidth = 2;
		h.LineStyle = '-' ;
		h.Color = '#0072BD'	;
		h.Marker = 'o' ;
		x = 0;
	end

	s = mean(abs(squeeze(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:))))) ;
	addpoints(h, x, s) ;
	x = x + 1;
	xlim([x-180, x+20]);
	%ylim([1, 4]*1e4);
	ylim([0, 3]*1e4);
	%ylim([-1, 5]*1e4);
	pause(0.01) ;
end


function handle_aoa_cdf()
	taoas = [0, 15, 30, 45, 60] ;
	taoas = union(-taoas, taoas) ;
	aoas = [] ;
	ss = [] ;
	calc_aoa = @do_iaa ;
	calc_aoa = @do_spotfi ;
	calc_aoa = @do_music ;

	for i = 1:length(taoas)
		taoa = taoas(i) ;
		csi_file = ['ax210_40ht20_', num2str(taoa), '.csi']
		sts = iaxcsi.static_read_all(csi_file);
		size(sts)
		%ss = sts{1,100:end} 
		%continue;

		n = 0;
		for j = 50:length(sts)-20
			csist = sts{j} ;
			if ~csi_filter(csist); fprintf("*** pass\n"); continue; end

			csist = calib_scsi_by_file(csist) ;
			%plot_phase_offset(csist) ;
			aoa1 = calc_aoa(csist) ;
			csist = calib_scsi_by_phaoff12(csist, pi) ; 
			aoa2 = calc_aoa(csist) ;
			%plot_aoa(aoa1, 11, false); plot_aoa(aoa2, 11, true); 
			aoa = min(abs(aoa1-taoa), abs(aoa2-taoa));
			if aoa > 60 %deg60has
				[aoa1, aoa2, aoa]
				csist
				%continue;
				%input('')
			end
			aoas(end+1) = aoa; 
			n = n + 1;
			if (n >= 100); break; end
		end
		ss(end+1) = n ;
		figure(99); p=cdfplot(aoas); p.LineWidth=2;
		xlim([0, 45]);

		%input('')
	end
	%save('/flqtmp/paper/aoa/aoa_cdf.mat', 'aoas');
	save('aoa_cdf.mat', 'aoas');
	ss

end

function save_calib(csist)
	persistent phaoffs;
	if isempty(phaoffs)
	end
		scsi = squeeze(csist.scsi(:,1,:)) ;
		po = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
		if (mean(po) > 0)
			phaoffs = po;
			%savename = join(['/flqtmp/', csist.chan_type_str, 'phaoffs12.mat'], '')
			savename = join([csist.chan_type_str, 'phaoffs12.mat'], '')
			%save("/flqtmp/phaoffs12.mat", "phaoffs");
			save(savename, "phaoffs");
			input("ok?")
		end
end

function [aoa1, aoa2] = do_aoa(csist)
	persistent aoas;
	calc_aoa = @do_music ;
	calc_aoa = @do_dbf ;
	calc_aoa = @do_iaa ;
	calc_aoa = @do_spotfi ;

	plot_phase_offset(csist) ;
    %csist = calib_scsi_by_delta(csist, 0.0, 0.32) ; 
    csist = calib_scsi_by_file(csist) ;
	plot_phase_offset(csist) ;
	aoa1 = calc_aoa(csist) ;
	%pause
    csist = calib_scsi_by_phaoff12(csist, pi) ; 
	plot_phase_offset(csist) ;
	aoa2 = calc_aoa(csist) ;

	fid = 11;
	ch = char(csist.smac);
	fid = hex2dec(ch(1:2));
	plot_aoa(aoa1, fid, csist.smac, false); 
	plot_aoa(aoa2, fid, csist.smac, true); 
	%pause

	truthaoa = -60 ;
	aoas(end+1) = min(abs(aoa1-truthaoa), abs(aoa2-truthaoa));
	if ~ mod(length(aoas), 50)
		figure(99); p=cdfplot(abs(aoas(end-49:end))); p.LineWidth=2;
		%save(['/flqtmp/aoas', num2str(truthaoa),'.mat'], "aoas");
		save(['aoas', num2str(truthaoa),'.mat'], "aoas");
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
	envs = iaa_envs() ;
	envs.nrx = csist.nrx ;
	envs.ntone = csist.nstone ;
	envs.subcs = csist.subc.subcs ;
	envs.fc = 5.2e9 ;
	envs.d = 0.013 ;
	envs.d = 0.056 ;
	envs.d = 0.026 ;
	envs.f_space = 312.5e3 ;
	envs.fc_space = envs.f_space ;

	%csist = simu_aoa(-pi/3, csist, envs) ;
	csi = squeeze(csist.scsi(:,1,:));
	if false
	csi = csi(:,1:4:end);
	envs.ntone = size(csi,2);
	envs.fc_space = 4*envs.f_space ;
	end
	aoa = iaa(csi, envs)
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


function aoa = do_music(csist)
	%aoa = do_spotfi(csist, true); return;
	envs = music_envs(2) ;
	envs.nrx = csist.nrx ;
	envs.ntx = csist.ntx ;
	envs.ntone = csist.ntone ;
	envs.subcs = csist.subc.subcs ;

	aoa = music(squeeze(csist.scsi(:,1,:)), envs) 
	return ;
end


function aoa = do_dbf(csist)
	st = csist;
	st.csi = squeeze(csist.scsi(:,1,:));
	aoa = dbf(st)
end


function aoa = do_spotfi(csist, music)
	if nargin < 2; music = false; end
	envs = spotfi_envs() ;
	envs.fc = 5.2e9 ;
	envs.lambda = envs.c / envs.fc ;
	envs.d = 0.013 ;
	envs.d = 0.056 ;
	envs.d = 0.026 ;
	envs.nrx = csist.nrx ;
	envs.ntx = csist.ntx ;
	envs.ntone = csist.nstone ;
	envs.ntone_sm = floor(envs.ntone/2) ;
	envs.subc_idxs = csist.subc.subcs ;
	%envs.pmufig = true;
	envs.niter = 1 ;
	envs.music = music ;

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

function plot_aoa(aoa, fid, fig_title, holdon)
	if nargin < 3; fig_title = fid; end
	if nargin < 4; holdon = false; end
	figaoa = 90 - aoa ;
	figure(fid) ;
	if holdon; hold on; else; hold off; end
	c = compass(cosd(figaoa), sind(figaoa)) ;
	c.LineWidth = 6 ;
	if holdon; c.LineWidth=3; end
	axis([-1, 1, 0, 1]) ;
	title(fig_title);
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
	%aks(end+1,:) = abs(csist.scsi(:,1,10)) ;
	aks(end+1,:) = mean(abs(csist.scsi(:,1,10))) ;
	sz = size(aks,1);
	range = max(sz-5,1):sz ;
	hold on; plot(range, aks(range,:), 'LineWidth',2) ;
	xlabel('Packet index');
	ylabel('Magnitude');
	%set(gca,'FontName','Times New Roman','FontSize',10,'LineWidth',2)
	%set(gca,'LineWidth',2)
	pause(0.01)
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
		%savename = join(['/flqtmp/', csist.chan_type_str, 'phaoffs12.mat'], '')
		savename = join([csist.chan_type_str, 'phaoffs12.mat'], '')
		phaoffs = load(savename).phaoffs.';
		%figure(29); plot(phaoffs);
		fprintf("***** load phaoffs %f\n", mean(phaoffs)); %pause;
	end
    csist = calib_scsi_by_phaoffs(csist, phaoffs);
end

function csist = calib_scsi_by_delta(csist, deltak, deltab)
	phaoffs = csist.subc.subcs*deltak + deltab;
	csist = calib_scsi_by_phaoffs(csist, phaoffs.', 0);
	%csist.scsi(2,1,:) =  squeeze(csist.scsi(2,1,:)) .* exp(-1j*delta.') ;
end

function csist = calib_scsi_by_phaoffs(csist, phaoffs, offs)
	if nargin < 3; offs = 0; end
	for i = 1:csist.ntx
		csist.scsi(2,i,:) = squeeze(csist.scsi(2,i,:)) .* exp(-1j*(phaoffs+offs));
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
	[dk, deltab, tones] = iaxcsi.fit_csi(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)), csist.subc.subcs);
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
	[~, gdeltab, ~] = iaxcsi.fit_csi(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)), csist.subc.subcs);
	[gdeltab, goffs, offs]
end


function csist = preprocess(csist)
	for itx = 1:csist.ntx
		for irx = 1:csist.nrx
			subc0 = csist.scsi(irx,itx,ceil(end/2));
			csist.scsi(irx,itx,:) = csist.scsi(irx,itx,:) * conj(subc0);
		end
	end

	return;
    scsi = csist.scsi;
    subcs = csist.subc.subcs;
	calib_type = 2;

	if calib_type == 1
		phaoff12 = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
		fprintf("* prep phaoff12 %f\n", mean(phaoff12))

		%csist = calib_by_last_delta_kb(csist, 3.5) ;
		%csist = calib_by_last_delta_kb(csist, 2.7) ;
		%csist = calib_by_last_delta_kb(csist, pi) ;

		phaoff12 = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
		fprintf("* prep phaoff12 %f\n", mean(phaoff12))
		%return 
	elseif calib_type == 2 
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
		%csist = calib_scsi_by_phaoff12(csist, calib_phaoff, offs) ; return ;
		%init_phaoff12_file = ('/tmp/init_phaoff12.mat') ;
		init_phaoff12_file = ('./VHT160phaoffs12.mat') ;
		if exist(init_phaoff12_file)
			fprintf("* calib by file\n");
			phaoff12 = load(init_phaoff12_file).phaoffs ;
			csist = calib_scsi_by_phaoffs(csist, phaoff12.', offs) ; return ;
		end
	else 
		warning('* error invalid calib_type');
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
	if (csist.ntx < 2); return; end
	%test
	%if (csist.ntx > 1); return; end
	%if (csist.chan_type_str ~= "VHT80"); return; end
	%if (csist.chan_type_str ~= "NOHT20"); return; end
	if (csist.chan_type_str ~= "HT40"); return; end
	%if (csist.smac ~= "90:CC:DF:6C:9E:09"); return; end
	%if (csist.smac ~= "3A:96:C4:F6:C6:5D"); return; end
	%if (csist.smac ~= "56:E7:B5:F7:42:55"); return; end
	samsung_laptop_mac = "90:CC:DF:6C:9E:09";
	%if (csist.smac ~= samsung_laptop_mac); return; end
	iphone_mac = "3A:96:C4:F6:C6:5D";
	ipad_mac = "56:E7:B5:F7:42:55";
	%if (csist.smac ~= ipad_mac); return; end
	if (csist.smac ~= iphone_mac && csist.smac ~= ipad_mac); return; end

	persistent pw1_sum pw2_sum ;
	if isempty(pw1_sum)
		pw1_sum = 0; pw2_sum = 0; 
	end
    pw1 = sum(abs(csist.scsi(1,1,:)).^2)/1e4;
    pw2 = sum(abs(csist.scsi(2,1,:)).^2)/1e4;
	pw1 = sum(abs(csist.scsi(1,1,:)))/1e2 ;
	pw2 = sum(abs(csist.scsi(2,1,:)))/1e2 ;
	[csist.rssi(1), csist.rssi(2), pw1, pw2]
	%pw1_sum = pw1_sum + pw1 ; pw2_sum = pw2_sum + pw2 ;
	%[pw1_sum, pw2_sum]
	%assume rssi1 > rssi2
    %if (abs(pw1-pw2)/min(pw1,pw2) < 0.2); return; end
    %if abs(csist.rssi(1)-csist.rssi(2)) < 3; return; end 
    %if ((pw1-pw2)/min(pw1,pw2) < 0.1); return; end
	fprintf("* check1 ok\n");
    if (csist.rssi(1)-csist.rssi(2)) < 3; return; end 
	fprintf("* check2 ok\n");
    if (csist.rssi(1) <= csist.rssi(2) || pw1 <= pw2); return; end
	fprintf("* check3 ok\n");

	[deltabk, deltab] = iaxcsi.fit_csi(csist.scsi(2,1,:) .* conj(csist.scsi(1,1,:)), csist.subc.subcs);
    %if abs(deltabk) > 0.1; return ; end
    %if abs(deltabk) > 0.05; return ; end

	r = true ;
end

function do_cir(csist, fid)
	if nargin < 2; fid = 15; end
	cfr = squeeze(csist.scsi(:,1,:)) ;
	plot_cir(cfr, csist.chan_width, fid);
end

%cfr = [nrx,ntone]
function plot_cir(cfr, bw, fid)
	if nargin < 3; fid = 15; end
	cir = ifft(cfr, [], 2) ;
	cir = cir(:, 1:min(100,size(cir,2))) ;
	dt = 1e9 / (bw * 1e6) ; %ns
	%xs = (0:size(cir,2)-1)*dt ; 
	%xs = (0:length(cir)-1)*dt ; 
	xs = (1:length(cir))*dt ; 
	[v, i] = max(abs(cir(1,:))) ;
	[111, xs(i), xs(i)*0.3]
	%hold on ; plot(xs, abs(cir), ':o', 'LineWidth', 2) ;
	figure(fid);
	%hold off ; 
	plot(xs, abs(cir(1,:)), '-o', 'LineWidth', 2) ; hold on ; 
	if size(cir,1) > 1
		plot(xs, 0+abs(cir(2,:)), ':o', 'LineWidth', 2) ;
	end
	xlabel('Time(ns)');
	ylabel('Magnitude');
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
	figure(1); hold on;
	%plot((1:csist.ntone)-csist.ntone/2, abs(tones.')-100, '-o', 'LineWidth',2) ; 
	plot(subc.subcs, abs(stones.'), '-o', 'LineWidth',2) ; 
	%input('')
	return;

	plot(subc.subcs, abs(stones(1,:)).', 'LineWidth',2) ; 
	figure(1); hold on;
	plot(subc.subcs, abs(stones(2,:)).', ':o', 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; 
end


function plot_phase_offset(csist)
	persistent phaseoffs
	if isempty(phaseoffs); phaseoffs = [] ; end

	subc = csist.subc ;
	scsi = squeeze(csist.scsi(:,1,:)) ;
	phaoff12 = unwrap(angle( scsi(2,:) .* conj(scsi(1,:)) )) ;  
	avg_phaoff12 = mean(phaoff12);
    while avg_phaoff12 < -pi/2
        avg_phaoff12 = avg_phaoff12 + 2*pi;
        phaoff12 = phaoff12 + 2*pi;
	end
	fprintf("* phaoff12 %f\n", mean(phaoff12))
	%phaseoffs(end+1) = mean(phaoff12) ;
	%phaseoffs(end+1) = phaoff12(1) ;
	%%phaseoffs(end+1,:) = phaoff12 ;
	%fprintf("- %d, %d, 12(%f)\n", i, length(phaseoffs), mean(phaseoffs)) ;
	%Util.plot_realtime1(1, phaseoffs) ;
	fid = 3;
	ch = char(csist.smac);
	fid = hex2dec(ch(1));
	figure(fid); hold on;
	plot(csist.subc.subcs, phaoff12, 'LineWidth',2) ;
	title(csist.smac);
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
	savename = "./iaxcsi.mat" ;
	if reload || ~exist(savename)
		fprintf("* reload %s\n", filename) ;
		sts = iaxcsi.static_read_all(filename, savename) ;
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

	key = st.smac ;
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
	save("iaxcsi_nonht20.mat", 'sts');
	sts = map('448') ;
	save("iaxcsi_ht20.mat", 'sts');
	sts = map('1824') ;
	save("iaxcsi_ht40.mat", 'sts');
	sts = map('3872') ;
	save("iaxcsi_vht80.mat", 'sts');
end



