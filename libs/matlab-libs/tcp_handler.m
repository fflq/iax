classdef tcp_handler < handle

properties (Access='public')
	sfd = -1 ;
	ip = "" ;
	port = -1 ;
    buf = [];
end

methods (Access='public')
    function self = tcp_handler(addr_or_ip, port, timeout)
        if nargin < 2
            addr = strsplit(addr_or_ip, ":") ;
            self.ip = addr{1};
            self.port = str2double(addr{2}) ;
        else
            self.ip = addr_or_ip;
            self.port = port;
        end
        if nargin < 3
            timeout = 5;
        end

		self.sfd = tcpclient(self.ip, self.port, "Timeout", timeout) ;
        %configureCallback(self.sfd, "byte", 4, @self.bytes_avaliable_fcn);
        self.sfd.ErrorOccurredFcn = @self.error_fcn;
    end

    function close(self)
        if self.sfd > 0
            fclose(self.sfd) ;
        end
        self.sfd = -1;
        self.ip = "";
        self.port = -1;
    end

    function res = read(self, count, data_type)
        if nargin < 3
            data_type = 'uint8';
        end
        res = read(self.sfd, count, data_type);
    end


    function tcp_error_fcn(self)
        self.close();
    end

    function tcp_bytes_avaliable_fcn(self)
    end
end

methods (Static)
    
end

end