global gx ;
gx = 1 ;

from_remote();
% from_file() ;

function from_remote()
    ufd = udpport("byte", "LocalPort", 7020, "EnablePortSharing", true, "ByteOrder", "big-endian");
    disp(ufd) ;
    
    n = 1 ;
    while true
        try
            len = read(ufd, 1, 'uint16') ;
            %disp(len) ;
            % datatype是数值类型的，返回的是double数组，手册说的
            buf = read(ufd, len, 'uint8') ;
            data = uint8(buf') ;
        catch E
            disp(E) ;
            pause(1) ;
            continue ;
        end
        
        %handle_csi_cells(read_bf_packet(data)) ;
        csi_trace = read_bf_packet(data) ;
        % 画的图不对，和from_file不同，因为行向量和列向量被画一样了
        % 因为是1包x*30子载波y，只是1上30个点，，故自作聪明变成30x*1，是错的
        % 解决办法多凑几个包行数再画图
        %handle_csi_trace(csi_trace) ;
        
        csi_traces(n,:) = csi_trace ;
        if (n >= 40)
            handle_csi_trace(csi_traces) ;
            n = 0 ;
        end
        n = n + 1 ;
    end
end



function from_file()
    csi_trace = read_bf_file('/home/flq/ws/csi/csispl/netlink/26csi.dat') ;
    handle_csi_trace(csi_trace) ;
end



function handle_csi_trace(csi_trace)
    %disp(length(csi_trace)) ;
    if (length(csi_trace) < 1)  
        return ;
    end
        
    for i = 1:length(csi_trace)
        csi_entry = csi_trace{i} ;
        %disp(csi_entry) ;
        csi = get_scaled_csi(csi_entry) ;
        amp = abs(squeeze(csi(1,:,:)).') ;
        dbs = db(amp) ;
                
%         % 不用转置的方式
%         amp2 = abs(squeeze(csi(1,:,:))) ;
%         rx1amp2(i,:) = amp2(1,:) ;
%         % 未对齐到perm中
%         rx1amp(:,i) = amp(:,1) ;
%         rx3db(:,i) = dbs(:,3) ;   
        
        % 对齐perm, perm(3,2,1)对应天线3在chain1上
        for j = 1:length(csi_entry.perm)
            % 第csi_entry.perm[j]号rx天线，在csi索引j中
            rxno = csi_entry.perm(j) ;
            %disp(rxno*100 + j) ;
            % 天线号*30子载波*包数
            rxlamp(rxno,:,i) = amp(:,j) ;
            rxdb(rxno,:,i) = dbs(:,j) ;
        end
    end

    ys = squeeze(rxdb(1,20:2:30,:)) ;
    ys = squeeze(rxdb(3,:,:)) ;
    % ys: 30子载波 * 包数
    step = size(ys, 2) ; % step选包数
    disp(size(ys));

    global gx;
    hold on
    plot(gx:gx+step-1, ys);
    %axis([gx-step gx+step -5 30]);
    axis([gx-step gx+step -10 40]);
    gx = gx + step - 1 ;
end


