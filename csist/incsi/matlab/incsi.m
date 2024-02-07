%{
libs: file_handler, tcp_client_handler, endian, csiutils, csi_handler_interface
%}

classdef incsi < csi_handler_base

properties (Access='public')
end

methods (Access='public')
	function self = incsi(input_name)
		self@csi_handler_base(input_name);
	end
	
	function delete(self)
		%warning("** incsi");
	end

	function st = read_next(self)
		st = []; len = 0;
			msg_len = endian.be16u(self.io_handler.read(2));
			if isempty(msg_len); return ; end

			msg = self.io_handler.read(msg_len);
			st = self.read_st(msg) ;

			len = 2 + msg_len ;
		try
		catch ME
			ME.identifier
		end
	end

	function st = read_st(self, buf)
		pos = 1 ;
		st = [] ;
			st = read_bf_buf(buf);
			if ~isempty(st) && iscell(st)
				st = st{1};
			end
			st.csi = get_scaled_csi(st) ;
		try
		catch ME
			ME.identifier
		end
	end

end

methods (Static)

end

end
