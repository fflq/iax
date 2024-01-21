classdef io_handler_interface < handle

properties (Access='public')
end

methods (Access='public')
end

methods (Abstract)
    buf = read(self, count);
    close(self);
    set(self, varargin);
    r = is_empty(self);
end

methods (Static)
end

end