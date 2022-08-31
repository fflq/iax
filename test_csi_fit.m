clear all; close all ;
addpath('./csilibs') ;


%server = CSIFile('./data/csi.dat') ;
server = CSIServer() ;
while true
	csi_st = server.read_csi_st() ;
	if (isempty(csi_st))
		%pause(2) ; continue ;
		break ;
	end
	handle_csist(csi_st) ;
end


function handle_csist(csi_st)
    csi = get_scaled_csi(csi_st) ;
    csi = squeeze(csi(1,:,:)) ;
	csi = CSIUtil.get_csi(csi_st) ;
    cag = angle(csi) ;

    unwrap_cag = unwrap(cag, [], 2) ;
    %figure(i) ; 
    plot(unwrap_cag.') ;
    %unwrap +- 2npi %plot(cag.') ; plot(cag.'-unwrap(cag.')) ;
    legend("rx1", "rx2", "rx3") ;

	%paper说只对第一个包计算kb,之后直接减.但效果并不好,所以作者源代码也是每个包都算下kb
        [k,b] = kbfit(csi) 
    if (i == 1)
    end
    for n = 1:30
        unwrap_cag(:,n) = unwrap_cag(:,n) - 4*n*k - b;
    end
	hold on ;
    plot(unwrap_cag.') ;
	hold off ;
    %break ;
	pause(1) ;
end


function [k,b] = kbfit(csi)	
	%结果差不多
	useone = true ;
	useone = false ;
    %不同于spotfi三个天线,这里只用一个天线拟合
	if (useone)
    	subc_idxs = -58:4:58 ; %(1,30)
    	unwrap_phases = unwrap(angle(csi(1,:))) ; %(1,30)
	else
    	subc_idxs = -58:4:58 ; %(1,30)
    	subc_idxs = repmat(subc_idxs.', 3, 1); %(90,1)  
    	unwrap_phases = unwrap(angle(csi), [], 2) ; %(3,30)
		unwrap_phases = unwrap_phases.' ; 
		unwrap_phases = unwrap_phases(:) ; %(90,1)
	end
    res = polyfit(subc_idxs, unwrap_phases, 1) ;
    k = res(1) ;
    b = res(2) ;
end

