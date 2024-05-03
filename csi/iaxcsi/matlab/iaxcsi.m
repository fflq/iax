%{
libs: file_handler, socket_handler, endian, csi_handler_base
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

			hdr_st = self.get_csi_hdr_st(hdr_buf) ; 
			rnf_st = self.get_rnf_st(hdr_st.rnf) ;
			%utils.print_hexs(hdr_buf, true);

			csi_len = endian.be32u(buf(pos:pos+3)); pos = pos + 4 ;
			csi_buf = buf(pos:pos+csi_len-1); pos = pos + csi_len ;

			csi = self.get_csi(csi_buf, hdr_st) ;

			%[hdr_len, csi_len, 111111, hdr_st.csi_len, hdr_st.ntone] 
			st = self.fill_csist(hdr_st, rnf_st, csi) ;  
		try
		catch ME
			ME.identifier
		end
	end

	function hdr_st = get_csi_hdr_st(self, hdr_buf) 
		hdr_st = struct() ;

		if self.debug
			hdr_st.buf = hdr_buf;
		end
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
	end

	function rnf_st = get_rnf_st(self, rnf)
		rnf_st = struct() ;

        %Bits 3-0: MCS
        %rnf_st.mcs = RATE_HT_MCS_INDEX(rnf & RATE_MCS_CODE_MSK);
		rnf_st.mcs = iaxcsi.get_rnf_fmt_val(rnf, 0, 15) ; 

		%Bits 5-4: nss
		rnf_st.nss = iaxcsi.get_rnf_fmt_val(rnf, 4, 3)+1 ;

		%Bits 10-8: mod type
		persistent rate_type_strs ;
		if isempty(rate_type_strs)
			rate_type_strs = ["CCK", "NOHT", "HT", "VHT", "HE", "EH"] ;
		end
		rate_type = iaxcsi.get_rnf_fmt_val(rnf, 8, 7) ;  
		rnf_st.rate_type = rate_type_strs(rate_type+1) ;

		%Bits 24-23: HE type
		persistent he_type_strs ;
		if rate_type == 4+1 && isempty(he_type_strs)
			he_type_strs = ["HE-SU", "HE-EXT-SU", "HE-MU", "HE-TRIG"] ;
		end
		if (rate_type == 4+1) 
			rate_type = iaxcsi.get_rnf_fmt_val(rnf, 23, 3);
			%rnf_st.rate_type = he_type_strs(rate_type+1) ;
		end

		%Bits 13-11: chan width
		persistent chan_width_vals ;
		if isempty(chan_width_vals)
			chan_width_vals = [20, 40, 80, 160, 320] ;
		end
		val = iaxcsi.get_rnf_fmt_val(rnf, 11, 7) ;
		rnf_st.bandwidth = chan_width_vals(val+1);
		if strcmpi(rnf_st.rate_type, "NOHT")
			rnf_st.bandwidth = 20 ;
		end

		rnf_st.rate_bw_type = strcat(rnf_st.rate_type, num2str(rnf_st.bandwidth)) ;

		%Bits 15-14: ant sel
		rnf_st.ant_sel = iaxcsi.get_rnf_fmt_val(rnf, 14, 3);

		%Bits 16
		rnf_st.ldpc = rnf & bitshift(1, 16) ;
	end

	function csi = get_csi(self, csi_buf, hdr_st)
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

	% raw_csi only data_subcs+pilot_subcs, need add dc_subcs, then interp pilot_dc_subcs
	% eg. csi={-28:-1,1:28}, pilot{-21,-7,7,21} in csi is nan, dc{0} not in csi
	function st = calib_csi_subcs(self, st)
		% handle special
		if strcmp(st.rate_bw_type, "VHT160") 
			st.csi = st.csi(:,:,subcarrier.get_vht160_noextra_subc(st.ntone));
			st.ntone = size(st.csi, 3) ;
		elseif strcmp(st.rate_bw_type, "HE160")
			st.csi = st.csi(:,:,subcarrier.get_he160_noextra_subc(st.ntone));
			st.ntone = size(st.csi, 3) ;
		end

		subc = subcarrier.get_subc(st.rate_bw_type) ;
		scsi = zeros(st.nrx, st.ntx, subc.subcs_len) ; % add for dc
		data_pilot_dc_tones = zeros(1, subc.subcs_len) ;

		for irx = 1:st.nrx; for itx = 1:st.ntx; 
			data_pilot_dc_tones = 0;
			csi_data_pilot_tones = squeeze(st.csi(irx, itx, :)) ;
			data_pilot_dc_tones(subc.idx_data_pilot_subcs) = csi_data_pilot_tones ; 
			%figure(51);hold on; plot(subc.subcs, abs(data_pilot_dc_tones), 'b-o'); input("");

			% for raw_csi, only data_tones valid
			x = subc.idx_data_subcs ;
			xv = subc.idx_pilot_dc_subcs ;
			data_pilot_dc_tones(xv) = iaxcsi.do_complex_interp(xv, x, data_pilot_dc_tones(x)) ;
			scsi(irx,itx,:) = data_pilot_dc_tones ;
			%scsi(irx,itx,subc.idx_data_pilot_subcs) = squeeze(st.csi(irx, itx, :)) ;
			%figure(51);hold on; plot(abs(squeeze(scsi(irx,itx,:))), 'r-*'); input("");
		end; end;
		
		st.scsi = scsi ;
		st.subc = subc ;
		st.nstone = length(subc.subcs) ;
	end

	function st = fill_csist(self, hdr_st, rnf_st, csi)
		st = struct() ;
		if self.debug
			st.st = hdr_st ; 
		end

		st.smac = hdr_st.smac ;
		st.seq = hdr_st.seq ;
		st.us = hdr_st.us ;
		%st.ftm = hdr_st.ftm ;
		st.timestamp = hdr_st.timestamp/1e9;
		st.datetime = utils.ts_to_dt(st.timestamp);

		st.rnf = dec2hex(hdr_st.rnf) ;
		st.bandwidth = rnf_st.bandwidth ;
		st.rate_type = rnf_st.rate_type ;
		st.rate_bw_type = rnf_st.rate_bw_type ;
		%st.ant_sel = rnf_st.ant_sel ;
		%st.ldpc = rnf_st.ldpc ;
		st.mcs = rnf_st.mcs;
		st.nss = rnf_st.nss;

		st.rssi = [hdr_st.rssi1, hdr_st.rssi2] ;
		st.nrx = hdr_st.nrx ;
		st.ntx = hdr_st.ntx ;
		st.ntone = hdr_st.ntone ;
		st.csi_len = hdr_st.csi_len ;
		st.csi = csi ;

		st = self.calib_csi_subcs(st) ;
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

	%diff from iaxcsi.cpp
	function val = get_rnf_fmt_val(rnf, pos, msk_base)
		val = bitand(bitshift(rnf, -pos), msk_base) ;
	end

	function test_st(st)
		st
		subc = st.subc ;
		tones = squeeze(st.csi(1,1,:)) ;
		stones = squeeze(st.scsi(1,1,:)) ;

		title(st.rate_bw_type);
		plot(subc.subcs, abs(stones), 'LineWidth',2) ; hold on;
		plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; hold on;
	end
end

end
