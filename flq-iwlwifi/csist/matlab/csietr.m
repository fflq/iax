
classdef csietr < handle

properties (Constant)
    Type = struct('I53', 1, 'IAX', 2);
end

properties (Access='public')
	display = true;
	inputname = "";
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
	type = csietr.Type.I53;
end

methods (Access='public')
	function self = csietr(display)
		if nargin < 1 
			display = false;
		end
		self.display = display;
	end

	%{
	function self = csietr(inputname, type)
		if nargin < 2
			type = csietr.Type.I53;
		end
		self.inputname = inputname;
		self.type = type;

		try
			if contains(inputname, ':') && ~contains(inputname, '/')
				self.is_net = true;
				addr = strsplit(inputname,":") ;
				self.ip = addr{1};
				self.port = STR2DOUBLE(addr{2}) ;
				self.sfd = tcpclient(self.ip, self.port, "Timeout",5) ;
				%self.sfd = tcpclient(self.ip, self.port);
			else
				self.is_net = false;
				self.filename = inputname;
				%self.fd = fopen(self.filename, 'rb') ;
				%self.file_len = csietr.get_file_len(self.fd) ;
				%self.pos = 0; 
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
			st = csietr.read_axcsi_st(msg) ;
		catch ME
			ME.identifier
			st = [] ;
		end
		len = 4 + msg_len ;
	end

	function [st, len] = read_net_once(self)
		try
			msg_len = csietr.be_uintn(double(read(self.sfd, 4, 'uint8'))) ;
			if isempty(msg_len)
				st = [] ; len = 0 ; return ;
			end
			msg = double(read(self.sfd, msg_len, 'uint8')) ;
			st = csietr.read_axcsi_st(msg) ;
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
	%}

	function sts = read(self, inputname)
		sts = {};
		try
			if contains(inputname, ':') && ~contains(inputname, '/')
				self.is_net = true;
				sts = read_net(inputname);
			else
				self.is_net = false;
				self.filename = inputname;
				sts = read_file(self.filename);
			end
		catch ME
			ME.identifier
			%self = [];
		end
	end

	function sts = read_file(self, filename, type, once)
		if nargin < 3
			type = csietr.Type.I53;
		end
		if nargin < 4
			once = false;
		end
		self.type = type;
		self.is_net = false;

		sts = {};
		switch self.type
		case csietr.Type.I53
			sts = self.read_file_i53(filename);
			sts = self.convert_from_sts_i53(sts);
		case csietr.Type.IAX
			sts = self.read_file_iax(filename, once);
			sts = self.convert_from_sts_iax(sts);
		otherwise
			error("* unknown type");
		end
	end

	function sts = read_file_cached(self, filename, type)
		sts = self.read_file(filename, type, true);
	end

	%127.0.0.1:12345
	function st = read_net(self, addr_str, type)
		if nargin < 3
			type = csietr.Type.I53;
		end
		self.type = type;
		self.is_net = true;
		%{
		try
			addrs = strsplit(addr_str,":") ;
			self.ip = addrs{1};
			self.port = STR2DOUBLE(addrs{2}) ;
			self.sfd = tcpclient(self.ip, self.port, "Timeout",5) ;
			%self.sfd = tcpclient(self.ip, self.port);
		catch ME
			ME.identifier
			%self = [];
		end
		%}
		addpath("../../../incsi/csist/matlab/csilibs/");
		addpath("../../../incsi/csist/matlab/");
		server = CSIServer() ;
		while true
			st = server.read_csi_st() 
			if (isempty(st)); continue; end
			sts = self.convert_from_sts_i53({st});
			st = sts{1};
		end

		st = [];
	end

	function sts = convert_from_sts_i53(self, in_sts)
		sts = {};
		for i = 1:length(in_sts) 
			in_st = in_sts{i};
			st = csist();
			st.seq = in_st.bfee_count;
			st.us = in_st.timestamp_low;
			st.rnf = in_st.rate;
			st.ntx = in_st.Ntx;
			st.nrx = in_st.Nrx;
			st.ntone = size(in_st.csi, 3);
			st.protocol = 1;
			st.rssi = [in_st.rssi_a, in_st.rssi_b, in_st.rssi_c];
			st.agc = in_st.agc;
			st.noise = in_st.noise;
			st.perm = in_st.perm;
			st.csi = in_st.csi;
			sts{end+1} = st;
		end
	end

	function sts = read_file_i53(self, filename)
		addpath("../../../incsi/csist/matlab/csilibs/");
		self.filename = filename;
		sts = read_bf_file(self.filename) ;
		for i = 1:length(sts)
			st = sts{i};
			sts{i}.csi = get_scaled_csi(st) ;
		end
	end 

	function sts = read_file_iax(self, filename, once)
		if nargin < 3
			once = false;
		end
		sts = {};

		addpath("../../../iaxcsi/csist/matlab/");
		self.filename = filename;
		if once
			sts = iaxcsi(self.filename).read_cached();
		else
			sts = iaxcsi(self.filename).read();
		end
	end

	function sts = convert_from_sts_iax(self, in_sts)
		sts = {};
		for i = 1:length(in_sts) 
			in_st = in_sts{i};
			st = csist();
			st.seq = in_st.seq;
			st.us = in_st.us;
			st.rnf = in_st.rnf;
			st.ntx = in_st.ntx;
			st.nrx = in_st.nrx;
			st.ntone = in_st.nstone;
			st.chan_type = in_st.chan_type_str;
			prot = char(st.chan_type);
			if prot(2) == 'E'; st.protocol = 3;
			elseif prot(1) == 'V'; st.protocol = 2;
			elseif prot(2) == 'T'; st.protocol = 1;
			elseif prot(1) == 'N'; st.protocol = 0;
			end
			st.rssi = [in_st.rssi(1), in_st.rssi(2)];
			st.perm = in_st.perm;
			st.bw = in_st.chan_width;
			st.smac = in_st.smac;
			st.subcs = in_st.subc.subcs;
			st.csi = zeros(in_st.ntx, in_st.nrx, in_st.nstone);
			for j = 1:in_st.ntx
				for k = 1:in_st.nrx
					st.csi(j,k,:) = in_st.scsi(k,j,:);
				end
			end
			sts{end+1} = st;
		end
	end


end


methods (Static)

end

end
