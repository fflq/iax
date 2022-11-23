%clear all;
%close all;
%addpath('../../') ;


function view_csi(reload)
	sts = load_csi(reload) ;

	phaseoff = [] ;
	len = length(sts) ;
	for i = 1:len
		if ~mod(i, 1000)
			fprintf("- %d/%d\n", i, len) ;
		end
		csi_st = sts{1,i} ;

		csi = squeeze(csi_st.csi) ;
		angleoffs12 = angle( csi(2,:) .* conj(csi(1,:)) ) ;  
		phaseoff(end+1) = mean(angleoffs12) ;
		%fprintf("- %d, %d, 12(%f)\n", i, length(phaseoff), mean(phaseoff)) ;
		%Util.plot_realtime1(1, phaseoff) ;

		%fprintf("- %s\n", csi_st.mac) ;
		%Util.plot_realtime1(1, csi_st.csi) ;
		%plot_csi(csi_st.csi) ;
		%input('-') ;
		%pause(0.001) ;

		stats_macs(csi_st, false) ;
	end
	stats_macs([], true) ;
end

function sts = load_csi(reload)
	filename = "../netlink/ax.csi" ;
	savename = "./axcsi.mat" ;
	if reload || ~exist(savename)
		fprintf("* reload %s\n", filename) ;
		sts = read_ax2xx_csi(filename, savename) ;
	else
		sts = load(savename).sts ;
	end
end


function stats_macs(st, print)
	persistent map ;
	if isempty(map)
		map = containers.Map() ;
	end
	if (print)
		macs = keys(map) ;
		macns = values(map) ; 
		for i = 1:length(macs)
			fprintf("-%d. %s %d\n", i, macs{1,i}, macns{1,i});
		end
		return ;
	end

	key = st.mac ;
	if any(strcmp(keys(map),key))
		map(key) = map(key) + 1 ;
	else
		map(key) = 1 ;
	end
end


function plot_csi(csi)
	csi = squeeze(csi(:,1,:)) ;
	csi_phase = unwrap(angle(csi.')) ;
	%csi_phase = angle(csi.') ;
	csi_mag = abs(csi.') ;
	%plot(csi_phase) ;
	plot(csi_mag) ;
	pause(0.01) ;
end


function map_sts(sts)
	map = containers.Map() ;
	for i = 1:length(sts)
		st = sts{i} ;
		csi_len_str = int2str(st.csi_len) ;
		if any(strcmp(keys(map),csi_len_str))
			map(csi_len_str) = [map(csi_len_str); st] ;
		else
			map(csi_len_str) = st ;
		end
	end
	map_keys = keys(map) ;
	map_vals = values(map) ;
	for i = 1:length(map_keys)
		[str2num(map_keys{i}), length(map_vals{i})]
	end
	sts = map('416') ;
	save("axcsi_nonht20.mat", 'sts');
	sts = map('448') ;
	save("axcsi_ht20.mat", 'sts');
	sts = map('1824') ;
	save("axcsi_ht40.mat", 'sts');
	sts = map('3872') ;
	save("axcsi_vht80.mat", 'sts');
end



