%{
Instrument Tools, Signal Processing Toolbox
%}
%clear ; close all; clc;
%clear all ;
%addpath('./csilibs') ;


classdef CSIUtil < handle

methods (Static)
	function csi = get_csi(csi_st)
    	csi = get_scaled_csi(csi_st) ;
    	csi = squeeze(csi(1,:,:)) ;
	end

end

end
