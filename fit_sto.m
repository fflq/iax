clear all; close all ;
addpath('./csilibs') ;


csi_sts = read_bf_file('./data/csi.dat') ;
for i = 1:length(csi_sts)
    csi = get_scaled_csi(csi_sts{i}) ;
    csi = squeeze(csi(1,:,:)) ;
    cag = angle(csi) ;
    unwrap_cag = unwrap(cag, [], 2) ;

    %figure(i) ; 
    hold on ;
    plot(unwrap_cag.') ;
    %unwrap +- 2npi %plot(cag.') ; plot(cag.'-unwrap(cag.')) ;
    legend("rx1", "rx2", "rx3") ;

        [k,b] = kbfit(csi) 
    if (i == 1)
    end
    for n = 1:30
        unwrap_cag(:,n) = unwrap_cag(:,n) - 4*n*k - b;
    end
    plot(unwrap_cag.') ;
    break ;
end

function [k,b] = kbfit(csi)
    %不同于spotfi三个天线,这里只用一个天线拟合
    subc_idxs = -58:4:58 ;
    unwrap_phases = unwrap(angle(csi(1,:))) ;
    %subc_idxs = repmat(subc_idxs, 3, 1) ; unwrap_phases = unwrap_phases(:) ;
    res = polyfit(subc_idxs, unwrap_phases, 1) ;
    k = res(1) ;
    b = res(2) ;
end
