
classdef csiutils < handle

properties (Constant)
end

properties (Access='public')
end

methods (Access='public')
	function self = csiutils()
	end
end


methods (Static)

    function plot_aoa(aoa, fid, fig_title, holdon, color)
        if nargin < 2; fid = 15; end
        if nargin < 3; fig_title = "aoa"; end
        if nargin < 4; holdon = false; end
        if nargin < 5; color = 'b'; end
        figaoa = 90 - aoa ;
        figure(fid) ;
        if holdon; hold on; else; hold off; end
        c = compass(cosd(figaoa), sind(figaoa), color) ;
        c.LineWidth = 6 ;
        if holdon; c.LineWidth=3; end
        axis([-1, 1, 0, 1]) ;
        title(fig_title);
		pause(0.001)
    end


    function plot_ppo12(csi, fid, hold_on, spec)
        if nargin < 2; fid = 13; end
        if nargin < 3; hold_on = false; end
        if nargin < 4; spec = "-o"; end
        
        csi = squeeze(csi);
        csiutils.plot_ppo(csi(2,:), csi(1,:), fid, hold_on, spec);
    end

    function plot_ppo(csi1, csi2, fid, hold_on, spec)
        if nargin < 3; fid = 13; end
        if nargin < 4; hold_on = false; end
        if nargin < 5; spec = "-o"; end
        
        if size(fid) == 1
            figure(fid);
        else
            figure(25);
            subplot(fid(1), fid(2), fid(3));
            szw = 600;
            szh = 350;
            sz = get(gcf, 'Position');
            sz(3) = fid(2)*szw;
            sz(4) = fid(1)*szh; 
            set(gcf, 'Position', sz);
        end
        if hold_on;  hold on; end
        ppo = unwrap(angle(squeeze(csi2 .* conj(csi1))));
        plot(ppo, spec);
        %ylim([-pi, pi]*1.2);
		pause(0.0001);
    end


    %{
	    plot_cir(squeeze(csi(1,1,:)), 20, 11);
    %}
    function peak_ts = plot_cir(cfr, bw, fid, spec, hold_off)
        if nargin < 3; fid = 15; end
        if nargin < 4; spec = '-o'; end
        if nargin < 5; hold_off = false; end

        cir = ifft(cfr);
        cir = cir(1:min(35,length(cir))) ;
        dt = 1e9 / (bw * 1e6) ; %ns
        %xs = (0:size(cir,2)-1)*dt ; 
        %xs = (0:length(cir)-1)*dt ; 
        xs = (1:length(cir))*dt ; 
        [maxv, maxi] = max(abs(cir)) ;
        peak_ts = xs(maxi);
        [111, xs(maxi), xs(maxi)*0.3];
        %hold on ; plot(xs, abs(cir), ':o', 'LineWidth', 2) ;
        %hold off ;  
        if fid > 0; figure(fid); end
        if hold_off; 
            hold off; 
        else
            hold on;
        end
        if fid > 0
            plot(xs, abs(cir), spec, 'LineWidth', 2);
        end

        xlabel('Time(ns)');
        ylabel('Magnitude');
    end


    %{
	    plot_cir(squeeze(csi(:,1,:)), 20, 11);
    %}
    function plot_cir_old(cfr, bw, fid)
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

    %{
    	fc = 5.21e9;
	    subc_freq_range = get_subc_freq_range(fc, st.chan_width, length(st.subc.subcs));
    %}
    function [subc_freq_range, fc_idx] = get_subc_freq_range(fc, bw, len, is_he)
        if nargin < 4; is_he = false; end
        fd = 312.5e3;
        if is_he; fd = fd/4; end
        bw = bw * 1e6;
        subc_freq_range = fc - bw/2 : fd : fc + bw/2;
        fc_idx = find(subc_freq_range == fc);
        r = floor(len/2);
        subc_freq_range = subc_freq_range(fc_idx-r:fc_idx+r);
        fc_idx = find(subc_freq_range == fc);
    end

    %{
    %}
    function [k, b, tones] = fit_csi_phase(tones, xs)
		tones = tones(:) ;
		xs = xs(:) ;
		mag = abs(tones) ;
		uwphase = unwrap(angle(tones)) ;
		%xs = 1:length(tones) ;
		z = polyfit(xs, uwphase, 1) ;
		k = z(1) ;
		b = z(2) ;
		%fprintf("* k(%f) b(%f)\n", k, b) ;
		%pha = uwphase - k*xs - b;
		%pha = uwphase - k*xs*0.2; %prev 
		%pha = uwphase - k*xs;
		pha = uwphase - b;
		%plot(xs, pha); hold on;
		%plot(xs, uwphase, ':o'); hold on;
		%plot(xs, unwrap(angle(tones))-b); hold on;
		tones = mag.*exp(1j*pha);
		%plot(xs, unwrap(angle(tones)),':o'); hold on;
	end

end

end
