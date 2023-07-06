%{
Instrument Tools, Signal Processing Toolbox
%}
%clear ; close all; clc;
%clear all ;
%addpath('./csilibs') ;
addpath('/home/flq/ws/git/CSI/intel5300')


classdef iaxcsi_server < CSIServer

methods (Access='public')
	function obj = iaxcsi_server(ip, port)
		obj = obj@CSIServer()
	end

	function csi_st = read_csi_st(obj)
		csi_st = [] ;

    	[data, r] = obj.recv_csi(obj.clientfd) ;
        if (0 > r); 
			fprintf("* recv err %d\n", r) ;
			return ; 
		end

        csi_sts = read_bf_packet(data, true) ;
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
