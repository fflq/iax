%{
libs: file_handler, tcp_client_handler, endian, csiutils, csi_handler_interface
%}

classdef csi_handler_interface < handle

properties (Access='public')
	input_name_ = "";
	io_handler_ = [];
	is_net_ = false ;
	debug_ = false;
end

methods (Access='public')

	set(self, varargin);

	build_io_handler(self, input_name);

	close(self);

	st = read_st(self, buf);

	st = read_next(self);

	sts = read(self, save_name);

	sts = read_cached(self);

	test(self);

end

methods (Static)

end

end
