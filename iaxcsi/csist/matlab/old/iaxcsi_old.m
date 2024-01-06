
classdef iaxcsi < handle

properties (Access='public')
	%file
	filename = "" ;
	fd = -1 ;
	file_len = -1 ;
	pos = 0 ;
	is_net = false ;
	%net
	sfd = -1 ;
	ip = "" ;
	port = 0 ;
end
	

methods (Access='public')
	function self = iaxcsi(inputname)
		try
			if contains(inputname, ':') && ~contains(inputname, '/')
				self.is_net = true;
				addr = strsplit(inputname,":") ;
				self.ip = addr{1};
				self.port = str2num(addr{2}) ;
				self.sfd = tcpclient(self.ip, self.port, "Timeout",5) ;
				%self.sfd = tcpclient(self.ip, self.port);
			else
				self.is_net = false;
				self.filename = inputname;
				self.fd = fopen(self.filename, 'rb') ;
				self.file_len = iaxcsi.get_file_len(self.fd) ;
				self.pos = 0; 
			end
		catch ME
			ME.identifier
			%self = [];
		end
	end

	function delete(self)
		if (self.fd > 0)
			fclose(self.fd) ;
			self.fd = -1;
		end

		if (self.sfd > 0)
			fclose(self.sfd) ;
			self.sfd = -1;
		end
	end

	%
	function [st, len] = read_file_once(self)
		try
			msg_len = fread(self.fd, 1, 'int32', 'b') ;
			if isempty(msg_len)
				st = [] ; len = 0 ; return ;
			end
			msg = fread(self.fd, msg_len, 'uint8') ;
			st = iaxcsi.read_axcsi_st(msg) ;
		catch ME
			ME.identifier
			st = [] ;
		end
		len = 4 + msg_len ;
	end

	function [st, len] = read_net_once(self)
		try
			msg_len = iaxcsi.be_uintn(double(read(self.sfd, 4, 'uint8'))) ;
			if isempty(msg_len)
				st = [] ; len = 0 ; return ;
			end
			msg = double(read(self.sfd, msg_len, 'uint8')) ;
			st = iaxcsi.read_axcsi_st(msg) ;
			len = 4 + msg_len ;
		catch ME
			ME.identifier
			st = [] ;
		end
		%fflqdbg
		%st
	end

	function [st, len] = read_once(self, savename)
		if (nargin < 2); savename = '' ; end

		if (self.is_net)
			[st, len] = self.read_net_once();
		else 
			[st, len] = self.read_file_once();
		end

		sts = st;
		if ~isempty(savename)
			save(savename, "sts");
		end
	end


	function sts = read_file(self)
		sts = {} ;
		while self.pos < self.file_len
			if ~mod(length(sts),100)
				fprintf("* read %.2f %%\n", 100*self.pos/self.file_len) ;
			end

			[st, len] = self.read_file_once();
			self.pos = self.pos + len ;
			if isempty(st); break; end
			sts{end+1} = st ;
			%test_st(st) ;
		end
	end

	function sts = read_net(self)
		sts = {} ;
		while true
			if ~mod(length(sts),100)
				fprintf("* read %.2f %%\n", 100*self.pos/self.file_len) ;
			end

			st = self.read_net_once() ;
			if isempty(st); break; end
			sts{end+1} = st ;
		end
	end

	function sts = read_cached(self)
		cached_mat = strcat(self.filename, ".cached.mat") ;
		if exist(cached_mat, 'file')
			fprintf("* load cached_mat %s\n", cached_mat);
			sts = load(cached_mat).sts ;
		else
			sts = self.read(cached_mat);
			%save(cached_mat, "sts");
		end
	end


	function sts = read(self, savename)
		if (nargin < 2); savename = '' ; end

		if (self.is_net)
			sts = self.read_net() ;
		else 
			sts = self.read_file() ;
		end

		if ~isempty(savename)
			save(savename, "sts");
		end
	end


	%test
	function r = test(self)
		r = true ;
		if (self.is_net)
			try
				write(self.sfd, [0]) ;
			catch ME
				r = false ;
			end
		end

	end

end


methods (Static)

	function [st, len] = static_read_once(inputname, savename)
		if (nargin < 2); savename = '' ; end
		[st, len] = iaxcsi(inputname).read_once(savename) 
	end

	function [st, len] = static_read(inputname, savename)
		if (nargin < 2); savename = '' ; end
		[st, len] = iaxcsi.static_read_once(inputname, savename);
	end

	function sts = static_read_all(inputname, savename)
		if (nargin < 2); savename = '' ; end
		sts = iaxcsi(inputname).read(savename);
	end


	function st = read_axcsi_st(buf)
		pos = 1 ;
		st = [] ;

		try
			hdr_len = iaxcsi.be_uintn(buf(pos:pos+3)); pos = pos + 4 ;
			if (hdr_len ~= 272)
				fprintf("*err hdr_len %d!=272\n", hdr_len) ;
				return ;
			end
			%global hdr_buf; %flqtest
			hdr_buf = buf(pos:pos+hdr_len-1); pos = pos + hdr_len ;
			hdr_st = iaxcsi.get_csi_hdr_st(hdr_buf) ; 
			rnf_st = iaxcsi.get_rnf_st(hdr_st.rnf) ;
			iaxcsi.output_hexs(hdr_buf, true);

			csi_len = iaxcsi.be_uintn(buf(pos:pos+3)); pos = pos + 4 ;
			csi_buf = buf(pos:pos+csi_len-1); pos = pos + csi_len ;
			if length(buf) ~= pos-1
				fprintf("* buf len err: %d %d-1\n", length(buf), pos) ;
				pause ;
			end
			csi = iaxcsi.get_csi(csi_buf, hdr_st) ;

			%[hdr_len, csi_len, 111111, hdr_st.csi_len, hdr_st.ntone] 
			st = iaxcsi.fill_csist(hdr_st, rnf_st, csi) ;  
		catch ME
			ME.identifier
		end
	end

	function test_st(st)
		st
		subc = st.subc ;
		tones = squeeze(st.csi(1,1,:)) ;
		stones = squeeze(st.scsi(1,1,:)) ;

		title(st.chan_type_str);
		plot(subc.subcs, abs(stones), 'LineWidth',2) ; hold on;
		plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; hold on;
		input('a') ;
	end

	function st = fill_csist(hdr_st, rnf_st, csi)
		st = struct() ;

		st.smac = hdr_st.smac ;
		st.seq = hdr_st.seq ;
		st.us = hdr_st.us ;
		%st.ftm = hdr_st.ftm ;
		st.ts = hdr_st.ts;
		st.datetime = iaxcsi.ts_to_dt(st.ts);

		st.rnf = dec2hex(hdr_st.rnf) ;
		%st.mod_type_str = rnf_st.mod_type_str ;
		st.chan_width = rnf_st.chan_width ;
		st.chan_type_str = rnf_st.chan_type_str ;
		st.ant_sel = rnf_st.ant_sel ;
		%st.ldpc = rnf_st.ldpc ;

		st.rssi = [hdr_st.rssi1, hdr_st.rssi2] ;
		st.nrx = hdr_st.nrx ;
		st.ntx = hdr_st.ntx ;
		st.ntone = hdr_st.ntone ;
		st.csi_len = hdr_st.csi_len ;

		st.csi = csi ;
		st = iaxcsi.calib_csi_subcs(st) ;
		st = iaxcsi.calib_csi_perm(st) ;
	end


	function [k, b, tones] = fit_csi(tones, xs)
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


	function st = calib_csi_perm(st)
		if st.nrx < 2
			return
		end
		st.perm = [1,2] ;

		csi = squeeze(st.scsi(1,1,:));
		csi2 = squeeze(st.scsi(2,1,:));
		pw1 = sum(power(abs(st.csi(1,1,:)), 2))/1e4 ;
		pw2 = sum(power(abs(st.csi(2,1,:)), 2))/1e4 ;
		[111, st.rssi(1), st.rssi(2), pw1, pw2]
		ppos = unwrap(angle(csi2 .* conj(csi)));
		z = polyfit(1:length(ppos), ppos, 1) ;
		[z(1), z(2), mean(ppos)]
		%figure(21); hold on; plot(ppos,'-o'); 
		%figure(22); hold off; plot(abs(csi),'r-o'); hold on; plot(abs(csi2),'b-o');
		%global recs hdr_buf;
		%recs(end+1,:) = ([st.rssi(1), st.rssi(2), pw1, pw2, hdr_buf(241:256).']);
		%recs(end+1,:) = ([0, z(1), z(2), mean(ppos), hdr_buf(257:272).']);

		%{
		pause
		[a,b,st.scsi(1,1,:)] = iaxcsi.fit_csi(st.scsi(1,1,:), st.subc.subcs) ;
		[a,b,st.scsi(2,1,:)] = iaxcsi.fit_csi(st.scsi(2,1,:), st.subc.subcs) ;
		[dk, deltab, tones] = iaxcsi.fit_csi(st.scsi(2,1,:) .* conj(st.scsi(1,1,:)), st.subc.subcs);
		%}
		%if ~(st.rssi(1) > st.rssi(2) && pw1 > pw2)
		if (pw1 >= pw2) ~= (st.rssi(1) >= st.rssi(2)) %no
		%if (pw1 < pw2) %no
			st.perm = [2,1] ; 
			st
			pause;
			%st.scsi(:,:,:) = st.scsi(st.perm,:,:) ;
			%for i = 1:st.ntx; st.scsi(:,i,:) = st.scsi(st.perm,i,:) ; end
		end
		%pause;
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
		if strcmp(st.chan_type_str, "VHT160") 
			st.csi = st.csi(:,:,subcarry.get_vht160_noextra_subc(st.ntone));
			st.ntone = size(st.csi, 3) ;
		elseif strcmp(st.chan_type_str, "HE160")
			st.csi = st.csi(:,:,subcarry.get_he160_noextra_subc(st.ntone));
			st.ntone = size(st.csi, 3) ;
		end


		subc = subcarry.get_subc(st.chan_type_str) ;
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

		%Bits 10-8: mod type
		mod_type_strs = ["CCK", "NOHT", "HT", "VHT", "HE", "EH"] ;
		[mod_type, rnf_st.mod_type_str] = iaxcsi.get_rate_mcs_fmt_val(8, 7, mod_type_strs, rnf) ;  

		%Bits 24-23: HE type
		if (mod_type == 4+1) 
			he_type_strs = ["HE-SU", "HE-EXT-SU", "HE-MU", "HE-TRIG"] ;
			[~, rnf_st.mod_type_str] = iaxcsi.get_rate_mcs_fmt_val(23, 3, he_type_strs, rnf) ;
		end

		%Bits 13-11: chan width
		chan_width_vals = [20, 40, 80, 160, 320] ;
		[~, rnf_st.chan_width] = iaxcsi.get_rate_mcs_fmt_val(11, 7, chan_width_vals, rnf) ;

		rnf_st.chan_type_str = strcat(rnf_st.mod_type_str, num2str(rnf_st.chan_width)) ;

		%Bits 15-14: ant sel
		ant_sel_vals = 0:3 ;
		rnf_st.ant_sel = iaxcsi.get_rate_mcs_fmt_val(14, 3, ant_sel_vals, rnf) ;

		%Bits 16
		rnf_st.ldpc = rnf & bitshift(1, 16) ;
	end


	function r = le_uint(s)
		r = 0 ;
		m = 1 ;
		for i = 1:length(s)
			r = r + s(i)*m ;
			m = m*256 ;
		end
	end


	function r = le_int(s)
		r = iaxcsi.le_uint(s) ;
		nbit = length(s)*8 ;
		highest_bit = bitshift(1, nbit-1) ;
		if bitand(r, highest_bit)
			r = r - bitshift(1, nbit) ;
		end
	end


	function hdr_st = get_csi_hdr_st(hdrbuf) 
		hdr_st = struct() ;

		hdr_st.csi_len = iaxcsi.le_uint(hdrbuf(1:4)) ; 
		hdr_st.ftm = uint32(iaxcsi.le_uint(hdrbuf(9:12))) ;
		hdr_st.nrx = hdrbuf(47) ;
		hdr_st.ntx = hdrbuf(48) ;
		hdr_st.ntone = iaxcsi.le_uint(hdrbuf(53:56)) ;
		hdr_st.rssi1 = -hdrbuf(61) ;
		hdr_st.rssi2 = -hdrbuf(65) ;
		hdr_st.smac = join(string(dec2hex(hdrbuf(69:74))),':') ;
		hdr_st.seq = iaxcsi.le_uint(hdrbuf(77)) ;
		hdr_st.us = uint64(iaxcsi.le_uint(hdrbuf(89:92))) ;
		hdr_st.rnf = iaxcsi.le_uint(hdrbuf(93:96)) ;
		%custom
		hdr_st.ts = iaxcsi.le_uint(hdrbuf(209:216));
	end


	%从f中提取4*nrx*ntx*ntone字节到csi矩阵
	function csi = get_csi(csibuf, hdr_st)
		%nsymbol = 16 ;
		pos = 1 ;

		csi = zeros(hdr_st.nrx, hdr_st.ntx, hdr_st.ntone) ;
		for rxidx = 1:hdr_st.nrx; for txidx = 1:hdr_st.ntx; for toneidx = 1:hdr_st.ntone
				%imag = fread(f, 1, 'int16', 'l') ;
				%real = fread(f, 1, 'int16', 'l') ;
				imag = iaxcsi.le_int(csibuf(pos:pos+1)) ;
				real = iaxcsi.le_int(csibuf(pos+2:pos+3)) ;
				csi(rxidx, txidx, toneidx) = real + 1j*imag ;
				pos = pos + 4 ;
		end; end; end
	end


	function r = get_file_len(f)
		fseek(f, 0, 'eof') ;
		r = ftell(f) ;
		fseek(f, 0, 'bof') ;
	end


	%need s(nitem, comp), be=big-endian
	function r = to_uintn(s, be)
		persistent lews ;
		if isempty(lews)
			pows = 0:16-1 ;
			lews = 256 .^ pows ;
		end
		if (size(s,2) == 1)
			s = s.' ;
		end

		ws = lews(1:size(s,2)) ;
		if be; ws = flip(ws); end 
		r = sum(s.*ws, 2) ;
	end

	function r = uintn_to_intn(s, nbits)
		uintn = bitshift(1, nbits-1) ;
		r = s - 2*uintn .* (s>=uintn);
	end

	function r = le_uintn(s)
		r = iaxcsi.to_uintn(s, false) ;
	end

	function r = le_intn(s, nbits)
		r = iaxcsi.uintn_to_intn(iaxcsi.le_uintn(s), nbits) ;
	end

	function r = be_uintn(s)
		r = iaxcsi.to_uintn(s, true) ;
	end

	function r = be_intn(s, nbits)
		r = iaxcsi.uintn_to_intn(iaxcsi.be_uintn(s), nbits) ;
	end

	function dt = ts_to_dt(ts) 
		ts = double(ts) ;
		dt = datetime(ts, 'ConvertFrom', 'posixtime', 'TimeZone', 'Asia/Shanghai', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') ;
		%dt = string(datestr(dt, 'YYYY-mm-dd HH:MM:ss')) ;
	end

	function output_hexs(buf, dec_fmt)
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
	end
end

end
