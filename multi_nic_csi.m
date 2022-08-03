clear all ;
close all ;
addpath('./csilibs') ;

server = CSIServer() ;
global tscell ;
tss = zeros(2,0) ;
tscell = cell(10,1) ;
n = 1 ;
while true
	csi_st = server.read_csi() ; 
	if (isempty(csi_st))
		pause(2) ;
		continue ;
	end
	csi = get_scaled_csi(csi_st) ;
	csi = squeeze(csi) ;
	fprintf("*%d, %d, %f, 4/%d, 8/%d\n", n, csi_st.pci, csi_st.timestamp_low/1e6, length(tscell{1}), length(tscell{2})) ;

	if (csi_st.pci == 4000)
		tscell{1}(end+1) = csi_st.timestamp_low/1e6 ;
	end
	if (csi_st.pci == 8000)
		tscell{2}(end+1) = csi_st.timestamp_low/1e6 ;
	end
	if (n >= 20)
		tscell{1} = sort(tscell{1}) ;
		tscell{2} = sort(tscell{2}) ;
		%[tscell{1}.', tscell{2}.']
		%break ;
	end

	%draw_ts(csi_st) ;
	%draw_db(csi_st.pci/1000, csi(1,10)) ;

	n = n + 1 ;
	pause(0.0001) ;
end

function draw_ts(csi_st)
	global tscell ;
	persistent pciids ;
	if (isempty(pciids))
		pciids = [] ;
	end
	pciid = csi_st.pci/1000 ;
	if (~any(find(pciids==pciid)))
		pciids(end+1) = pciid ;
	end

	tscell{pciid}(end+1) = csi_st.timestamp_low/1e6 ;

	figure(11); hold on ;
	skip = 5 ;
	c = size(tscell{pciid},2) ; 
	if (c > skip)
		plot(c-skip:c, tscell{pciid}(c-skip:c)) ;
	end

	if (length(pciids) >= 2)
		pciid1 = pciids(1) ;
		c1 = size(tscell{pciid1},2) ; 
		pciid2 = pciids(2) ;
		c2 = size(tscell{pciid2},2) ; 
		if (c1 == c2)
		minlen = min(c1,c2) ;
		off = tscell{pciid2}(1:minlen) - tscell{pciid1}(1:minlen) ;
		figure(12); hold on;
		plot(off) ;
		end
	end
end

function draw_db(fid, csi)
	persistent n csis ;
	if (isempty(n))
		n = 0 ;
		csis = cell(10,1) ;
	end
	csis{fid}(end+1,:) = angle(csi) ;
	%csis{fid}(end+1,:) = angle(csi) + fid*10;
	n = size(csis{fid},1) ;

	figure(fid) ; hold on ;
	%plot(db(abs(csi).')) ;
	%plot(n, angle(csi)) ;
	skip = 5 ;
	if (n > skip)
		plot(n-skip:n, csis{fid}(n-skip:n,:)) ;
	end
	%legend('RA', 'RB', 'RC') ;
end
