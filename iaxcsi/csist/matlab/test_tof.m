addpath("C:\Users\flq\OneDrive\papers\iax\data\paper");


subc_freq_range = -10e6:312.5e3:10e6;
subc_freq_range = 5.2e9:312.5e3:5.22e9;

mat_name = "attack_5m_20spm_130-3400.mat";
sts = load(mat_name).sts;
st = sts{1};
csi = st.scsi;
subc_freq_range = subc_freq_range(5:end-4);

%{
mat_name = "st53_pdp.mat";
st = load(mat_name).st;
csi = st.csi;
subc_freq_range = subc_freq_range(16:45);
%}

for i = 1:length(sts)
	csi = sts{i}.scsi;

[k, b, tones] = iaxcsi.fit_csi(squeeze(csi(1,1,:)), subc_freq_range);
[k, b];
subc_freq_range(floor(end/2));
tpdd = b / subc_freq_range(floor(end/2)) / (2*pi);
tall = k / (-2*pi);
ttof = tall - tpdd;
dist = ttof * 3e8;
[k, b]
[tall, tpdd, ttof, dist]
end

%uwphase = unwrap(angle(tones)) ;
%uwphase(15)/(-2*pi*5.2e9)

plot_cir(squeeze(csi(:,1,:)), 20, 11);
%plot_cir(squeeze(csi(1,:,:)), 20, 12);


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

