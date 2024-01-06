classdef file_handler < handle

properties (Access='public')
    block_len = 512*1024*1024 ;
    %block_len = 100*1024 ;
    need_reread_len = 20*1024 ;
    file_len = -1 ;
    fbuf_len = -1 ;
    file_pos = 1;
    fbuf = [] ;
    pos = 1 ;
    fd = -1 ;
end

methods (Access='public')
    function self = file_handler(filename)
        self.fd = fopen(filename, 'rb') ;
	    self.file_len = file_handler.get_file_len(self.fd) ;
    end

    function r = if_need_read_file(self)
		r = (self.fbuf_len - self.pos < self.need_reread_len) && (ftell(self.fd) < self.file_len) ;
    end

    function read_file_block(self)
		if self.if_need_read_file()
			buf = fread(self.fd, self.block_len).' ;
			self.fbuf = [self.fbuf(self.pos:end), buf] ;
			self.fbuf_len = length(self.fbuf) ;
			self.pos = 1 ;
		end
    end

    function [ret_buf, ret_len] = read(self, len)
        len = double(len);
        if self.if_need_read_file()
            self.read_file_block() ;
        end
        rend = min(self.pos+len-1, self.fbuf_len) ;
        ret_buf = self.fbuf(self.pos:rend);
        ret_len = length(ret_buf);
        self.pos = self.pos + len ;
        self.file_pos = self.file_pos + len ;
		%[self.pos, self.fbuf_len, self.file_pos, self.file_len]
    end

    function r = has_data(self)
        r = self.file_pos < self.file_len ;
        if ~r
            self.close_file();
        end
    end

    function r = percent(self)
        r = 100 * (self.file_pos/self.file_len);
    end

    function close_file(self)
        if self.fd > 0
            fclose(self.fd);
            self.fd = -1;
        end
    end

    function close(self)
        self.close_file();
        self.pos = -1;
    end
end

methods (Static)
    function r = get_file_len(fd)
        fseek(fd, 0, 'eof') ;
        r = ftell(fd) ;
        fseek(fd, 0, 'bof') ;
    end
end

end