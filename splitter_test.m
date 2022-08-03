clear all ;
close all ;
addpath('./csilibs') ;

server = CSIServer() ;
n = 1 ;
rssia = [] ;
rssib = [] ;
while true
	csi_st = server.read_csi() ;
	if (isempty(csi_st))
		pause(2) ;
		continue ;
	end
	if (csi_st.pci ~= 4000)
		continue ;
	end
	csi_st 
	csi = get_scaled_csi(csi_st) ;
	csi = squeeze(csi) ;
	%fprintf("*%d, %d, %f\n", n, csi_st.pci, csi_st.timestamp_low/1e6) ;

	rssia(end+1) = csi_st.rssi_a ;
	rssib(end+1) = csi_st.rssi_b ;
	hold on ;
	plot(rssia) ;
	plot(rssib,'--') ;
	legend('rx1', 'rx2') ;

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


