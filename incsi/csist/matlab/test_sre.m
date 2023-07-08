%clear all ;
addpath('./csilibs')
addpath('/home/flq/ws/git/SpotFi')

global dir; dir='data/sre/' ;

pha12 = load([dir, 'mean_phaseshift12.mat']).mean_phaseshift12.' ;
pha13 = load([dir, 'mean_phaseshift13.mat']).mean_phaseshift13.' ;

matdata='csi_entry_list_1_2.mat' ; %exchange rx12 cable
matdata='csi_entry_list_1_3.mat' ; 
matdata='csi_entry_list_1_1.mat' ; %1tx-3rx, 3spliter
matdata_path = [dir, matdata] ; 

filedata='position2_sRE4.dat' ; %may45/-20
filedata='position3_sRE4.dat' ; %may10
filedata='position4_sRE4.dat' ; %may20
filedata='position5_sRE4.dat' ; %may-15
filedata='position1_sRE4.dat' ; %may-30/-45
filedata_path = [dir, filedata] ;

do_file_data(filedata_path, pha12, pha13) ; return ;
do_mat_data(load('/tmp/csist.mat').csist) ; return;
do_mat_data(load(path).csi_entry_list) ; return;


function do_csist(csist, pha12, pha13)
    csist
	csi = Util.get_csi(csist) ;

    %csist = calib_csi(csist, pha12+pi, pha13+pi) ;
    csist = calib_csi(csist, pha12, pha13) ;
	%plot_phaoff(csist, 1) ;

    envs = spotfi_envs() ;
	[aoa, aoatofs] = spotfi(csi, envs, -1) 

	pause
end

function do_file_data(path, pha12, pha13)
    server = CSIFile(path) ;
    while true
		do_csist(server.read_csi_st(), pha12, pha13) ;
    end
end

function do_mat_data(sts)
    for i = 1:length(sts)
		do_csist(sts(i), 0, 0) ;
    end
end

function csist = calib_csi(csist, calib_pha12, calib_pha13) 
    %[calib_pha12; calib_pha13]
    csi = squeeze(csist.csi(1,:,:)) ;
    csist.csi(1,2,:) = csi(2,:) .* exp(-1j*calib_pha12) ;
    csist.csi(1,3,:) = csi(3,:) .* exp(-1j*calib_pha13) ;
end

function phaoff = phaoff_in_range(phaoff)
    phaoff = phaoff - 2*pi*(mean(phaoff)>pi) ;
    phaoff = phaoff + 2*pi*(mean(phaoff)<-pi) ;
end

function plot_phaoff(csist, fid)
    csi = squeeze(csist.csi(1,:,:)) ;

    pha12 = unwrap(angle(csi(2,:) .* conj(csi(1,:)))) ;
    pha12 = phaoff_in_range(pha12) ;
    pha13 = unwrap(angle(csi(3,:) .* conj(csi(1,:)))) ;
    pha13 = phaoff_in_range(pha13) ;
    figure(fid) ;
    hold on ;
    plot(pha12) ;
    plot(pha13, ':o') ;
end




