clear all;
close all;

addpath("../libs/matlab-libs");
addpath("../algorithm/iaa");
addpath("/home/flq/ws/git/SpotFi");

calib_file = "/flqtmp/wdata/in/ppo/incsi-64ht20-ppo.mat";
input_name = "tcp-server:127.0.0.1:7120";
s = csietr(input_name, csietr.Type.I53);
%s.set("debug", true);

ppo = load(calib_file).ppo.ppo;
ppo.ppo12 = ppo.ppo12 - pi;
[mean(ppo.ppo12), mean(ppo.ppo13)]
while ~s.is_end()
    st = s.read_next()

    %[-2,-1.4]
    st = csietr.calib_ppo(st, ppo.ppo12, ppo.ppo13);

    subp = [1, 2];
    csiutils.plot_ppo(st.csi(1,1,:), st.csi(1,2,:), [subp,1], true);
    csiutils.plot_ppo(st.csi(1,1,:), st.csi(1,3,:), [subp,2], true);

    do_aoa(st);
end

function do_aoa(st)
	aoa_func = @do_spotfi ; algo_name = "spotfi";
	aoa_func = @do_iaa ; algo_name = "iaa";
    aoa = aoa_func(st);
    csiutils.plot_aoa(aoa, 15, algo_name);
end

function aoa = do_spotfi(st)
	envs = spotfi_envs() ;
	envs.fc = 5.32e9 ;
	envs.d = 0.026 ;
	envs.lambda = envs.c / envs.fc ;
	envs.nrx = st.nrx ;
	envs.ntx = st.ntx ;
	envs.ntone = st.ntone ;
	envs.ntone_sm = floor(envs.ntone/2) ;
	envs.subc_idxs = st.subcs ;
	envs.pmufig = true;
	envs.pmufig = false;
	envs.niter = 2 ;
	%envs

    envs.nrx = 3;
    envs.nrx = 2;
    csi = st.csi(1,1:envs.nrx,:);
	aoa = spotfi(squeeze(csi), envs, -1) 
end

function aoa = do_iaa(st)
	envs = iaa_envs() ;
	envs.nrx = st.nrx ;
	envs.ntone = st.ntone ;
	envs.subcs = st.subcs ;
	envs.fc = 5.32e9 ;
	envs.d = 0.026 ;
	envs.f_space = 312.5e3 ;
	envs.fc_space = envs.f_space ;

    envs.nrx = 3;
    envs.nrx = 2;
    csi = st.csi(1,1:envs.nrx,:);
	aoa = iaa(squeeze(csi), envs)
end	
