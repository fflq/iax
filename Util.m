%{
Instrument Tools, Signal Processing Toolbox
%}
%clear ; close all; clc;
%clear all ;
%addpath('./csilibs') ;


classdef Util < handle

methods (Static)

	function csi = get_csi(csi_st)
		csi = get_scaled_csi(csi_st) ;
		csi = squeeze(csi(1,:,:)) ; 
	end

	function cabl_csi = cabl_phase(csi, phaseoff12, phaseoff13)
		cabl_csi = csi ;
		cabl_csi(2,:) = csi(2,:) * exp(-j*phaseoff12) ;
		cabl_csi(3,:) = csi(3,:) * exp(-j*phaseoff13) ;
	end

	function plot_realtime1(fid, data, spec)
		if (nargin < 3)
			spec = 'b--o' ;
		end
		len = length(data) ;
		skip = 2 ;
		if (len > skip)
			figure(1); hold on ;
			plot(len-skip:len, data(end-skip:end), spec) ;
			drawnow ;
		end
	end

end

end
