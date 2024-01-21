
classdef csietr < csi_handler_base

properties (Constant)
    Type = struct('I53', 1, 'IAX', 2, 'MAX', 5);
end

properties (Access='public')
	type = csietr.Type.I53;
	csi_handler = [];
	%type map
	csi_handler_func_map = [];
	convert_csist_func_map = [];
end

methods (Access='public')

	function self = csietr(input_name, type)
		self@csi_handler_base(); % empty base

		if nargin < 2; type = csietr.Type.I53; end
		self.input_name = input_name;
		self.type = type;

		self.build_func_map();

		self.csi_handler = self.csi_handler_func();
		%self.io_handler = self.csi_handler.io_handler;
	end

	function delete(self)
		%warning("** csietr");
	end

    function set(self, varargin)
		%set@csi_handler_base(self, varargin{:}); %no use base
		self.csi_handler.set(varargin{:});
	end

	function r = is_end(self)
		r = self.csi_handler.is_end();
	end

	%replace switch self.type
	function build_func_map(self)
		self.csi_handler_func_map = cell(1, csietr.Type.MAX);
		self.csi_handler_func_map{csietr.Type.I53} = @incsi;
		self.csi_handler_func_map{csietr.Type.IAX} = @iaxcsi;

		self.convert_csist_func_map = cell(1, csietr.Type.MAX);
		self.convert_csist_func_map{csietr.Type.I53} = @self.convert_from_st_i53;
		self.convert_csist_func_map{csietr.Type.IAX} = @self.convert_from_st_iax;
	end

	function r = csi_handler_func(self)
		r = self.csi_handler_func_map{self.type}(self.input_name);
	end

	function st = convert_csist_func(self, st)
		st = self.convert_csist_func_map{self.type}(st);
	end

	function st = read_st(self, buf)
		st = self.csi_handler.read_st(buf);
		st = self.convert_csist_func(st);
	end

	function st = read_next(self)
		st = self.csi_handler.read_next();
		st = self.convert_csist_func(st);
		try
		catch ME
			ME.identifier
		end
	end

	function st = convert_from_st_i53(self, in_st)
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
		st.subcs = -58:4:58;
		st.type = csietr.Type.I53;
		st.dbg = in_st;
	end

	function st = convert_from_st_iax(self, in_st)
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
		st.type = csietr.Type.IAX;
		st.dbg = in_st;
	end

end


methods (Static)

	function st = calib_ppo(st, ppo12, ppo13)
		if nargin < 3
			if st.nrx >= 3
				error("*** error no ppo13");
			end
			ppo13 = ppo12;
		end

		if isrow(ppo12); ppo12 = ppo12.'; end
		if isrow(ppo13); ppo13 = ppo13.'; end

		for i = 1:st.ntx
			st.csi(i,2,:) = squeeze(st.csi(i,2,:)) .* exp(-1j*ppo12);
			if st.nrx >= 3
				st.csi(i,3,:) = squeeze(st.csi(i,3,:)) .* exp(-1j*ppo13);
			end
		end
	end

end

end
