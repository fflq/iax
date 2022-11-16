clear all;
close all;
addpath('../../') ;

global g_phaseoff g_perms ;
g_phaseoff = [] ;
g_perms = [] ;
angles = [] ;

sts = load('./axcsi_vht80.mat').sts ;
for i = 1:length(sts)
	csi_st = sts(1) ;

	csi = squeeze(csi_st.csi) ;
	angleoffs12 = angle( csi(2,:) .* conj(csi(1,:)) ) ;  
	g_phaseoff(end+1) = mean(angleoffs12) ;
	fprintf("- %d, %d, 12(%f)\n", i, length(g_phaseoff), mean(g_phaseoff)) ;
	Util.plot_realtime1(1, g_phaseoff) ;
end




