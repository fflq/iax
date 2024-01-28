clear all;
close all;

input_name = "/flqtmp/i53/i53_phaoffs.csi";
input_name = "/tmp/in.csi";
input_name = "tcp-server:127.0.0.1:7120"; csi_type = csietr.Type.I53;
input_name = "tcp-client:127.0.0.1:7120"; csi_type = csietr.Type.IAX;
s = csietr(input_name, csi_type);
%s.set("debug", true);

calib_file = "/flqtmp/wdata/ppo/iax-13ht20-ppo.mat";
ppo12 = load(calib_file).ppo12;

ppo12s = [];
ppo13s = [];
while ~s.is_end()
    st = s.read_next()
    %continue;
    csi1 = squeeze(st.csi(1,1,:));
    csi2 = squeeze(st.csi(1,2,:));
    csi3 = squeeze(st.csi(1,end,:));

	%st = iaxcsi.calib_csi_perm_ppo_qtr_lambda(st.dbg, ppo12, true); continue;

    %mag
    %figure(11); hold off; plot(abs(squeeze(st.csi(1,:,:)).')); legend("1", "2", "3");
    %ppo
    ppo12 = unwrap(angle(squeeze(csi2 .* conj(csi1))));
    ppo13 = unwrap(angle(squeeze(csi3 .* conj(csi1))));
    ppo12s(end+1,:) = ppo12;
    ppo13s(end+1,:) = ppo13;
    subp = [2, 1];
    subp = [1, 2];
    csiutils.plot_ppo(csi1, csi2, [subp,1], true);
    csiutils.plot_ppo(csi1, csi3, [subp,2], true);

    %pause
end

