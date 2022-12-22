
%HT: [1:56]-{8,22,35,49} => [-28:28]-{-21,7,0,7,21}
%{
NONHT20: 48/52, [-26:26]-{-21,-7,0,7,21}
HT20: 52/56, [-28:28]-{-21,-7,0,7,21}
HT40: 108/114, [-57,57]-{-53,-25,-11,0,11,25,53}
%}
function sts = read_axcsi(filename, savename)
	if (nargin < 2)
		savename = '' ;
	end
	f = fopen(filename, 'rb') ;
	file_len = get_file_len(f) ;

	pos = 0; 
	sts = {} ;
	while pos < file_len
		if ~mod(length(sts),1000)
			fprintf("* read %.2f %%\n", 100*ftell(f)/file_len) ;
		end

		hdr_len = fread(f, 1, 'uint32', 'b') ;
		if (hdr_len ~= 272)
			fprintf("*err hdr_len %d!=272\n", hdr_len) ;
			break ;
		end
		hdr_st = get_csi_hdr_st(f, hdr_len) ; 
		rnf_st = get_rnf_st(hdr_st.rnf) ;
		pos = pos + 4 + hdr_len ;

		csi_len = fread(f, 1, 'uint32', 'b') ;
		csi = get_csi(f, csi_len, hdr_st.nrx, hdr_st.ntx, hdr_st.ntone) ;
		pos = pos + 4 + csi_len ;

		%[hdr_len, csi_len, 111111, hdr_st.csi_len, hdr_st.ntone] 
		st = fill_st(hdr_st, rnf_st, csi) ;  
		sts{end+1} = st ;

		st
		input('-');
	end
	if ~isempty(savename)
		save(savename, "sts");
	end

	fclose(f) ;	
end


function st = fill_st(hdr_st, rnf_st, csi)
	st = struct() ;

	st.smac = hdr_st.smac ;
	st.seq = hdr_st.seq ;
	st.us = hdr_st.us ;
	%st.ftm = hdr_st.ftm ;

	st.rnf = dec2hex(hdr_st.rnf) ;
	st.mod_type_str = rnf_st.mod_type_str ;
	st.chan_width = rnf_st.chan_width ;
	st.ant_sel = rnf_st.ant_sel ;
	%st.ldpc = rnf_st.ldpc ;

	st.rssi = [hdr_st.rssi1, hdr_st.rssi2] ;
	st.nrx = hdr_st.nrx ;
	st.ntx = hdr_st.ntx ;
	st.ntone = hdr_st.ntone ;
	st.csi_len = hdr_st.csi_len ;

	st.csi = csi ;
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


function hdr_st = get_csi_hdr_st(f, len) 
	hdr_st = struct() ;
	hdrbuf = fread(f, len) ;

	hdr_st.csi_len = le_uint(hdrbuf(1:4)) ; 
	hdr_st.ftm = uint32(le_uint(hdrbuf(9:12))) ;
	hdr_st.nrx = hdrbuf(47) ;
	hdr_st.ntx = hdrbuf(48) ;
	hdr_st.ntone = hdrbuf(53) ;
	hdr_st.rssi1 = -hdrbuf(61) ;
	hdr_st.rssi2 = -hdrbuf(65) ;
	hdr_st.smac = join(string(dec2hex(hdrbuf(69:74))),':') ;
	hdr_st.seq = le_uint(hdrbuf(77)) ;
	hdr_st.us = le_uint(hdrbuf(89:92)) ;
	hdr_st.rnf = le_uint(hdrbuf(93:96)) ;
end


%从f中提取4*nrx*ntx*ntone字节到csi矩阵
function csi = get_csi(f, len, nrx, ntx, ntone)
	%nsymbol = 16 ;
	csibuf = fread(f, len) ;
	pos = 1 ;

	csi = zeros(nrx,ntx,ntone) ;
	for rxidx = 1:nrx; for txidx = 1:ntx; for toneidx = 1:ntone
		%imag = fread(f, 1, 'int16', 'l') ;
		%real = fread(f, 1, 'int16', 'l') ;
		imag = le_int(csibuf(pos:pos+1)) ;
		real = le_int(csibuf(pos+2:pos+3)) ;
		csi(rxidx, txidx, toneidx) = real + 1j*imag ;
		pos = pos + 4 ;
	end; end; end
	%csi = squeeze(csi) ;

	ht20_subcidxs = [1:6, 8:20, 22:28] ;
	ht20_subcidxs = [-ht20_subcidxs, ht20_subcidxs] ; 
	%ht20_null_subcidxs = [-21, -7, 0, 7, 21] ;
	ht20_subcidxs = [1:7, 9:21, 23:34, 36:48, 50:56] ;
	ht20_null_subcidxs = [8, 22, 35, 49] ;

	%csi = csi(:,:,ht20_subcidxs) ;
	%csi(:,ht20_null_subcidxs) = nan ;
	%csi = fillmissing(csi, 'linear', 2, 'EndValues', 'previous') ;
end


function r = get_file_len(f)
	fseek(f, 0, 'eof') ;
	r = ftell(f) ;
	fseek(f, 0, 'bof') ;
end



