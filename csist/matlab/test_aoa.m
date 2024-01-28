clear all;
close all;

addpath("../libs/matlab-libs");
addpath("../algorithm/iaa");
addpath("/home/flq/ws/git/SpotFi");

calib_file = "/flqtmp/wdata/in/ppo/incsi-64ht20-ppo.mat";
ppo = load(calib_file).ppo.ppo;
[11, mean(ppo.ppo12), mean(ppo.ppo13)]
%ppo.ppo12 = ppo.ppo12 - pi;
ppo.ppo13 = ppo.ppo13 - pi;
[22, mean(ppo.ppo12), mean(ppo.ppo13)]

iax_calib_file = "/flqtmp/wdata/ppo/iax-13ht20-ppo.mat";
iax_calib_file = "iax-13ht20-ppo.mat";
iax_ppo = load(iax_calib_file);

global gs;
gs.ppo = ppo;

is_realtime = false;
is_realtime = true;

sts = {};
aoas = [];
if is_realtime
	input_name = "tcp-server:127.0.0.1:7120"; csi_type = csietr.Type.I53;
	input_name = "/tmp/iax.csi"; csi_type = csietr.Type.IAX;
	input_name = "tcp-client:127.0.0.1:7120"; csi_type = csietr.Type.IAX;
	s = csietr(input_name, csi_type);
	%s.set("debug", true);

	while ~s.is_end()
		st = s.read_next()
		sts{end+1} = st;

    	%[-2,-1.4]
		if s.type == csietr.Type.I53
    		st = csietr.calib_ppo(st, ppo.ppo12, ppo.ppo13);
		else
			gs.fc = 2.472e9;
			gs.d = 0.028;
			[mean(iax_ppo.ppo12)]
			%csiutils.plot_ppo12(st.csi(1,:,:));
			st = iaxcsi.calib_csi_perm_ppo_qtr_lambda(st.dbg, iax_ppo.ppo12, true);
			if isempty(st); continue; end
			st = s.convert_csist(st);
		end
		%handle_st(st);
    	aoas(end+1) = do_aoa(st);
	end
else
	sts = load("incsi.mat").csi_sts; 
	for i = 1:length(sts)
		st = sts{i};
		handle_st(st);
    	aoas(end+1) = do_aoa(st);
	end
end

function handle_st(st)
	global gs;

    subp = [1, 2];
    csiutils.plot_ppo(st.csi(1,1,:), st.csi(1,2,:), [subp,1]);
	if st.nrx > 2
    csiutils.plot_ppo(st.csi(1,1,:), st.csi(1,end,:), [subp,2]);
	end

	%pause;
end

function aoa = do_aoa(st)
	aoa_func = @do_iaa ; algo_name = "iaa";
	aoa_func = @do_spotfi ; algo_name = "spotfi";
    aoa = aoa_func(st);
    csiutils.plot_aoa(aoa, 15, algo_name);
end

function aoa = do_spotfi(st)
	global gs;
	envs = spotfi_envs() ;
	envs.fc = 5.32e9 ;
	envs.d = 0.028 ;
	envs.fc = gs.fc;
	envs.d = gs.d;
	envs.lambda = envs.c / envs.fc ;
	envs.nrx = st.nrx ;
	envs.ntx = st.ntx ;
	envs.ntone = st.ntone ;
	envs.ntone_sm = floor(envs.ntone/2) ;
	envs.subc_idxs = st.subcs ;
	envs.pmufig = true;
	envs.pmufig = false;
	envs.niter = 1 ;
	%envs

    envs.nrx = 3;
    envs.nrx = 2;
    csi = st.csi(1,1:envs.nrx,:);
	aoa = spotfi(squeeze(csi), envs, -1) 
end

function aoa = do_iaa(st)
	global gs;
	envs = iaa_envs() ;
	envs.nrx = st.nrx ;
	envs.ntone = st.ntone ;
	envs.subcs = st.subcs ;
	envs.fc = 5.32e9 ;
	envs.d = 0.028 ;
	envs.fc = gs.fc;
	envs.d = gs.d;
	envs.f_space = 312.5e3 ;
	envs.fc_space = envs.f_space ;

    envs.nrx = 3;
    envs.nrx = 2;
    csi = st.csi(1,1:envs.nrx,:);
	aoa = iaa(squeeze(csi), envs)
end	
