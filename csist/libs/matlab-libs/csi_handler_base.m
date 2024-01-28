%{
libs: file_handler, tcp_client_handler, endian, csiutils, csi_handler_interface
%}

classdef csi_handler_base < handle

properties (Constant)
	%IoType = struct("NONE", 0, "FILE", 1, "MAT", 2, "SOCKET", 3, "MAX", 5);
	IoType = struct("NONE", 0, "FILE", 1, "SOCKET", 2, "MAX", 5);
end

properties (Access='public')
	input_name = [];
	io_handler = [];
	io_type = csi_handler_base.IoType.NONE;
	io_handler_func_map = [];
	debug = false;
	no_io_handler = false;
end

methods (Access='public')

	function self = csi_handler_base(input_name, no_io_handler)
		if nargin < 2
			fprintf("* not create io handler\n");
			no_io_handler = false;
		end

		self.input_name = input_name;
		self.no_io_handler = no_io_handler;
		if ~self.no_io_handler
			self.io_handler = self.get_io_handler();
		end
	end

	function delete(self)
		%warning("** csi_handler_base");
	end

    function set(self, varargin)
		self.io_handler.set(varargin{:});

        for i = 1:2:length(varargin)
            argin = string(varargin{i});
            switch argin
            case "debug"
                self.debug = varargin{i+1};
            otherwise
                ;
            end
        end
    end

	function build_func_map(self)
		self.io_handler_func_map = cell(1, csi_handler_base.IoType.MAX);
		self.io_handler_func_map{csi_handler_base.IoType.FILE} = @file_handler;
		self.io_handler_func_map{csi_handler_base.IoType.SOCKET} = @socket_handler;
	end

	function r = get_io_handler(self)
		if self.io_type == csi_handler_base.IoType.NONE
			self.judge_io_type();
		end
		if isempty(self.io_handler_func_map)
			self.build_func_map();
		end
		r = self.io_handler_func_map{self.io_type}(self.input_name);
	end

	function judge_io_type(self)
		if contains(self.input_name, ':') && ~contains(self.input_name, '/')
			self.io_type = csi_handler_base.IoType.SOCKET;
		else
			self.io_type = csi_handler_base.IoType.FILE;
		end
	end

	%{
	function st = read_st(self, buf)
		st = [] ;
		warning("** read_st need impl\n");
	end
	%}

	function st = read_next(self)
		st = []; 
		warning("** read_next need impl\n");
	end

	function sts = read(self, save_name)
		if (nargin < 2); save_name = '' ; end

		sts = {} ;
		while ~self.is_end()
			st = self.read_next();
			if isempty(st); continue; end

			sts{end+1} = st ;

			if ~mod(length(sts)-1,1000)
				fprintf("* read no.%d\n", length(sts));
			end
		end

		if ~isempty(save_name)
			save(save_name, "sts");
		end
	end

	function sts = read_cached(self)
		[dirname, prefix, ext] = fileparts(self.filename);
		cache_dir = [char(dirname), '/.cache/'];
		if ~exist(cache_dir)
			mkdir(cache_dir);
		end

		cached_mat = strcat(self.filename, ".cached.mat") ;
		if exist(cached_mat, 'file')
			fprintf("* load cached_mat %s\n", cached_mat);
			sts = load(cached_mat).sts ;
		else
			sts = self.read(cached_mat);
		end
	end

    function r = is_end(self)
		r = self.io_handler.is_end();
    end

    function dbg(self, varargin)
        if self.debug
            fprintf(varargin{:});
        end
    end

	%test
	function test(self)
	end

end


methods (Static)

end

end
