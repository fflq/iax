
classdef utils < handle

properties (Constant)
end

properties (Access='public')
end

methods (Access='public')
	function self = utils()
	end
end

methods (Static)
	% interp complex num by (mag,phase)
    % data_pilot_dc_tones(xv) = iaxcsi.do_complex_interp(xv, x, data_pilot_dc_tones(x)) ;
	function yv = do_complex_interp(xv, x, y)
		interp_method='linear';
		F = griddedInterpolant(x, abs(y),interp_method) ;
		mag = F(xv) ;
		%no unwrap then yv-unwrap-phase will fluctuate
		%F = griddedInterpolant(x, angle(y),interp_method) ;
		F = griddedInterpolant(x, unwrap(angle(y)),interp_method) ;
		phase = F(xv) ;
		yv = mag.*exp(1j*phase) ;
	end

	function dt = ts_to_dt(ts) 
		ts = double(ts) ;
		dt = datetime(ts, 'ConvertFrom', 'posixtime', 'TimeZone', 'Asia/Shanghai', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') ;
		%dt = string(datestr(dt, 'YYYY-mm-dd HH:MM:ss')) ;
	end

	function r = get_file_len(f)
		fseek(f, 0, 'eof') ;
		r = ftell(f) ;
		fseek(f, 0, 'bof') ;
	end

	function plot_realtime1(fid, data, spec)
		if (nargin < 3)
			spec = 'b--o' ;
		end
		len = length(data) ;
		skip = 2 ;
		if (len > skip)
			figure(fid); hold on ;
			plot(len-skip:len, data(end-skip:end), spec) ;
			drawnow ;
		end
	end

	function print_hexs(buf, dec_fmt)
		if nargin < 2; dec_fmt = false; end
		for i = 1:length(buf)
			pos = i - 1;
			if ~mod(pos, 16)
				fprintf("\n%08d:", pos);
			elseif ~mod(pos, 8)
				fprintf("  ");
			elseif ~mod(pos, 4)
				fprintf(" ");
			end

			if dec_fmt
				fprintf(" %03d", buf(i));
			else
				fprintf(" %02X", buf(i));
			end
		end
		fprintf("\n");
	end

end

end
