classdef file_handler < io_handler_base

properties (Access='public')
    block_len = 512*1024*1024 ;
    %block_len = 100*1024 ;
    file_len = 0 ;
    file_read_len = 0;
    fd = -1 ;
    is_file_end = false;
end

methods (Access='public')

    function self = file_handler(filename)
        self.fd = fopen(filename, 'rb') ;
	    self.file_len = file_handler.get_file_len(self.fd) ;
        self.file_read_len = 0;
        self.read_file_block();
    end

    function delete(self)
        warning("** file_handler");
        self.close();
    end

    function read_file_block(self)
        %keep block_len buf
        %if self.sbuf.len < self.block_len
        rbuf = fread(self.fd, self.block_len, "uint8=>uint8");
        if self.block_len ~= length(rbuf)
            self.is_file_end = true;
            self.close();
        end
        self.sbuf.write(rbuf);
    end

    function r = progress(self)
        r = 100 * (self.file_read_len/self.file_len);
    end

    function close(self)
        if self.fd > 0
            fclose(self.fd);
            self.fd = -1;
        end
    end

    %%ops in buffer
    function rbuf = read(self, len)
        len = double(len);
        %read until len or file-end
        while ~self.is_file_end && self.sbuf.len < 2*len
            self.read_file_block();
        end
        rbuf = self.sbuf.read(len);
        self.file_read_len = self.file_read_len + length(rbuf);
    end

    function r = is_end(self)
        r = self.sbuf.is_empty() && self.is_file_end;
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