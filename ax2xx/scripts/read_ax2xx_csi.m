
%HT: [1:56]-{8,22,35,49} => [-28:28]-{-21,7,0,7,21}
%{
NONHT20: 48/52, [-26:26]-{-21,-7,0,7,21}
HT20: 52/56, [-28:28]-{-21,-7,0,7,21}
HT40: 108/114, [-57,57]-{-53,-25,-11,0,11,25,53}
%}
function sts = read_ax2xx_csi(filename, savename)
	if (nargin < 2)
		savename = '' ;
	end
	f = fopen(filename, 'rb') ;
	file_len = get_file_len(f) ;

	pos = 0; 
	sts = {} ;
	while pos < file_len
		fprintf("* %.2f %%\n", 100*ftell(f)/file_len) ;

		hdr_len = fread(f, 1, 'uint32', 'b') ;
		if (hdr_len ~= 272)
			fprintf("*err hdr_len %d!=272\n", hdr_len) ;
			break ;
		end
		hdr_st = get_csi_hdr_st(f, hdr_len) ; 
		pos = pos + 4 + hdr_len ;

		csi_len = fread(f, 1, 'uint32', 'b') ;
		csi_st = get_csi_st(f, csi_len) ;
		pos = pos + 4 + csi_len ;
		if (isempty(csi_st))
			continue ;
		end

		%[hdr_len, csi_len, 111111, hdr_st.csi_len, hdr_st.ntone] 
		st = fill_st(hdr_st, csi_st) ;  
		sts{end+1} = st ;

		plot_csi(csi_st.csi) ;
		input('-') ;
	end
	if ~isempty(savename)
		save(savename, "sts");
	end

	disp('-----------') ;
	%map_sts(sts) ;

	fclose(f) ;	
end


function map_sts(sts)
	map = containers.Map() ;
	for i = 1:length(sts)
		st = sts{i} ;
		csi_len_str = int2str(st.csi_len) ;
		if any(strcmp(keys(map),csi_len_str))
			map(csi_len_str) = [map(csi_len_str); st] ;
		else
			map(csi_len_str) = st ;
		end
	end
	map_keys = keys(map) ;
	map_vals = values(map) ;
	for i = 1:length(map_keys)
		[str2num(map_keys{i}), length(map_vals{i})]
	end
	sts = map('416') ;
	save("axcsi_nonht20.mat", 'sts');
	sts = map('448') ;
	save("axcsi_ht20.mat", 'sts');
	sts = map('1824') ;
	save("axcsi_ht40.mat", 'sts');
	sts = map('3872') ;
	save("axcsi_vht80.mat", 'sts');
end


function st = fill_st(hdr_st, csi_st)
	st = struct() ;
	st.mac = hdr_st.mac ;
	st.csi_len = hdr_st.csi_len ;
	st.ntone = hdr_st.ntone ;
	st.ntx = csi_st.ntx ;
	st.nrx = csi_st.nrx ;
	st.csi = csi_st.csi ;
end


function hdr_st = get_csi_hdr_st(f, len) 
	hdr_st = struct() ;
	%a=fread(f, len, 'uint8');
	%reshape(a, {}, 16)
	%return ;
	%0
	hdr_st.csi_len = fread(f, 1, 'uint32', 'l') ;
	fread(f, 12*4) ;
	%52
	hdr_st.ntone = fread(f, 1, 'uint32', 'l') ;
	fread(f, 3*4) ;
	%68
	hdr_st.mac = join(string(dec2hex(fread(f, 6))),':') ;
	%74
	fread(f, len-74) ;
end


function plot_csi(csi)
	csi = squeeze(csi(:,1,:)) ;
	csi_phase = unwrap(angle(csi.')) ;
	%csi_phase = angle(csi.') ;
	csi_mag = abs(csi.') ;
	%plot(csi_phase) ;
	plot(csi_mag) ;
	pause(0.1) ;
end


function [nrx,ntx,ntone,type] = get_csi_type(len)
	%len=(nrx,ntx,ntone)*4
	%NONHT20: 208=(1,1,52), 416=(2,1,52), 832=(2,2,52)
	%HT20: 224=(1,1,56), 448=(2,1,56), 896=(2,2,56)
	%HT40: 456=(1,1,114), 912=(2,1,114), 1824=(2,2,114)
	%VHT80: 968=(1,1,242), 1936=(2,1,242), 3872=(2,2,242)
	%%HE160: 1936=(1,1,484), 3872=(2,1,484), 7744=(2,2,484), =2VHT80
	%HE160: 1936=(1,1,498), 3872=(2,1,498), 7744=(2,2,498), =2VHT80
	%80MHZ-wifi6-phone-hotpot 14152, 14912
	if ~mod(len, 208) 
		type = -20 ;
		ntone = 52 ;
	elseif ~mod(len, 224) 
		type = 20 ;
		ntone = 56 ;
	elseif ~mod(len, 456) 
		type = 40 ;
		ntone = 114 ;
	elseif ~mod(len, 968) 
		type = 80 ;
		ntone = 242 ;
	elseif ~mod(len, 1936) 
		type = 160 ;
		ntone = 484 ;
	else
		fprintf("*len=%d?\n",len) ;
		type = -999 ;
		ntone = len/4 ;
	end
	nrxtx = len/ntone/4 ;
	%ntx<=ntx
	if (nrxtx >= 2)
		nrx = 2 ;
	else
		nrx = 1 ;
	end
	ntx = nrxtx / nrx ;

	[nrx,ntx,ntone,type]
end


function csi_st = get_csi_st(f, len, ntone)
	ht20_subcidxs = [1:6, 8:20, 22:28] ;
	ht20_subcidxs = [-ht20_subcidxs, ht20_subcidxs] ; 
	%ht20_null_subcidxs = [-21, -7, 0, 7, 21] ;
	ht20_subcidxs = [1:7, 9:21, 23:34, 36:48, 50:56] ;
	ht20_null_subcidxs = [8, 22, 35, 49] ;
	csi_st.subcidxs = ht20_subcidxs ;

	[csi_st.nrx,csi_st.ntx,csi_st.ntone,type] = get_csi_type(len) ;

	csi = get_csi(f, csi_st.nrx, csi_st.ntx, csi_st.ntone) ; 
	%csi_st.csi = csi(:,:,ht20_subcidxs) ;
	csi_st.csi = csi ;
	%csi_st.csi(:,ht20_null_subcidxs) = nan ;
	%csi_st.csi = fillmissing(csi_st.csi, 'linear', 2, 'EndValues', 'previous') ;
end


%从f中提取4*nrx*ntx*ntone字节到csi矩阵
function csi = get_csi(f, nrx, ntx, ntone)
	%nsymbol = 16 ;
	csi = zeros(nrx,ntx,ntone) ;
	for rxidx = 1:nrx; for txidx = 1:ntx; for toneidx = 1:ntone
		imag = fread(f, 1, 'int16', 'l') ;
		real = fread(f, 1, 'int16', 'l') ;
		csi(rxidx, txidx, toneidx) = real + 1j*imag ;
		csi(rxidx, txidx, toneidx);
		%input('----')
	end; end; end
	%csi = squeeze(csi) ;
end



%用ph状态中选择部分属性填充csi_st结构
function st = fill_qca_st(ph)
	st.peer_mac = ph.peer_mac ;

	channel_bws = [20, 40, 80, 160] ;
	channel_bw_ntones = [56, 114, 256, 0] ;
	st.ntx = ph.sts ;
	st.nrx = ph.rx_chain_mask ;
	st.ntone = channel_bw_ntones(ph.channel_bw+1) ;
	%st.nrx = ph.rx_chain_mask ;
	%st.ntx = ph.csi_len/nrx/ntone/4 ;

	st.timestamp = ph.timestamp ;
	st.chain_rssi = ph.chain_rssi ;
	st.agc_gain = ph.agc_gain ; 
	st.chain_phase = ph.chain_phase ;

	%st.cfr_version = [ph.cfr_header_version, ph.cfr_data_version] ;
	st.chip_type = ph.chip_type ;
	st.platform_type = ph.platform_type ;
	st.capture_type = ph.capture_type ;
	st.capture_mode = ph.capture_mode ;
	st.capture_status = ph.capture_status ;
	st.phy_mode = ph.phy_mode ;
	st.capture_bw = ph.capture_bw ;
	st.channel_bw = ph.channel_bw ;
	st.channel = ph.channel ;
	st.band_center_freq = [ph.band_center_freq1, ph.band_center_freq2] ;
end


%尚未提供数据说明
function r = get_csi_header(f)
	r = fread(f, 8) ;
end


function ph = get_payload_header(f)
	ph = struct() ;
	ph.magic_number1 = dec2hex(fread(f, 1, 'uint32', 'l')) ;
	ph.vendor_id = dec2hex(fread(f, 1, 'uint32', 'l')) ;
	ph.cfr_header_version = fread(f, 1) ;
	ph.cfr_data_version = fread(f, 1) ;
	ph.chip_type = fread(f, 1) ;
	ph.platform_type = fread(f, 1) ;
	ph.cft_meta_data_len = fread(f, 1, 'uint32', 'l') ;
	ph.peer_mac = join(string(dec2hex(fread(f, 6))),':') ;
	ph.capture_status = fread(f, 1) ;
	ph.capture_bw = fread(f, 1) ;
	ph.channel_bw = fread(f, 1) ;
	ph.phy_mode = fread(f, 1) ;
	ph.channel = fread(f, 1, 'uint16', 'l') ;
	ph.band_center_freq1 = fread(f, 1, 'uint16', 'l') ;
	ph.band_center_freq2 = fread(f, 1, 'uint16', 'l') ;
	ph.capture_mode = fread(f, 1) ;
	ph.capture_type = fread(f, 1) ;
	ph.sts = fread(f, 1) ;
	ph.rx_chain_mask = fread(f, 1) ;
	ph.timestamp = fread(f, 1, 'uint32=>uint32', 'l') ;
	ph.cfr_dump_length = fread(f, 1, 'uint32', 'l') ;
	ph.chain_rssi = fread(f, [1,8]) ;
	ph.chain_phase = fread(f, [1,8], 'uint16', 'l') ;
	ph.rtt_cfo_measurement = fread(f, 1, 'uint32', 'l') ;
	ph.agc_gain = fread(f, [1,8]) ;
	ph.rx_start_ts = fread(f, 1, 'uint32', 'l') ;
	ph.magic_number2 = dec2hex(fread(f, 1, 'uint32', 'l')) ;

	ph.csi_st_len = fread(f, 1, 'uint16', 'l') ;
	ph.csi_st_header_len = fread(f, 1, 'uint16', 'l') ;
	ph.csi_len = ph.csi_st_len - ph.csi_st_header_len ;
end


function r = get_file_len(f)
	fseek(f, 0, 'eof') ;
	r = ftell(f) ;
	fseek(f, 0, 'bof') ;
end

