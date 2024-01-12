
classdef iaxcsi < handle

properties (Access='public')
	input_name_ = "";
	debug_ = false;
	file_handler_ = [];
	tcp_handler_ = [];
	is_net_ = false ;
	%file
	%filename = "" ;
	%fd = -1 ;
	%file_len = -1 ;
	%pos = 0 ;
	%is_net_ = false ;
	%%net
	%sfd = -1 ;
	%ip = "" ;
	%port = 0 ;
end
	

methods (Access='public')
	function self = iaxcsi(input_name, debug)
		if nargin < 2
			debug = false;
		end
		self.input_name_ = input_name;
		self.debug_ = debug;
		self.build_handler(self.input_name_);
	end

	function build_handler(self, input_name)
			if contains(input_name, ':') && ~contains(input_name, '/')
				self.is_net_ = true;
				self.tcp_handler_ = tcp_handler(input_name);
				%addr = strsplit(input_name,":") ;
				%self.ip = addr{1};
				%self.port = STR2DOUBLE(addr{2}) ;
				%self.sfd = tcpclient(self.ip, self.port, "Timeout",5) ;
				%self.sfd = tcpclient(self.ip, self.port);
			else
				self.is_net_ = false;
				self.file_handler_ = file_handler(input_name);
				%self.filename = input_name;
				%self.fd = fopen(self.filename, 'rb') ;
				%self.file_len = iaxcsi.get_file_len(self.fd) ;
				%self.pos = 0; 
			end
		try
		catch ME
			ME.identifier
			%self = [];
		end

	end

	function close(self)
		self.input_name_ = "";
		self.tcp_handler_.close();
		self.tcp_handler_ = [];
		self.file_handler_.close();
		self.file_handler_ = [];
	end

	%
	function [st, len] = read_file_next(self)
		st = []; len = 0;
			%msg_len = fread(self.fd, 1, 'int32', 'b') ;
			msg_len = endian.be32i(self.file_handler_.read(4));
			if isempty(msg_len); return ; end

			%msg = fread(self.fd, msg_len, 'uint8') ;
			msg = self.file_handler_.read(msg_len);
			st = self.read_st(msg) ;
		try
		catch ME
			ME.identifier
		end
		len = 4 + msg_len ;
	end

	function [st, len] = read_net_next(self)
		st = []; len = 0;
			%msg_len = iaxcsi.be_uintn(double(read(self.sfd, 4, 'uint8'))) ;
			msg_len = endian.be32i(self.tcp_handler_.read(4));
			if isempty(msg_len); return ; end

			%msg = double(read(self.sfd, msg_len, 'uint8')) ;
			msg = double(self.tcp_handler_.read(msg_len));
			st = self.read_st(msg) ;
			len = 4 + msg_len ;
		try
		catch ME
			ME.identifier
		end
		%fflqdbg
		%st
	end

	function [st, len] = read_next(self)
		if (self.is_net_)
			[st, len] = self.read_net_next();
		else 
			[st, len] = self.read_file_next();
		end
	end


	function sts = read_file(self)
		sts = {} ;
		while self.file_handler_.has_data()
			if ~mod(length(sts),100)
				fprintf("* read %.2f %%\n", self.file_handler_.percent());
			end

			st = self.read_file_next();
			if isempty(st); break; end

			sts{end+1} = st ;
		end
	end

	function sts = read_net(self)
		sts = {} ;
		while self.tcp_handler_.sfd > 0
			if ~mod(length(sts),100)
				fprintf("* read %d\n", length(sts));
			end

			st = self.read_net_next() ;
			if isempty(st); break; end
			sts{end+1} = st ;
		end
	end

	function sts = read(self, save_name)
		if (nargin < 2); save_name = '' ; end

		if (self.is_net_)
			sts = self.read_net() ;
		else 
			sts = self.read_file() ;
		end

		if ~isempty(save_name)
			save(save_name, "sts");
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
			if self.debug_
				st.hdr_buf = hdr_buf;
			end
		try
		catch ME
			ME.identifier
		end
	end


	%test
	function r = test(self)
		addpath("../../../libs/matlab-libs/");

		r = true ;
		if (self.is_net_)
			try
				write(self.sfd, [0]) ;
			catch ME
				r = false ;
			end
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

		title(st.chan_type_str);
		plot(subc.subcs, abs(stones), 'LineWidth',2) ; hold on;
		plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; hold on;
		input('a') ;
	end

	function st = fill_csist(hdr_st, rnf_st, csi)
		st = struct() ;
		st = hdr_st ; %fflqtest

		st.smac = hdr_st.smac ;
		st.seq = hdr_st.seq ;
		st.us = hdr_st.us ;
		%st.ftm = hdr_st.ftm ;
		st.ts = hdr_st.ts;
		st.datetime = utils.ts_to_dt(st.ts);

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
		st = iaxcsi.calib_csi_perm(st, hdr_st.buf) ;
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

	function st = perm_csi(st, new_perm)
		if st.nrx < 2
			warning("* nrx < 2");
			return;
		end
		st.perm = new_perm;
		st.csi(:,:,:) = st.csi(st.perm,:,:) ;
		st.scsi(:,:,:) = st.scsi(st.perm,:,:) ;
	end

	function st = calib_csi_perm(st, hdr_buf)
		if st.nrx < 2
			return;
		end
		st.perm = [1,2] ;

		csi = squeeze(st.scsi(1,1,:));
		csi2 = squeeze(st.scsi(2,1,:));
		pw1 = sum(power(abs(st.csi(1,1,:)), 2))/1e4 ;
		pw2 = sum(power(abs(st.csi(2,1,:)), 2))/1e4 ;
		%[11, st.rssi(1), st.rssi(2), pw1, pw2]
		ppos = unwrap(angle(csi2 .* conj(csi)));
		z = polyfit(1:length(ppos), ppos, 1) ;
		%[z(1), z(2), mean(ppos)]
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
			%st.perm = [2,1] ; 
			%st
			%pause;
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


	function hdr_st = get_csi_hdr_st(hdr_buf) 
		hdr_st = struct() ;
		hdr_st.buf = hdr_buf;

		hdr_st.csi_len = endian.le32u(hdr_buf(1:4)) ; 
		hdr_st.ftm = uint32(endian.le32u(hdr_buf(9:12))) ;
		hdr_st.nrx = hdr_buf(47) ;
		hdr_st.ntx = hdr_buf(48) ;
		hdr_st.ntone = endian.le32u(hdr_buf(53:56)) ;
		hdr_st.rssi1 = -hdr_buf(61) ;
		hdr_st.rssi2 = -hdr_buf(65) ;
		hdr_st.smac = join(string(dec2hex(hdr_buf(69:74))),':') ;
		hdr_st.seq = hdr_buf(77) ;
		hdr_st.us = uint64(endian.le32u(hdr_buf(89:92))) ;
		hdr_st.rnf = endian.le32u(hdr_buf(93:96)) ;
		%custom
		hdr_st.ts = endian.le64u(hdr_buf(209:216));
		hdr_st.w1 = endian.le16u(hdr_buf(249:250)) + hdr_buf(261) + endian.le16u(hdr_buf(265:266));
		hdr_st.w2 = endian.le16u(hdr_buf(249+4:250+4)) + hdr_buf(261+2) + endian.le16u(hdr_buf(265+2:266+2));
		hdr_st.woff = double(hdr_st.w2) - double(hdr_st.w1);
	end


	%从f中提取4*nrx*ntx*ntone字节到csi矩阵
	function csi = get_csi(csi_buf, hdr_st)
		%nsymbol = 16 ;
		pos = 1 ;

		csi = zeros(hdr_st.nrx, hdr_st.ntx, hdr_st.ntone) ;
		for rxidx = 1:hdr_st.nrx; for txidx = 1:hdr_st.ntx; for toneidx = 1:hdr_st.ntone
			%imag = fread(f, 1, 'int16', 'l') ;
			%real = fread(f, 1, 'int16', 'l') ;
			imag = double(endian.le16i(csi_buf(pos:pos+1))) ;
			real = double(endian.le16i(csi_buf(pos+2:pos+3))) ;
			csi(rxidx, txidx, toneidx) = real + 1j*imag ;
			pos = pos + 4 ;
		end; end; end
	end

end

end
