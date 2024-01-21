
classdef csist < handle

properties (Constant)
	CsiOrder = struct('TX_RX_TONE', 1, 'RX_TX_TONE', 2);
end

properties (Access='public')
	seq = -1;
	us = -1; 
	ts = -1;
	protocol = -1;
	bw = -1; 
	chan = -1;
	chan_type = "";
	nrx = -1; ntx = -1; ntone = -1;
	rnf = -1; noise = -1; agc = -1;
	smac = ""; dmac = "";
	rssi = [];
	perm = [];
	subcs = [];
	%tx*rx*tone
	csi = [];
	csi_order = csist.CsiOrder.TX_RX_TONE;
	dbg = [];
	type = -1;
end

methods (Access='public')
	function self = csist()
	end
end


methods (Static)

end

end
