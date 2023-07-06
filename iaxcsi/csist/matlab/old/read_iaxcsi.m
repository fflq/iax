
function sts = read_iaxcsi(inputname, savename)
	if (nargin < 2)
		savename = '' ;
	end

	if isnumeric(inputname)
		sts = read_iaxcsi_net(inputname) ;
	else
		sts = read_iaxcsi_file(inputname) ;
	end

	if ~isempty(savename)
		save(savename, "sts");
	end

end


function sts = read_iaxcsi_file(filename)
	f = fopen(filename, 'rb') ;
	file_len = get_file_len(f) ;
	pos = 0; 

	sts = {} ;
	while pos < file_len
		if ~mod(length(sts),100)
			fprintf("* read %.2f %%\n", 100*pos/file_len) ;
		end

		msg_len = fread(f, 1, 'int32', 'b') ;
		msg = fread(f, msg_len, 'uint8') ;
		pos = pos + 4 + msg_len ;

		st = read_iaxcsi_st(msg) ;
		if isempty(st); break; end
		sts{end+1} = st ;
		%test_st(st) ;
	end

	fclose(f) ;	
end


function sts = read_iaxcsi_net(port)
	sts = {} ;
	cfd = tcpclient('localhost', 7120) ;
	while true
		msg_len = be_uintn(double(read(cfd, 4, 'uint8'))) ;
		msg = double(read(cfd, msg_len, 'uint8')) ;
		st = read_iaxcsi_st(msg) ;
		sts{end+1} = st ;
		st
	end
end


function st = read_iaxcsi_st(buf)
	pos = 1 ;
	st = [] ;

	hdr_len = be_uintn(buf(pos:pos+3)); pos = pos + 4 ;
	if (hdr_len ~= 272)
		fprintf("*err hdr_len %d!=272\n", hdr_len) ;
		return ;
	end
	hdr_buf = buf(pos:pos+hdr_len-1); pos = pos + hdr_len ;
	hdr_st = get_csi_hdr_st(hdr_buf) ; 
	rnf_st = get_rnf_st(hdr_st.rnf) ;

	csi_len = be_uintn(buf(pos:pos+3)); pos = pos + 4 ;
	csi_buf = buf(pos:pos+csi_len-1); pos = pos + csi_len ;
	if length(buf) ~= pos-1
		fprintf("* buf len err: %d %d-1\n", length(buf), pos) ;
		pause ;
	end
	csi = get_csi(csi_buf, hdr_st) ;

	%[hdr_len, csi_len, 111111, hdr_st.csi_len, hdr_st.ntone] 
	st = fill_csist(hdr_st, rnf_st, csi) ;  
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
	st = calib_csi_subcs(st) ;
	st = calib_csi_perm(st) ;
end


function st = calib_csi_perm(st)
	if st.nrx < 2
		return
	end
	st.perm = [1,2] ;
	pw1 = sum(abs(st.csi(1,1,:))) ;
	pw2 = sum(abs(st.csi(2,1,:))) ;
	if (pw1 >= pw2) ~= (st.rssi(1) >= st.rssi(2))
		st.perm = [2,1] ;
		for i = 1:st.ntx
			st.scsi(:,i,:) = st.scsi(st.perm,i,:) ;
		end
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
	%if (st.chan_type_str ~= "VHT80") return ; end
	subc = Subcarry.get_subc(st.chan_type_str) ;

	scsi = zeros(st.nrx, st.ntx, subc.subcs_len) ; % add for dc
	data_pilot_dc_tones = zeros(1, subc.subcs_len) ;

	for irx = 1:st.nrx; for itx = 1:st.ntx; 
		csi_data_pilot_tones = squeeze(st.csi(irx, itx, :)) ;
		data_pilot_dc_tones(subc.idx_data_pilot_subcs) = csi_data_pilot_tones ; 

		% for raw_csi, only data_tones valid
		x = subc.idx_data_subcs ;
		xv = subc.idx_pilot_dc_subcs ;
		data_pilot_dc_tones(xv) = do_complex_interp(xv, x, data_pilot_dc_tones(x)) ;
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
	[mod_type, rnf_st.mod_type_str] = get_rate_mcs_fmt_val(8, 7, mod_type_strs, rnf) ;  

	%Bits 24-23: HE type
	if (mod_type == 4+1) 
		he_type_strs = ["HE-SU", "HE-EXT-SU", "HE-MU", "HE-TRIG"] ;
		[~, rnf_st.mod_type_str] = get_rate_mcs_fmt_val(23, 3, he_type_strs, rnf) ;
	end

	%Bits 13-11: chan width
	chan_width_vals = [20, 40, 80, 160, 320] ;
	[~, rnf_st.chan_width] = get_rate_mcs_fmt_val(11, 7, chan_width_vals, rnf) ;

	rnf_st.chan_type_str = strcat(rnf_st.mod_type_str, num2str(rnf_st.chan_width)) ;

	%Bits 15-14: ant sel
	ant_sel_vals = 0:3 ;
	rnf_st.ant_sel = get_rate_mcs_fmt_val(14, 3, ant_sel_vals, rnf) ;

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
	r = le_uint(s) ;
	nbit = length(s)*8 ;
	highest_bit = bitshift(1, nbit-1) ;
	if bitand(r, highest_bit)
		r = r - bitshift(1, nbit) ;
	end
end


function hdr_st = get_csi_hdr_st(hdrbuf) 
	hdr_st = struct() ;

	hdr_st.csi_len = le_uint(hdrbuf(1:4)) ; 
	hdr_st.ftm = uint32(le_uint(hdrbuf(9:12))) ;
	hdr_st.nrx = hdrbuf(47) ;
	hdr_st.ntx = hdrbuf(48) ;
	hdr_st.ntone = le_uint(hdrbuf(53:56)) ;
	hdr_st.rssi1 = -hdrbuf(61) ;
	hdr_st.rssi2 = -hdrbuf(65) ;
	hdr_st.smac = join(string(dec2hex(hdrbuf(69:74))),':') ;
	hdr_st.seq = le_uint(hdrbuf(77)) ;
	hdr_st.us = uint64(le_uint(hdrbuf(89:92))) ;
	hdr_st.rnf = le_uint(hdrbuf(93:96)) ;
end


%从f中提取4*nrx*ntx*ntone字节到csi矩阵
function csi = get_csi(csibuf, hdr_st)
	%nsymbol = 16 ;
	pos = 1 ;

	csi = zeros(hdr_st.nrx, hdr_st.ntx, hdr_st.ntone) ;
	for rxidx = 1:hdr_st.nrx; for txidx = 1:hdr_st.ntx; for toneidx = 1:hdr_st.ntone
			%imag = fread(f, 1, 'int16', 'l') ;
			%real = fread(f, 1, 'int16', 'l') ;
			imag = le_int(csibuf(pos:pos+1)) ;
			real = le_int(csibuf(pos+2:pos+3)) ;
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
	r = to_uintn(s, false) ;
end

function r = le_intn(s, nbits)
	r = uintn_to_intn(le_uintn(s), nbits) ;
end

function r = be_uintn(s)
	r = to_uintn(s, true) ;
end

function r = be_intn(s, nbits)
	r = uintn_to_intn(be_uintn(s), nbits) ;
end


