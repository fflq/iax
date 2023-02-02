%clear all;
%close all;
%addpath('../../../libs/') ;


function view_csi(filename, reload)
	sts = load_csi(filename, reload) ;

	phaseoff = [] ;
	len = length(sts) ;
	for i = 1:len
		if ~mod(i, 1000)
			fprintf("- %d/%d\n", i, len) ;
		end
		csist = sts{1,i} ;

		%plot_csi(csist.csi);
		%plot_mag(csist) ;
		%plot_phase(csist) ;
		plot_phase_offset(csist) ;
	
	end
	%stats_macs([], true) ;
end


function plot_phase(csist)
	subc = csist.subc ;
	tones = squeeze(csist.csi(1,1,:)) ;
	stones = squeeze(csist.scsi(1,1,:)) ;

	title(csist.chan_type_str);
	%hold off;
	hold on;
	plot(subc.subcs, unwrap(angle(stones))-2, 'LineWidth',2) ; 
	%plot(subc.subcs, angle(stones)+20, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), unwrap(angle(tones))-20, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), angle(tones)-50, 'LineWidth',2) ; 
	input('a') ;
end


function plot_mag(csist)
	subc = csist.subc ;
	tones = squeeze(csist.csi(1,1,:)) ;
	stones = squeeze(csist.scsi(1,1,:)) ;

	title(csist.chan_type_str);
	hold on;
	plot(subc.subcs, abs(stones)-2, 'LineWidth',2) ; 
	%plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; 
	input('a') ;
end


function plot_phase_offset(csist)
	persistent phaseoff
	if isempty(phaseoff)
		phaseoff = [] ;
	end
	scsi = squeeze(csist.scsi(:,1,:)) ;
	angleoffs12 = angle( scsi(2,:) .* conj(scsi(1,:)) ) ;  
	%phaseoff(end+1) = mean(angleoffs12) ;
	phaseoff(end+1) = angleoffs12(1) ;
	%fprintf("- %d, %d, 12(%f)\n", i, length(phaseoff), mean(phaseoff)) ;
	Util.plot_realtime1(1, phaseoff) ;
	hold on;
	%scatter(csist.subc.subcs, angleoffs12, 'o', 'LineWidth',2) ;
	pause(0.1) ;
	%input('a') ;

	%stats_macs(csist, false) ;
end
		


function sts = load_csi(filename, reload)
	%filename = "../netlink/ax.csi" ;
	savename = "./axcsi.mat" ;
	if reload || ~exist(savename)
		fprintf("* reload %s\n", filename) ;
		sts = read_axcsi(filename, savename) ;
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
	plot(csi_phase) ;
	%plot(csi_mag) ;
	pause(0.01) ;
	input('-') ;
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



