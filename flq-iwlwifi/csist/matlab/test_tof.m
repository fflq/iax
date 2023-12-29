close all;

addpath("C:/Users/flq/OneDrive/papers/iax/data/paper");
addpath("N:\winhome\2023\data");
addpath("/tmp");
addpath("D:\Data\csi\iax-rx-hop");

%global gs
%gs.subc_freq_range = -10e6:312.5e3:10e6;
%gs.subc_freq_range = 5.2e9:312.5e3:5.22e9;

global sts filename;
sts = {};
filename = "";

use_iax = true;
use_iax = false;
if use_iax
	mat_name = "attack_5m_20spm_130-3400.mat";
	mat_name = "ax210_40vht160_split.mat";
	mat_name = "ax210_40ht20_split.mat";
	%sts = load(mat_name).sts;
	%sts = csietr().convert_from_sts_iax(sts);
	filename = "iax-40vht80vht160-5250.csi";
	filename = "iax-40vht80vht80-5210.csi";
	filename = "/tmp/iax.csi";
	stsa = csietr().read_file(filename, csietr.Type.IAX);
	sts = {};
	for i = 1:length(stsa)
		st = stsa{i};
		if st.chan_type == "HE20"
			sts{end+1} = st;
		end
	end
else
	filename = "in.csi";
	filename = "in2.csi";
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
	filename = "/flqtmp/tof/incsi-64ht40-1000us-7m-splitter.csi";
	filename = "/flqtmp/tof/incsi-64ht40-500us-7m-splitter.csi";
	filename = "/flqtmp/tof/incsi-64ht40-200us-7m-splitter.csi";
	sts = csietr().read_file(filename, csietr.Type.I53);
	sts = reproc_sts_i53(sts);
	sts = sts(10:end);
end

%simu_cir();
do_fc(sts);
%do_pdd(sts);
%do_hk_div_h0(sts);
%do_pll(sts);


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
	st.subcs
	[subc_freq_range, fc_idx] = csiutils.get_subc_freq_range(fc, st.bw, ...
			length(st.subcs), st.protocol==3);
	[fc_idx, length(st.subcs)]
	for i = 11:min(500,length(sts))
		st = sts{i};
		csi = squeeze(st.csi(1,1,:));
		csi2 = squeeze(st.csi(1,2,:));
		%maxis(end+1) = csiutils.plot_cir(csi+csi2, 160, -1);
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


function sts = reproc_sts_i53(sts)
	bw = 40;
	subcs = -58:58;
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
