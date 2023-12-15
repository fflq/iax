close all;

addpath("C:\Users\flq\OneDrive\papers\iax\data\paper");

%global gs
%gs.subc_freq_range = -10e6:312.5e3:10e6;
%gs.subc_freq_range = 5.2e9:312.5e3:5.22e9;

mat_name = "attack_5m_20spm_130-3400.mat";
mat_name = "ax210_40ht20_split.mat";
mat_name = "ax210_40vht160_split.mat";
sts = load(mat_name).sts;

%do_hk_div_h0(sts);
do_pll(sts);


function do_hk_div_h0(sts)
	fc = 5.21e9;
	st = sts{1};
	[subc_freq_range, fc_idx] = get_subc_freq_range(fc, st.chan_width, length(st.subc.subcs));
	for i = 1:length(sts)
		st = sts{i};
		csi = st.scsi;
		%tone = squeeze(csi(1,1,:));
		%plot(st.subc.subcs, unwrap(angle(tone)),':'); hold on;
		% hk/h0 need unwrap first, not final
		uwphase = unwrap(angle(squeeze(csi(1,1,:)))); 
		plot(st.subc.subcs, uwphase,':'); hold on;
		uwphase2 = uwphase - uwphase(fc_idx);
		plot(st.subc.subcs, uwphase2); hold on;
		pause;
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
	subc_freq_range = get_subc_freq_range(fc, st.chan_width, length(st.subc.subcs));

	for i = 1:length(sts)
		scsi = sts{i}.scsi;
		csi = squeeze(scsi(1,1,:));
		csi2 = squeeze(scsi(2,1,:));

		xs = st.subc.subcs; scale = 1;
		xs = subc_freq_range; scale = 1e9;
		%figure(11); plot(xs, unwrap(angle(csi))); hold on;
		[k, b, tones] = iaxcsi.fit_csi(csi, xs);
		[k2, b2, tones2] = iaxcsi.fit_csi(csi2, xs);
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
		figure(11); plot(st.subc.subcs, wrapToPi(b2-b),'-o'); hold on;
		%figure(21); plot(st.subc.subcs, b2-b,'-o'); hold on;
		figure(22); plot(st.subc.subcs, unwrap(angle(csi2 .* conj(csi))),'-o'); hold on;

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


function plot_cir(cfr, bw, fid)
	if nargin < 3; fid = 15; end
	cir = ifft(cfr, [], 2) ;
	cir = cir(:, 1:min(20,size(cir,2))) ;
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


function [subc_freq_range, fc_idx] = get_subc_freq_range(fc, bw, len)
	fd = 312.5e3;
	bw = bw * 1e6;
	subc_freq_range = fc - bw/2 : fd : fc + bw/2;
	fc_idx = find(subc_freq_range == fc);
	r = floor(len/2);
	subc_freq_range = subc_freq_range(fc_idx-r:fc_idx+r);
	fc_idx = find(subc_freq_range == fc);
end

