clear all;
close all;

addpath("C:/Users/flq/OneDrive/papers/iax/data/paper");
addpath("N:\winhome\2023\data");
addpath("/tmp");
addpath("D:\Data\csi\iax-rx-hop");


global recs rs;
%test_hdr_agc(); return;

%global gs
%gs.subc_freq_range = -10e6:312.5e3:10e6;
%gs.subc_freq_range = 5.2e9:312.5e3:5.22e9;

global sts filename;
sts = {};
filename = "";

use_iax = false;
use_iax = true;
if use_iax
	addpath("N:/winhome/data/");
	filename = "attack_5m_20spm_130-3400.mat";
	filename = "ax210_40vht160_split.mat";
	filename = "ax210_40ht20_split.mat";
	filename = "iax-40vht80vht160-5250.csi";
	filename = "iax-40vht80vht80-5210.csi";
	filename = "/tmp/iax.csi";
	filename = "ax210_40ht20_split.mat";
	filename = "/flqtmp/perm/iax-40ht20-500us-sync4-air-ppo.csi";
	filename = "N:/winhome/data/agc/iax-40ht20-hdr256-agc-wireless-wire.csi";
	filename = "ax210_40ht20_split.csi";
	filename = "ax210_40noht_split.csi";
	filename = "ax210_40vht80_split.csi";
	filename = "ax210_40he160_split.csi";
	filename = "ax210_40vht160_split.csi";
	filename = "N:/winhome/data/perm/iax-40ht20-500us-sync4-air-ppo.csi";

	sts = {}; 
	[~,~,ext] = fileparts(filename);
	if strcmpi(ext, ".mat")
		sts = load(filename).sts;
		sts = csietr().convert_from_sts_iax(sts);
	else
		once = true;
		once = false;
		sts = csietr().read_file(filename, csietr.Type.IAX, once);
	end
	sts = reproc_sts_iax(sts);
else
	filename = "in-64ht40-add10m.csi";
	filename = "in-64ht40-add15m.csi";
	filename = "in-64ht40-add-0m-5m-10m-15m.csi";
	filename = "in-64ht40.csi";
	filename = "/flqtmp/tof/incsi-64ht40-100us-7m-splitter-restart2.csi";
	filename = "/flqtmp/tof/incsi-64ht40-100us-7m-splitter.csi";
	filename = "/tmp/in2.csi";
	filename = "/tmp/in.csi";
	filename = "/flqtmp/tof/incsi-64ht40-200us-7m-splitter-restart2.csi";
	filename = "/flqtmp/tof/incsi-64ht40-500us-12m-splitter.csi";
	filename = "/flqtmp/tof/incsi-64ht40-500us-7m-splitter.csi";
	filename = "/flqtmp/tof/incsi-64ht40-1000us-7m-splitter.csi";
	filename = "/flqtmp/tof/incsi-64ht40-200us-7m-splitter.csi";
	filename = "in.csi";
	filename = "in2.csi";
	filename = "in-64ht40-add10m.csi";
	sts = csietr().read_file(filename, csietr.Type.I53);
	sts = reproc_sts_i53(sts);
	sts = sts(10:end);
end


foreach_sts(sts);


function foreach_sts(sts)
	for i = 1:min(100, length(sts))
		st = sts{i};

		csi1 = squeeze(st.csi(1,1,:));
		csi2 = squeeze(st.csi(1,2,:));
		csi3 = squeeze(st.csi(1,end,:));
		pw1 = sum(csi1' * csi1)/1e3;
		pw2 = sum(csi2' * csi2)/1e3;
		pw3 = sum(csi3' * csi3)/1e3;
		%int32([st.perm, st.rssi, pw1, pw2])
		%int32([st.perm, st.rssi, pw1, pw2, pw3])
		%[st.rssi(1)-st.rssi(2), 10*log10(pw1/pw2)]
		%[st.rssi(2)-st.rssi(3), 10*log10(pw2/pw3)]
		%[st.rssi(1)-st.rssi(3), 10*log10(pw1/pw3)]
		
		if st.type == csietr.Type.IAX
			test_perm_iax(st);
		else
			test_perm_i53(st);
		end
		%disp(st); 
		test_ppo(st);
		pause;
	end
end

function sts = reproc_sts_iax(stsa)
	sts = {};
	for i = 1:length(stsa)
		st = stsa{i};
		%if st.chan_type ~= "HE20"; continue; end

		%st.csi(:,:,:) = st.csi(:,st.perm,:);
		%{
		st.perm = [1, 2];
		if (pw1 >= pw2) ~= (st.rssi(1) >= st.rssi(2)) 
			st.perm = [2, 1];
		end
		%}

		sts{end+1} = st;
	end
end

function sts = reproc_sts_i53(sts)
	bw = 40;
	subcs = -58:58;
	subcs = -58:4:58;
	%phaoffs12 = load('phaoffs').phaoffs12;
    for i = 1:length(sts)
        st = sts{i};
        st.bw = bw;
        old_subcs = subcs(1):4:subcs(end);
        st.subcs = subcs;
		csi = zeros(st.ntx, st.nrx, length(subcs));
		for i = 1:st.ntx
			for j = 1:st.nrx
				csi(i,j,:) = utils.do_complex_interp(st.subcs, old_subcs, squeeze(st.csi(i,j,:)));
			end
			%calib
			%csi(i,1,:) = squeeze(csi(i,1,:)) .* exp(1j*phaoffs12);
		end
		st.csi = csi;
		%plot(abs(squeeze(st.csi(1,1,:))), '-o'); hold on;
        sts{i} = st;
    end
end

function test_perm_iax(st)
	%ppos = unwrap(angle(csi2 .* conj(csi)));
	%[k, b, ~] = csiutils.fit_csi_phase(ppos, st.subcs);
	%[k, b, mean(ppos)]
	%[st.rssi(1), st.rssi(2), pw1, pw2]
	%if st.perm(1) == 2; pause; end

	st = st.dbg;
	hdr_buf = st.hdr_buf;
	subcs = st.subc.idx_data_pilot_dc_subcs ;
	subcs = st.subc.idx_data_subcs  ;
	csi = st.scsi;
	csi = st.scsi(:,:,subcs);
	utils.print_hexs(hdr_buf, true);

	csi1 = squeeze(csi(1,1,:));
	csi2 = squeeze(csi(2,1,:));
	pw1 = sum(power(abs(csi(1,1,:)), 2))/1e4 ;
	pw2 = sum(power(abs(csi(2,1,:)), 2))/1e4 ;
	[111, st.rssi(1), st.rssi(2), pw1, pw2]

	ppos = unwrap(angle(csi2 .* conj(csi1)));
	z = polyfit(1:length(ppos), ppos, 1) ;
	[z(1), z(2), mean(ppos)]

	%figure(21); hold on; plot(ppos,'-o'); 
	%figure(22); hold off; plot(abs(csi1),'r-o'); hold on; plot(abs(csi2),'b-o');

	global recs;
	if isempty(recs); recs = []; end
	recs(end+1,:) = ([st.rssi(1), st.rssi(2), pw1, pw2, hdr_buf(241:256)]);
	recs(end+1,:) = ([0, z(1), z(2), mean(ppos), hdr_buf(257:272)]);
	save("recs.mat", "recs");

	dr1 = hdr_buf(7+256) - hdr_buf(5+256);
	dr2 = hdr_buf(11+256) - hdr_buf(9+256);
	dr3 = dr1 + dr2;
	fprintf("%d  %d  %d\n", dr1, dr2, dr3);

	if (pw1 >= pw2) ~= (st.rssi(1) >= st.rssi(2)) %no
		st.perm = [2, 1];
		st
		pause
	end

end

function test_perm_i53(st)
	csi = st.csi;

	%before_perm_csi = csi(:,st.perm,:);
	%csi = csi(:,st.perm,:);
	%test_ppo2(squeeze(csi(1,1,:)), squeeze(csi(1,2,:)));

	csi1 = squeeze(csi(1,1,:));
	csi2 = squeeze(csi(1,2,:));
	csi3 = squeeze(csi(1,end,:));
	pw1 = sum(csi1' * csi1)/1e1;
	pw2 = sum(csi2' * csi2)/1e1;
	pw3 = sum(csi3' * csi3)/1e1;
	[pw1, pw2, pw3]
	[v, fperm] = sort([pw1, pw2, pw3], 'descend');
	%倒推perm而不是fw提供需要rssi不模糊
	csi = csi(:,fperm,:);
	%test_ppo2(squeeze(csi(1,1,:)), squeeze(csi(1,2,:)));
	st.perm
	fperm
	if ~all(st.perm == fperm)
		warning('* not equal');
	end
end

function test_ppo(st)
	csi1 = squeeze(st.csi(1,1,:));
	csi2 = squeeze(st.csi(1,2,:));
	test_ppo2(csi1, csi2);
end

function test_ppo2(csi1, csi2)
	ppos = unwrap(angle(csi2 .* conj(csi1)));
	figure(13); hold on; plot(ppos, '-o'); 
end

function test_hdr_agc()
	global recs rs;
	n = 0;
	%if isempty(recs); recs = []; end
	recs = load("recs.mat").recs;
	rs = [];
	for i = 1:2:length(recs)
		rec1 = recs(i,:);
		rec2 = recs(i+1,:);
		%if abs(rec1(3) - rec1(4)) < 20; continue; end
		%if abs(rec1(3) - rec1(4)) > 50; continue; end

		r1 = rec1(2+4) + rec1(9+4) + rec2(5+4) + rec2(9+4);
		r1 = rec1(2+4) + rec2(5+4) + rec2(9+4);
		r2 = rec1(6+4) + rec1(13+4) + rec2(9+4) + rec2(13+4);
		r2 = rec1(6+4) + rec2(9+4) + rec2(13+4);
		dr1 = rec2(7+4) - rec2(5+4);
		dr2 = rec2(11+4) - rec2(9+4);
		dr3 = dr1 + dr2;
		%if dr3 < 39; continue; end
		fprintf("%d  %d  %d  %d  %d\n", r1, r2, dr1, dr2, dr3);
		rs(end+1,:) = [rec1(1), rec1(2), rec1(3), rec1(4), dr1, dr2, dr3];

		rec = rec1;
		fprintf("%d  %d  %.1f  %.1f\t\t", rec(1), rec(2), rec(3), rec(4));
		for j = 5:length(rec); 
			fprintf("%03d ", rec(j)); 
			if ~mod(j,4); fprintf(" "); end
		end
		fprintf("\n");

		rec = rec2;
		fprintf("%d  %.4f  %.1f  %.1f\t\t", rec(1), rec(2), rec(3), rec(4));
		for j = 5:length(rec); 
			fprintf("%03d ", rec(j)); 
			if ~mod(j,4); fprintf(" "); end
		end
		fprintf("\n\n");

		n = n + 1;
	end
	n
	rs
	save("rs.mat", "rs");
end




%inherit
%test_pdd_us(sts);
%test_adj_macs(sts);
%simu_cir();
%do_fc(sts);
%do_pdd(sts);
%do_hk_div_h0(sts);
%do_pll(sts);


function test_pdd_us(sts)
	pdd_tss = [];
	uss = [];
	for i = 1:length(sts)
		st = sts{i};
		csi = squeeze(st.csi(1,1,:));
		pdd_ts = csiutils.plot_cir(csi, st.bw, -1);
		pdd_tss(end+1) = pdd_ts;
		uss(end+1) = st.us;
	end
	adj_us_offs = uss(2:end) - uss(1:end-1);
	adj_pdd_ts_offs = pdd_tss(2:end) - pdd_tss(1:end-1);
	fidxs = find(abs(adj_us_offs) < 1000);
	[length(adj_pdd_ts_offs), length(fidxs)]
	adj_pdd_ts_offs = adj_pdd_ts_offs(fidxs);
	mean(adj_pdd_ts_offs)
	figure(12); hold on; plot(adj_pdd_ts_offs, '-o'); 
end


function test_adj_macs(sts)
	last_st = sts{1};
	for i = 2:length(sts)
		st = sts{i};
		if ~strcmpi(last_st.smac, st.smac)
			st
			last_st
			st_ts = csiutils.plot_cir(squeeze(st.csi(1,1,:)), st.bw, 11, '-o', true);
			last_st_ts = csiutils.plot_cir(squeeze(last_st.csi(1,1,:)), last_st.bw, 12, '-*', true);
			ts_off = st_ts - last_st_ts;
			[int32(st.us - last_st.us), st_ts, last_st_ts, ts_off, ts_off*0.3]
			pause;
		end
		last_st = st;
	end
end


function simu_cir()
	fc = 5.21e9;
	fd = 3.125e5; 
	bw = 160;
	bw = 320;
	%bw = fd*20/1e6;
	len = 64*(bw/20)+1;
	[fks, fc_idx] = csiutils.get_subc_freq_range(fc, bw, len);
	fks = 5.2e9:fd:5.2e9+(len-1)*fd;
	csi = zeros(1, len);
	tau = 10e-9; csi = csi + exp(-1j*2*pi*fks*tau);
	tau = 50e-9; csi = csi + exp(-1j*2*pi*fks*tau);
	tau = 100e-9; csi = csi + exp(-1j*2*pi*fks*tau);
    ds = 1e9 / (bw * 1e6) ; %ns
	csiutils.plot_cir(csi, bw);
end


function do_fc(sts)
	global sts filename;
	subcs0 = [];
	uss = [];
	maxis = [];
	fc = 5.25e9;
	fc = 5.21e9;
	st = sts{10};
	if st.us > 1e10
		%error("* error st.us(%f)\n", st.us);
	end
	[subc_freq_range, fc_idx] = csiutils.get_subc_freq_range(fc, st.bw, ...
			length(st.subcs), st.protocol==3);
	[fc_idx, length(st.subcs)]
	for i = 11:min(500,length(sts))
		st = sts{i};
		csi = squeeze(st.csi(1,1,:));
		csi2 = squeeze(st.csi(1,2,:));
		maxis(end+1) = csiutils.plot_cir(csi+csi2, st.bw, 21);
		pause;
		pw1 = sum(abs(csi))/1e3;
		pw2 = sum(abs(csi2))/1e3;
		[st.rssi(1), st.rssi(2), pw1, pw2]
		st
		if (st.rssi(1) > st.rssi(2)) ~= (pw1 > pw2)
			%pause;
		end
		%subcs0(end+1,:) = [csi(fc_idx), csi2(fc_idx)];
		subcs0(end+1,:) = [csi(fc_idx)+csi2(fc_idx), csi2(fc_idx)];
		uss(end+1) = st.us;

		%figure(11); plot(unwrap(angle(csi)), '-o'); hold on;
		phaoffs12 = unwrap(angle(csi2 .* conj(csi)));
		%figure(12); plot(phaoffs12, '-o'); hold on; %phaoff=3
		z = polyfit(st.subcs, phaoffs12, 1);
		%pause
	end
	mean(phaoffs12)
	size(subcs0)
	%return;

	us_offs = uss(2:end) - uss(1:end-1);
	idxs = 1:length(us_offs);
	idxs = find(us_offs == 200);
	%idxs = find(abs(us_offs-1000) < 10);
	us_offs = us_offs(idxs);
	figure(13); plot(us_offs, '-*'); hold on; grid on; title("adj pac us offs");
	figure(31); plot(normalize(us_offs), 'm:*'); hold on; grid on;
	%maxis = maxis(idxs);
	%figure(15); plot(normalize(maxis), 'c:*'); hold on; grid on;
	figure(15); plot(maxis, 'c:*'); hold on; grid on;
	return ;

	%figure(21); plot(abs(subcs0), '-o'); hold on;
	%figure(22); plot(wrapToPi(angle(subcs0)), '-o'); hold on; title("s0 pha");

	%pac_ho_phaoffs1 = wrapToPi(angle(subcs0(2:end,1) .* conj(subcs0(1:end-1,1))));
	pac_fc_phaoffs = angle(subcs0(2:end,:) .* conj(subcs0(1:end-1,:)));
	pac_fc_phaoffs = pac_fc_phaoffs(idxs,:);
	pac_fc_phaoffs = wrapToPi(pac_fc_phaoffs);
	midx = (find(pac_fc_phaoffs < pi/2));
	pac_fc_phaoffs(midx) = pac_fc_phaoffs(midx) + pi;
	figure(32); plot(pac_fc_phaoffs(:,1), 'bo'); hold on;
	figure(31); plot(pac_fc_phaoffs(:,1), 'b:o'); hold on;
	%figure(31); plot(pac_fc_phaoffs(:,2), 'r:x'); hold on;
	plot_title = sprintf("incsi adj pac s0 phaoffs and us-offs-norm,\n %s",filename);
	title(plot_title);

	fcfos = pac_fc_phaoffs/(-2*pi)/2e-4;
	figure(33); plot(fcfos(:,1), '-o'); hold on;

	ns_offs1 = 1e9* pac_fc_phaoffs / (2*pi) / 1e5;
	%figure(41); plot(ns_offs1, 'b-o'); hold on;
end


function do_pdd(sts)
	st = sts{1};
	s = [];

	fc = 5.21e9;
	fc = 5.31e9;
	[subc_freq_range, fc_idx] = csiutils.get_subc_freq_range(fc, st.bw, length(st.subcs));
	xs = subc_freq_range; scale = 1e9; use_fk = true;%b will with pdd, so random
	xs = st.subcs; scale = 1; use_fk = false;%b no pdd but tof

	csi = squeeze(st.csi(1,1,:));
	csi2 = squeeze(st.csi(1,2,:));
	[k, b, tones] = csiutils.fit_csi(csi, xs);
	firstb = b;
	%fc_idx = 1:length(xs); % better effect
	last_phase = angle(csi(fc_idx)); last_phase2 = angle(csi2(fc_idx));
	[last_phase, last_phase2];
	for i = 2:5:length(sts)
		i
		scsi = sts{i}.csi;
		csi = squeeze(scsi(1,1,:));
		csi2 = squeeze(scsi(1,2,:));
		[k, b, tones] = csiutils.fit_csi(csi, xs);
		[k2, b2, tones2] = csiutils.fit_csi(csi2, xs);
		[k*scale, b, k2*scale, b2]

		%s = [s, wrapToPi(b - last_phase)];
		s = [s, wrapToPi(angle(csi(fc_idx)) - last_phase)];
		utils.plot_realtime1(13, (s));

		cur_phase = angle(csi(fc_idx));
		cur_phase2 = angle(csi2(fc_idx));
		%csi = csi .* exp(-1j*last_phase);
		%csi2 = csi2 .* exp(-1j*last_phase2);
		last_phase = cur_phase; last_phase2 = cur_phase2;
		mean(wrapToPi(last_phase2-last_phase))

		%csiutils.plot_cir(csi, 40, 12, 'b-o');
		off_to_first_pdd = -(b - firstb) / (-2*pi) / fc;
		off_to_first_pdd
		csi = csi .* conj(exp(-1j*2*pi*xs*off_to_first_pdd).');
		%csi = csi .* exp(-1j*2*pi*xs.'*50e-9*i); %move i*20ns
		%csiutils.plot_cir(5*csi, 40, 12, 'r-o');

		phaoffs12 = unwrap(angle(csi2 .* conj(csi)));
		%save("phaoffs.mat", "phaoffs12"); %save calib
		%figure(22); plot(st.subcs, phaoffs12,'-o'); hold on;

		%验证截距b
		%xs = 0:312.5e3:fc; ys = k*xs + b; plot(xs, ys,'-.'); hold on;

		tall = 0; tpdd = 0;
		if use_fk
			%when xs == freq_range
			tpdd = b / (2*pi) / fc;
			tall = k / (-2*pi);
			ttof = tall - tpdd;
		else
			%when xs == subcs
			ttof = b / (-2*pi) / fc;
		end
		dist = ttof * 2e8;
		%[k*scale, b];
		[tall*1e9, tpdd*1e9, ttof*1e9, dist]

		pause;
	end		
end

function plot_phaoff(sts)
	for i = 1:length(sts)
		st = sts{i};

	end
end

function do_pll(sts)
	st = sts{1};

	%{
	mat_name = "st53_pdp.mat";
	st = load(mat_name).st;
	csi = st.csi;
	subc_freq_range = subc_freq_range(16:45);
	%}
	fc = 5.21e9;
	fc = 5.31e9;
	[subc_freq_range, fc_idx] = csiutils.get_subc_freq_range(fc, st.bw, length(st.subcs));
	s = [];
	s1 = [];
	s2 = [];

	for i = 1:length(sts)
		scsi = sts{i}.csi;
		csi = squeeze(scsi(1,1,:));
		csi2 = squeeze(scsi(1,2,:));

		xs = subc_freq_range; scale = 1e9;
		xs = st.subcs; scale = 1;
		%figure(11); plot(xs, unwrap(angle(csi))); hold on;
		[k, b, tones] = csiutils.fit_csi(csi, xs);
		[k2, b2, tones2] = csiutils.fit_csi(csi2, xs);
		[k*scale, b, k2*scale, b2]
		%xs=subcs时能看到线交织在(0,0), 而subc_freq_range时线分散, 但实际上是一样的(0,0), 只是x太大而已
		%figure(12); plot(xs, unwrap(angle(tones))); hold on;

		%验证rx1rx2的斜率是否相同，对应tof，结果是相同的. 截距b不同仅仅是因为pll
		%figure(31); hold off; plot(xs, unwrap(angle(tones))); 
		%figure(31); hold on; plot(xs, unwrap(angle(tones2)),'-.'); 
		%pause; continue;

		%验证fig11的delta-b ?= fig12的delta-pll为两个值，间隔pi. 结果不是
		%pha_k = fk*(tsfo+tpdd+tof) + pha_pll - fc(tsfo+tpdd) = x*k + b, 略去-2pi.
		%功分两天线没有delta_tof, delta_b = delta_pha_pll, 应该fig11 == fig12啊
		%用wrapToPi乱在一起, 不用的话, 在[-100,100]间聚集在两三处有点像, 但是分散度达10
		%上面是xs=range时不成立, 而在xs=subcs时fig11==fig12成立了, 但是b只有几十，前者有几千
		%figure(11); plot(xs, wrapToPi(b2-b),'-o'); hold on;
		%figure(21); plot(st.subc.subcs, b2-b,'-o'); hold on;
		%figure(22); plot(xs, unwrap(angle(csi2 .* conj(csi))),'-o'); hold on;

		%验证pha_pll是否动态变化(仅delta_pha_pll半不变), yes
		%figure(12); plot(xs, wrapToPi(b+b2),'-o'); hold on;
		%figure(12); plot(xs, wrapToPi(b),'-.'); hold on;
		%figure(12); plot(xs, wrapToPi(b2),'-o'); hold on;
		%s = [s, wrapToPi(b+b2)];
		%fc_idx = 1;
		s = [s, wrapToPi(b - angle(csi(fc_idx)))];
		s1 = [s1, wrapToPi(b)];
		s2 = [s2, 1+wrapToPi(angle(csi(fc_idx)))];
		%s2 = [s2, wrapToPi(b2)];
		utils.plot_realtime1(12, unwrap(s1));
		utils.plot_realtime1(12, unwrap(s2), 'r--o');
		utils.plot_realtime1(22, unwrap(s), 'k--o');
		title("* pll add");

		%验证截距b
		%xs = 0:312.5e3:fc; ys = k*xs + b; plot(xs, ys,'-.'); hold on;

		%when xs == freq_range
		tpdd = b / (2*pi) / fc;
		tall = k / (-2*pi);
		ttof = tall - tpdd;
		%when xs == subcs
		%ttof = b / (-2*pi) / fc;
		dist = ttof * 3e8;
		[k*scale, b]
		[tall*scale, tpdd*scale, ttof*1e9, dist]
		pause;
	end

	%uwphase = unwrap(angle(tones)) ;
	%uwphase(15)/(-2*pi*5.2e9)

	%plot_cir(squeeze(csi(:,1,:)), 20, 11);
	%plot_cir(squeeze(csi(1,:,:)), 20, 12);
end
