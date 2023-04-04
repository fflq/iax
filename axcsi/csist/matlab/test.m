
csi = randn(3,30) ;
csi = randn(2,1001) ;
envs.nant_rx = size(csi,1) ;
envs.ntone = size(csi,2) ;
s = smooth_csi(csi, envs) ;

%diff by nic
function csi_smoothed = smooth_csi(csi, envs)
    %csi_smoothed = zeros(size(csi,2), size(csi,2)); % 3*30
    csi_smoothed = [] ;

    nant_sm = 2 ;
    ntone_sm = floor(envs.ntone/2);
    %{
    % paper are 30*32
    for j = 1:2
        % csi的2行15列，按行转为smooth_csi的一列，注意非共轭转置
        csi_smoothed(:,j) = [csi(1, j:j+14), csi(2, j:j+14)].' ;
        csi_smoothed(:,j+16) = [csi(2, j:j+14), csi(3, j:j+14)].' ;
    end
    %}
    %for 3*30, 1:16, 1:2
    for antidx = 1:envs.nant_rx-nant_sm+1
        for toneidx = 1:envs.ntone-ntone_sm+1
            tmpcsi = [] ;
            for wantidx = antidx:antidx+nant_sm-1 
                range = toneidx:toneidx+ntone_sm-1 ;
                tmpcsi = [tmpcsi, csi(wantidx,range)];
            end
            csi_smoothed(:,end+1) = tmpcsi ;
        end
    end
end

