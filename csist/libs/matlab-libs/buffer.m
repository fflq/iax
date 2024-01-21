classdef buffer < handle

properties (Access='public')
    buf = [];
    %pos = 1;
    len = 0;
end

methods (Access='public')

    function self = buffer()
    end

    function delete(self)
		%warning("** buffer");
        self.buf = [];
        self.len = 0;
    end

    function write(self, wbuf)
        if isrow(self.buf) ~= isrow(wbuf); wbuf = wbuf.'; end
        self.buf = [self.buf, uint8(wbuf)];
        self.len = length(self.buf);
    end

    function rbuf = read(self, count)
        ed = min(count, self.len);
        rbuf = self.buf(1:ed);
        %truncate
        self.buf = self.buf(ed+1:end);
        self.len = length(self.buf);
    end

    function r = is_empty(self)
        r = isempty(self.buf);
    end

end

methods (Static)

end

end