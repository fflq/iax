%{
Instrument Tools, Signal Processing Toolbox
%}
%clear ; close all; clc;
%clear all ;
%addpath('./csilibs') ;


classdef CSIFile < handle

properties (Access='public')
	file = '' ;
	csi_sts = {} ;
	idx = 0 ;
end

methods (Access='public')
	function obj = CSIFile(file)
		obj.idx = 1 ;
		obj.file = file ;
		obj.csi_sts = read_bf_file(file) ;
	end

	function csi_st = read_csi_st(obj)
		csi_st = [] ;

		if (obj.idx <= length(obj.csi_sts))
			csi_st = obj.csi_sts{obj.idx} ;
			csi_st.csi = get_scaled_csi(csi_st) ;
			obj.idx = obj.idx + 1 ;
		end
	end

end

end


