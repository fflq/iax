classdef mat_handler < io_handler_base

properties (Access='public')
    csi_sts = [];
    len = 0;
    idx = 1;
end

methods (Access='public')

    function self = mat_handler(cells)
        self.csi_sts = cells;
        self.len = length(self.csi_sts);
        self.idx = 1;
    end

    %%ops in buffer
    function sts = read(self, count)
        if nargin < 2
            count = 1;
        end
        ed = min(self.idx+count-1, self.len);
        sts = self.csi_sts{self.idx:ed};
        self.idx = ed + 1;
    end

    function r = is_empty(self)
        r = isempty(self.csi_sts);
    end

    function r = is_end(self)
        r = self.idx > self.len;
    end
end

methods (Static)
end

end