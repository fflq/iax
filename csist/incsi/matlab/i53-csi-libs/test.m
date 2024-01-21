addpath("C:\Users\flq\OneDrive\flqdata\paper")
addpath('/media/flq/M_Linux/winhome/2023')
in_ipo = {};

sts = read_bf_file("in_ipo1221.csi")
for i = 1:length(sts)
    perm = sts{i}.perm;
    if all(perm == [1,2,3]) || all(perm == [2,1,3])
        in_ipo{end+1} = sts{i};
    end
end

sts = read_bf_file("in_ipo1331.csi");
for i = 1:length(sts)
    perm = sts{i}.perm;
    if all(perm == [1,3,2]) || all(perm == [3,1,2])
        in_ipo{end+1} = sts{i};
    end
end

sts = read_bf_file("in_ipo2332.csi");
for i = 1:length(sts)
    perm = sts{i}.perm;
    if all(perm == [2,3,1]) || all(perm == [3,1,2])
        in_ipo{end+1} = sts{i};
    end
end

sts = in_ipo;
%save("in_ipo_6perm_in_12", "sts")


phaoffs12 = [];
for i = 1:length(sts)
    st = sts{i};
    csi = squeeze(sts{i}.csi(1,:,:));
    csi(st.perm,:) = csi(:,:);
    phaoff12 = unwrap(angle(csi(2,:) .* conj(csi(1,:))));
    plot(phaoff12); hold on; drawnow()
    phaoffs12(:,end+1) = phaoff12;
    input("")
end