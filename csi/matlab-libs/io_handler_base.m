classdef io_handler_base < handle

properties (Access='public')
    sbuf = buffer();
    debug = false;
end

methods (Access='public')

    function self = io_handler_base()
    end

    function buf = read(self, len)
		warning("** read_next need impl\n");
    end

    function delete(self)
		%warning("** io_handler_base");
        self.sbuf = [];
    end

    function set(self, varargin)
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

    function r = is_empty(self)
        r = self.sbuf.is_empty();
    end

    function r = is_end(self)
        warning("** is_end need impl\n");
    end

    function dbg(self, varargin)
        if self.debug
            fprintf(varargin{:});
        end
    end

end

methods (Static)
end

end