%{
Instrument Tools, Signal Processing Toolbox
%}
%clear ; close all; clc;
%clear all ;
%addpath('./csilibs') ;


classdef CSIServer < handle

properties (Access='public')
	ip = '0.0.0.0';
	port = 7020 ; 
	clientfd = [] ;
end

methods (Access='public')
	function obj = CSIServer(ip, port)
		if (nargin > 1)
			obj.ip = ip ;
			obj.port = port ;
		elseif (nargin > 0)
			obj.port = port ;
		end

    	obj.clientfd = obj.wait_conn(obj.ip, obj.port) ;
	end

	function sfd = wait_conn(obj, ip, port)
		%sfd = tcpserver(7020,"Timeout",20,"ByteOrder","big-endian") ;
		sfd = tcpip(ip, port, 'NetworkRole', 'server', 'Timeout', 60) ;
		fprintf("* [csi_server][%s:%d] accept...\n", ip, port) ;
		fopen(sfd) ;
		fprintf("* [csi_server] got\n\n") ;
	end

	function csi_st = read_csi_st(obj)
		csi_st = [] ;

    	[data, r] = obj.recv_csi(obj.clientfd) ;
        if (0 > r); 
			fprintf("* recv err %d\n", r) ;
			return ; 
		end

        csi_sts = read_bf_buf(data, true) ;
		if (~isempty(csi_sts))
			csi_st = csi_sts{1} ;
			csi_st.csi = get_scaled_csi(csi_st) ;
		end
        %[aoas, ~] = spotfi(csi_trace, envs, -1);
	end

	function [data, r] = recv_csi(obj, sfd)
		data = [] ;
		r = 1 ;
		try
			len = fread(sfd, 1, 'uint16') ;
			% datatype是数值类型的，返回的是double数组，手册说的
			data = uint8(fread(sfd, len, 'uint8')') ;
		catch E
			r = -1 ;
			disp(E) ;
			fprintf("* recv csi fail, again\n") ;
		end
	end

end

end
