%{
libs: file_handler, socket_handler, endian, csiutils, csi_handler_base
%}

classdef iaxcsi < csi_handler_base

properties (Access='public')
end

methods (Access='public')
	function self = iaxcsi(input_name)
		self@csi_handler_base(input_name);
	end

	function delete(self)
		%warning("** iaxcsi");
	end

	function st = read_next(self)
		st = []; len = 0;
			msg_len = endian.be32i(self.io_handler.read(4));
			if isempty(msg_len); return ; end

			msg = self.io_handler.read(msg_len);
			st = self.read_st(msg) ;

			len = 4 + msg_len ;
		try
		catch ME
			ME.identifier
		end
	end

	function st = read_st(self, buf)
		pos = 1 ;
		st = [] ;

			hdr_len = endian.be32u(buf(pos:pos+3)); pos = pos + 4;
			if (hdr_len ~= 272)
				warning("* err hdr_len %d!=272, skip\n", hdr_len) ;
				return ;
			end
			hdr_buf = buf(pos:pos+hdr_len-1); pos = pos + hdr_len ;

			hdr_st = iaxcsi.get_csi_hdr_st(hdr_buf) ; 
			rnf_st = iaxcsi.get_rnf_st(hdr_st.rnf) ;
			%utils.print_hexs(hdr_buf, true);

			csi_len = endian.be32u(buf(pos:pos+3)); pos = pos + 4 ;
			csi_buf = buf(pos:pos+csi_len-1); pos = pos + csi_len ;

			csi = iaxcsi.get_csi(csi_buf, hdr_st) ;

			%[hdr_len, csi_len, 111111, hdr_st.csi_len, hdr_st.ntone] 
			st = iaxcsi.fill_csist(hdr_st, rnf_st, csi) ;  
			if self.debug
				st.hdr_buf = hdr_buf;
			end
		try
		catch ME
			ME.identifier
		end
	end

end

methods (Static)

	function st = sread_next(input_name, save_name)
		if (nargin < 2); save_name = '' ; end
		st = iaxcsi(input_name).read_next(save_name);
	end

	function sts = sread(input_name, save_name)
		if (nargin < 2); save_name = '' ; end
		sts = iaxcsi(input_name).read(save_name);
	end

	function test_st(st)
		st
		subc = st.subc ;
		tones = squeeze(st.csi(1,1,:)) ;
		stones = squeeze(st.scsi(1,1,:)) ;

		title(st.mod_bw_type);
		plot(subc.subcs, abs(stones), 'LineWidth',2) ; hold on;
		plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; hold on;
		pause;
	end

	function st = fill_csist(hdr_st, rnf_st, csi)
		st = struct() ;
		st = hdr_st ; %fflqtest

		st.smac = hdr_st.smac ;
		st.seq = hdr_st.seq ;
		st.us = hdr_st.us ;
		%st.ftm = hdr_st.ftm ;
		st.timestamp = hdr_st.timestamp/1e9;
		st.datetime = utils.ts_to_dt(st.timestamp);

		st.rnf = dec2hex(hdr_st.rnf) ;
		st.bandwidth = rnf_st.bandwidth ;
		st.mod_type = rnf_st.mod_type ;
		st.mod_bw_type = rnf_st.mod_bw_type ;
		%st.ant_sel = rnf_st.ant_sel ;
		%st.ldpc = rnf_st.ldpc ;

		st.channel = hdr_st.channel ;
		st.rssi = [hdr_st.rssi1, hdr_st.rssi2] ;
		st.nrx = hdr_st.nrx ;
		st.ntx = hdr_st.ntx ;
		st.ntone = hdr_st.ntone ;
		st.csi_len = hdr_st.csi_len ;
		st.csi = csi ;
		st.perm = 1:st.nrx;

		st = iaxcsi.calib_csi_subcs(st) ;
		%st = iaxcsi.calib_csi_perm(st) ; %call by hand
	end

	function st = calib_csi_perm_ppo_qtr_lambda(st, plus_ppos, do_plot)
		if nargin < 3; do_plot = false; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,1]); end

		st = iaxcsi.calib_csi_perm(st);
		if ~iaxcsi.is_calib_perm_valid(st); return; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,2]); end

		st = iaxcsi.calib_csi_dppo_qtr_lambda(st, plus_ppos);
		if ~iaxcsi.is_calib_dppo_valid(st); return; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,3]); end
	end

	function st = calib_csi_perm_ppo(st, plus_ppos, do_plot)
		if nargin < 3; do_plot = false; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,1]); end

		st = iaxcsi.calib_csi_perm(st);
		if ~iaxcsi.is_calib_perm_valid(st); return; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,2]); end

		st = iaxcsi.calib_csi_ppo(st, plus_ppos);
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,3]); end
	end

	function r = is_calib_perm_valid(st)
		r = ~isfield(st, "permw") || st.permw >= 0.2;
		if ~r; warning("permw=%f\n", st.permw); end
	end

	function r = is_calib_dppo_valid(st)
		r = ~isfield(st, "dppow") || st.dppow >= 0.2;
		if ~r; warning("dppow=%f\n", st.dppow); end
	end

	function r = is_calib_valid(st)
		r = iaxcsi.is_calib_perm_valid(st) && iaxcsi.is_calib_dppo_valid(st);
	end

	%convert [k,b] to ppos
	function r_ppos = convert_from_ppos(st, ppos)
		if length(ppos) == 2
			ppos_kb = ppos;
			r_ppos = ppos_kb(1)*st.subc.subcs + ppos_kb(2);
		else
			r_ppos = ppos;
		end
		if isrow(r_ppos); r_ppos = r_ppos.'; end
		%[ppo1,ppo2] => [exp(1j*ppo1),exp(1j*ppo2)]
		%complex avoid 0 value
		if isreal(r_ppos); r_ppos = complex(exp(1j*r_ppos)); end
	end

	%ppos or [k,b]
	function st = calib_csi_ppo(st, plus_ppos)
		if st.nrx < 2
			return;
		end

		plus_ppos = iaxcsi.convert_from_ppos(st, plus_ppos);

		for i = 1:st.ntx
			st.scsi(2,i,:) = squeeze(st.scsi(2,i,:)) .* conj(plus_ppos);
			%st.csi(2,i,:) = squeeze(st.csi(2,i,:)) .* conj(plus_ppos);
		end
	end

	%ppos or [k,b]
	function [st, w] = calib_csi_dppo_qtr_lambda(st, plus_ppos)
		st.dppow = 0;

		if st.nrx < 2
			st.dppow = 1;
			return;
		end

		plus_ppos = iaxcsi.convert_from_ppos(st, plus_ppos);

		%judge ppo12 by subc0
		csi1 = squeeze(st.scsi(1,1,:));
		csi2 = squeeze(st.scsi(2,1,:));
		subc0_idx = find(st.subc.subcs == 0);
		subc0_po = angle(csi2(subc0_idx) .* conj(csi1(subc0_idx)));
		po_to_ppo = wrapToPi(subc0_po - angle(plus_ppos(subc0_idx)));

		%judge if hop pi under qtr lambda ant dist
		is_hop_pi = false;
		if abs(po_to_ppo) > pi/2
			warning("** abs(po_to_ppo(%.2f)) > pi/2, hop pi\n", po_to_ppo);
			is_hop_pi = true;
		end
		%calc dppo right weight, maxw for 0 or pi, for [-pi/2,pi/2], [pi/2,3pi/2]
		w = 1 - abs(wrapToPi(po_to_ppo - double(is_hop_pi)*pi)) / (pi/2);
		st.dppow = w;

		%minus pi
		%wrong, need calib plus_ppos first, then judge extra pi.
		dppo_ppos = plus_ppos * exp(-1j*double(is_hop_pi)*pi); 
		%complex avoid 0 value
		st = iaxcsi.calib_csi_ppo(st, complex(dppo_ppos));
	end

	function st = perm_csi(st, new_perm)
		if st.nrx < 2
			warning("* nrx < 2");
			return;
		end
		st.perm = new_perm;
		st.scsi(:,:,:) = st.scsi(st.perm,:,:) ;
		%st.csi(:,:,:) = st.csi(st.perm,:,:) ;
	end

	function st = calib_csi_perm(st)
		st.perm = [1, 2] ;
		st.permw = 0;
		if st.nrx < 2
			st.perm = [1];
			st.permw = 1;
			return;
		end

		if abs(st.rssi(1) - st.rssi(2)) < 2
			fprintf("* cannot perm, skip\n");
			st.permw = 0;
			return;
		end

		st.permw = min(1, abs(st.rssi(1) - st.rssi(2))/10);
		is_perm21 = st.rssi(1) < st.rssi(2);
		if is_perm21 && all(st.perm == [1,2])
			warning("** perm21");
			st = iaxcsi.perm_csi(st, [2,1]);
		end

		csi = squeeze(st.scsi(1,1,:));
		csi2 = squeeze(st.scsi(2,1,:));
		pw1 = sum(power(abs(st.csi(1,1,:)), 2))/1e4 ;
		pw2 = sum(power(abs(st.csi(2,1,:)), 2))/1e4 ;
		[99, st.rssi(1), st.rssi(2), pw1, pw2, st.perm(1), st.perm(2)]

		return;

		if (pw1 >= pw2) ~= (st.rssi(1) >= st.rssi(2)) 
			st = iaxcsi.perm_csi(st, [2,1]);
		end
	end

	% interp complex num by (mag,phase)
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

	% raw_csi only data_subcs+pilot_subcs, need add dc_subcs, then interp pilot_dc_subcs
	% eg. csi={-28:-1,1:28}, pilot{-21,-7,7,21} in csi is nan, dc{0} not in csi
	function st = calib_csi_subcs(st)
		% handle special
		if strcmp(st.mod_bw_type, "VHT160") 
			st.csi = st.csi(:,:,subcarrier.get_vht160_noextra_subc(st.ntone));
			st.ntone = size(st.csi, 3) ;
		elseif strcmp(st.mod_bw_type, "HE160")
			st.csi = st.csi(:,:,subcarrier.get_he160_noextra_subc(st.ntone));
			st.ntone = size(st.csi, 3) ;
		end

		subc = subcarrier.get_subc(st.mod_bw_type) ;
		scsi = zeros(st.nrx, st.ntx, subc.subcs_len) ; % add for dc
		data_pilot_dc_tones = zeros(1, subc.subcs_len) ;

		for irx = 1:st.nrx; for itx = 1:st.ntx; 
			data_pilot_dc_tones = 0;
			csi_data_pilot_tones = squeeze(st.csi(irx, itx, :)) ;
			data_pilot_dc_tones(subc.idx_data_pilot_subcs) = csi_data_pilot_tones ; 
			%figure(51);hold on; plot(subc.subcs, abs(data_pilot_dc_tones), '-o');

			% for raw_csi, only data_tones valid
			x = subc.idx_data_subcs ;
			xv = subc.idx_pilot_dc_subcs ;
			data_pilot_dc_tones(xv) = iaxcsi.do_complex_interp(xv, x, data_pilot_dc_tones(x)) ;
			scsi(irx,itx,:) = data_pilot_dc_tones ;
		end; end;
		
		st.scsi = scsi ;
		st.subc = subc ;
		st.nstone = length(subc.subcs) ;
	end

	function [type, val] = get_rate_mcs_fmt_val(pos, msk_base, vals, rnf)
		msk = bitshift(msk_base, pos) ; 
		fmt_type = bitand(rnf, msk) ;
		type = bitshift(fmt_type, -pos) ; 
		val = vals(type+1) ;
	end

	function rnf_st = get_rnf_st(rnf)
		rnf_st = struct() ;

        % Bits 3-0: MCS
        %rnf_st.mcs = RATE_HT_MCS_INDEX(rnf & RATE_MCS_CODE_MSK)

		%Bits 10-8: mod type
		persistent mod_type_strs ;
		if isempty(mod_type_strs)
			mod_type_strs = ["CCK", "NOHT", "HT", "VHT", "HE", "EH"] ;
		end
		[mod_type, rnf_st.mod_type] = iaxcsi.get_rate_mcs_fmt_val(8, 7, mod_type_strs, rnf) ;  

		%Bits 24-23: HE type
		persistent he_type_strs ;
		if mod_type == 4+1 && isempty(he_type_strs)
			he_type_strs = ["HE-SU", "HE-EXT-SU", "HE-MU", "HE-TRIG"] ;
		end
		if (mod_type == 4+1) 
			[~, rnf_st.mod_type] = iaxcsi.get_rate_mcs_fmt_val(23, 3, he_type_strs, rnf) ;
		end

		%Bits 13-11: chan width
		persistent chan_width_vals ;
		if isempty(chan_width_vals)
			chan_width_vals = [20, 40, 80, 160, 320] ;
		end
		[~, rnf_st.bandwidth] = iaxcsi.get_rate_mcs_fmt_val(11, 7, chan_width_vals, rnf) ;
		if strcmpi(rnf_st.mod_type, "NOHT")
			rnf_st.bandwidth = 20 ;
		end

		rnf_st.mod_bw_type = strcat(rnf_st.mod_type, num2str(rnf_st.bandwidth)) ;

		%Bits 15-14: ant sel
		ant_sel_vals = 0:3 ;
		rnf_st.ant_sel = iaxcsi.get_rate_mcs_fmt_val(14, 3, ant_sel_vals, rnf) ;

		%Bits 16
		rnf_st.ldpc = rnf & bitshift(1, 16) ;
	end

	function hdr_st = get_csi_hdr_st(hdr_buf) 
		hdr_st = struct() ;
		hdr_st.buf = hdr_buf;

		hdr_st.csi_len = endian.le32u(hdr_buf(1:4)) ; 
		hdr_st.ftm = uint32(endian.le32u(hdr_buf(9:12))) ;
		hdr_st.nrx = double(hdr_buf(47)) ;
		hdr_st.ntx = double(hdr_buf(48)) ;
		hdr_st.ntone = double(endian.le32u(hdr_buf(53:56))) ;
		hdr_st.rssi1 = -double(hdr_buf(61)) ;
		hdr_st.rssi2 = -double(hdr_buf(65)) ;
		hdr_st.smac = join(string(dec2hex(hdr_buf(69:74))),':') ;
		hdr_st.seq = hdr_buf(77) ;
		hdr_st.us = uint64(endian.le32u(hdr_buf(89:92))) ;
		hdr_st.rnf = endian.le32u(hdr_buf(93:96)) ;
		%custom
		hdr_st.timestamp = endian.le64u(hdr_buf(209:216));
		hdr_st.channel = hdr_buf(217);
		%{
		hdr_st.w1 = endian.le16u(hdr_buf(249:250)) + double(hdr_buf(261)) + endian.le16u(hdr_buf(265:266));
		hdr_st.w2 = endian.le16u(hdr_buf(249+4:250+4)) + double(hdr_buf(261+2)) + endian.le16u(hdr_buf(265+2:266+2));
		hdr_st.woff = double(hdr_st.w2) - double(hdr_st.w1);
		%}
	end

	function csi = get_csi(csi_buf, hdr_st)
		%nsymbol = 16 ;
		pos = 1 ;

		csi = zeros(hdr_st.nrx, hdr_st.ntx, hdr_st.ntone) ;
		for rxidx = 1:hdr_st.nrx; for txidx = 1:hdr_st.ntx; for toneidx = 1:hdr_st.ntone
			imag = double(endian.le16i(csi_buf(pos:pos+1))) ;
			real = double(endian.le16i(csi_buf(pos+2:pos+3))) ;
			csi(rxidx, txidx, toneidx) = real + 1j*imag ;
			pos = pos + 4 ;
		end; end; end
	end

end

end
