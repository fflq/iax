%{
* 与spotfi-origin不同
- spotfi代码有不合理写死的参数, 信号数envs.nsignal=nComps=2, 天线间距envs.d=2.6e-2
- origin每次removePhsSlope而这里根据streamid
- origin在rapmusic非迭代时用kron，迭代时直接乘，二者结果在17位小数前同，导致pmu值不同，
  虽不像15位小数影响极值，但是影响max_corr中断
%}

function s = gs()
    global g ;

    %% 调试控制
    g.debug = false ;
    g.display = true ;
    g.display = false ;
    g.pmufig = false ;
    g.aoafig = false ;
    g.aoafig = true ;
    g.netpac = false ;
    g.sendaoa = false ;
    g.apmode = true ;
    g.origin_spotfi = true ;
    g.origin_spotfi = false ;

    g.gpu = true ;
    g.single = true ;

    %% 实现相关
    g.envs = struct ;
    g.envs.c = 3e8 ;
    g.envs.fc = 5.63e9;
    g.envs.fs = 312.5e3; % fgap
    g.envs.lambda = g.envs.c/g.envs.fc ;
    g.envs.d = g.envs.lambda/2 ;

    % antenna num, and num for smoothing music
    g.envs.nant_tx = 1 ;   
    g.envs.nant_rx = 3 ;   
    g.envs.nant_smooth = floor(g.envs.nant_rx/2) + 1 ;
    % subcarrier, and num for smoothing music
    g.envs.subc_idxs = -58:4:58 ;
    g.envs.nsubc = length(g.envs.subc_idxs) ;
    g.envs.nsubc_smooth = floor(g.envs.nsubc/2) ;
    g.envs.corr_threshold = 0.4 ;
    g.envs.niter = 10 ;

    g.envs.grid_size = [2, 2] ;
    g.envs.grid_size = [181, 101] ;
    g.envs.taus_range = [-50, 50]*1e-9 ;
    g.envs.thetas_range = [-90, 90] ;

    % 同spotfi的设置
    if (g.origin_spotfi)
        g.envs.corr_threshold = 0.4 ;
        g.envs.d = 2.6e-2 ;
        g.envs.niter = 2 ;
        g.envs.nsignal = 2 ; % fixed signal nums
    end

    %% 网络相关
    g.nets = struct ;
    g.nets.csi_ip = '0.0.0.0' ;
    g.nets.csi_port = 7020 ;
    %g.nets.aoa_ip = '192.168.100.187' ;
    g.nets.aoa_ip = '0.0.0.0' ;
    g.nets.aoa_port = 7022 ;

    g.disp = @gdisp ;
    g.print = @gprint ;

    s = g ;
end

function gdisp(s)
    if (gs().display)
        disp(s) ;
    end
end

function gprint(fmt, varargin)
    if (gs().display)
        fprintf(fmt, varargin{:}) ;
    end
end
