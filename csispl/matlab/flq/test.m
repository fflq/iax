


global gx;
gx=0;

recv_from_file();
% recv_from_remote();

function recv_from_file()
    for i = (1:1:5)
        handle_csi_cells(read_bf_file('../netlink/26csi.dat')) ;
        break ;
    end
end

function recv_from_remote()
    ufd = udpport("byte", "LocalPort", 7020, "EnablePortSharing", true, "ByteOrder", "big-endian");
    disp(ufd) ;
    
    while true
        try
        len = read(ufd, 1, 'uint16') ;
        disp(len) ;
        % datatype是数值类型的，返回的是double数组，手册说的
        buf = read(ufd, len, 'uint8') ;
        data = uint8(buf') ;
        %disp(char(buf));
        handle_csi_cells(read_bf_packet(data)) ;
        catch E
            disp(E) ;
        end
    end
end




% n*(1*1 struct) cell
function handle_csi_cells(csi_cells)
    fprintf ("cells: %d\n", length(csi_cells)) ;
    
    disp(csi_cells{1,1});
    for i = 1:length(csi_cells)
        disp("* cell "+i) ;
        handle_csi_struct(csi_cells{i,1});
        %break ;
    end
end

function handle_csi_struct(csi_struct)
    % chmats,csi_struct.csi: ntx*nrx*30
    chmats = get_scaled_csi(csi_struct) ;
    disp(size(chmats));
    
    for i = 1:csi_struct.Ntx
        disp("    ** tx"+i) ;
        handle_chmat(chmats(i,:,:));
        %break ;
    end
%     aa=cat(3, chmats(1,:,:), chmats(2,:,:));
%     disp(size(aa));
%     handle_chmat(aa);

    
    csis = csi_struct.csi ;
    for i = 1:length(csis)
        %disp("    ** csi"+i) ;
        handle_csi(csis(i)) ;
    end
end


function handle_csi(csi)
end

% chmat: nrx*30; chdb: 30*nrx; chdb(:,1)': 1*30
function handle_chmat(chmat)
    % A'是复共e转置，A.'对复矩阵只是单纯转置
    %disp(chmat);
    chdb = db(abs(squeeze(chmat).')) ;
    hold on
    %plot(chdb);
    plot_n(chdb(:,1)');
    %pause(0.2);
end

function plot_n(dbs)
    step = length(dbs) ;

    global gx;
    plot(gx:gx+step-1, dbs);
    axis([0 gx+step+5 0 30]);
    %legend('A','B','C','Location','NorthEast');
    xlabel('Subcarrier index');
    ylabel('SNR/dB');

    gx = gx+step ;
end














