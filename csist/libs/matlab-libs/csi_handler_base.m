%{
libs: file_handler, tcp_client_handler, endian, csiutils, csi_handler_interface
%}

classdef csi_handler_base < handle

properties (Access='public')
	input_name = "";
	io_handler = [];
	is_net = false ;
	debug = false;
end

methods (Access='public')

	function self = csi_handler_base(input_name, debug)
		if nargin < 1
			fprintf("* nop csi_handler_base\n");
			return;
		end
		if nargin < 2
			debug = false;
		end

		self.input_name = input_name;
		self.debug = debug;
		self.build_io_handler();
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

	function build_io_handler(self)
			if contains(self.input_name, ':') && ~contains(self.input_name, '/')
				self.is_net = true;
				self.io_handler = socket_handler(self.input_name);
			else
				self.is_net = false;
				self.io_handler = file_handler(self.input_name);
			end
		try
		catch ME
			ME.identifier
			%self = [];
		end

	end


	function st = read_next(self)
		st = []; len = 0;
		warning("** read_next need impl\n");
	end

	function sts = read(self, save_name)
		if (nargin < 2); save_name = '' ; end

		sts = {} ;
		while ~self.io_handler.is_end()
			st = self.read_next();
			if isempty(st); break; end

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

	function st = read_st(self, buf)
		pos = 1 ;
		st = [] ;
		try
			warning("** read_st need impl\n");
		catch ME
			ME.identifier
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
