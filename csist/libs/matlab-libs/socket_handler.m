classdef socket_handler < io_handler_base

properties (Access='public')
    %socket
	sfd = [] ;
    addr = "" ;
	ip = "" ;
	port = -1 ;
    timeout = 10;
    %stats
    is_tcp = false;
    is_server = false;
    reconn_count = 0;
    max_reconn_count = 100;
    clients = [];
end

methods (Access='public')

    function self = socket_handler(addr, timeout)
        if nargin < 2
            timeout = 10;
        end
        self.addr = addr;
        self.timeout = timeout;

        addrs = strsplit(addr, ":") ;
        assert(length(addrs)==3, "like (tcp-server:127.0.0.1:7120), not (%s)", addr);
        self.judge_socket_type(addrs{1});        
        self.ip = addrs{2};
        self.port = str2double(addrs{3}) ;

        self.reconn();
    end

    function delete(self)
        warning("** socket_handler");
        self.close();
    end

    function close(self)
        self.sfd = [];
        self.clients = [];
    end

    function judge_socket_type(self, type)
        switch type
        case 'tcp-server'
            self.is_tcp = true;
            self.is_server = true;
        case 'tcp-client'
            self.is_tcp = true;
            self.is_server = false;
        case 'udp-server'
            self.is_tcp = false;
            self.is_server = true;
        case 'udp-client'
            self.is_tcp = false;
            self.is_server = false;
        otherwise
            warning("** not support type: %s", type);
        end
    end

    function reconn(self)
        self.reconn_count = self.reconn_count + 1;
        self.close();
        pause(min(self.reconn_count, self.timeout));

        fprintf("* reconn no.%d: %s\n", self.reconn_count, self.addr);
        try
            if self.is_tcp 
                if self.is_server
                    self.sfd = tcpserver(self.ip, self.port, "Timeout", self.timeout,...
                        "ConnectionChangedFcn", @socket_handler.connection_changed_fcn) ;
                else
                    self.sfd = tcpclient(self.ip, self.port, "Timeout", self.timeout) ;
                end
                configureCallback(self.sfd, "byte", 4, @socket_handler.bytes_avaliable_fcn);
            else
                if self.is_server
                    self.sfd = udpport("datagram", "LocalHost", self.ip, "LocalPort",...
                        self.port, 'Timeout', self.timeout, "outputDatagramsize",20480);
                        %"EnablePortSharing", true, 
                else
                    self.sfd = udpport("datagram", 'Timeout', self.timeout,...
                        "outputDatagramsize", 20480);
                        %"EnablePortSharing", true);
                    %write(self.sfd, 1:100, "uint8", self.ip, self.port);
                end
                configureCallback(self.sfd, "datagram", 1, @socket_handler.datagrams_available_fcn);
            end

            self.sfd.UserData = self;
            self.sfd.ErrorOccurredFcn = @socket_handler.error_occurred_fcn;
		catch ME
			ME.identifier
            self.reconn();
        end
    end

    function buf = read_tcp(self, count)
        buf = []; 
        try
            buf = read(self.sfd, count, "uint8");
		catch ME
			ME
            ME.stack
            self.reconn();
        end
    end

    function [buf, datagrams] = read_udp(self, count)
        buf = []; datagrams = [];
        try
            datagrams = read(self.sfd, count, "uint8");
            for i = 1:length(datagrams)
                datagram = datagrams(i);
                buf = [buf, datagram.Data];
            end
		catch ME
			ME
            ME.stack
            self.reconn();
        end
    end

    %%op in buffer
    function buf = read(self, count)
        %use custom timeout, not read/write timeout
        timeout = self.timeout;
        n = 1;
        while self.sbuf.len < count
            if n == 1
                fprintf("* wait read buf(%d/%d) ", self.sbuf.len, count);
            elseif ~mod(n, 50)
                fprintf(".\n");
            else
                fprintf(".");
            end
            n = n + 1;
            pause(1);

            %reconn for client
            if ~self.is_server
                timeout = timeout - 1;
                if timeout < 0
                    self.reconn();
                    timeout = self.timeout;
                end
            end
        end
        fprintf("\n");
        buf = self.sbuf.read(count);
    end

    function r = is_end(self)
        r = self.reconn_count > self.max_reconn_count;
    end

end

methods (Static)

    function bytes_avaliable_fcn(source, event)
        self = source.UserData;
        while source.NumBytesAvailable > 0
            avaliable_bytes_num = source.NumBytesAvailable;
            rbuf = self.read_tcp(avaliable_bytes_num);
            self.sbuf.write(rbuf);
            self.dbg("* tcp %d aval, read %d\n", avaliable_bytes_num, length(rbuf));
        end
    end

    function connection_changed_fcn(source, ~)
        self = source.UserData;
        if source.Connected
            self.clients{end+1} = source;
            fprintf("* tcp accepted the client connection request\n");
        else
            %del client
            fprintf("* tcp client has disconnected\n");
        end
    end

    function datagrams_available_fcn(source, ~)
        self = source.UserData;
        avaliable_datagrams_num = source.NumDatagramsAvailable;
        if avaliable_datagrams_num > 0
            rbuf = self.read_udp(avaliable_datagrams_num);
            self.sbuf.write(rbuf);
            self.dbg("* udp %d aval, read %d\n", avaliable_datagrams_num, length(rbuf));
        end
    end

    %not here, but expection
    function error_occurred_fcn(source)
        self = source.UserData;
        warning("** socket error occurred\n");
        self.reconn();
    end

    function test(self)
        th = socket_handler("127.0.0.1:7120");
        for i = 1:1000
            "loop"
            pause;
        end
    end
end

end