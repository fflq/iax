%{
libs: file_handler, socket_handler, endian, csiutils, csi_handler_base
%}

classdef fiaxcsi < iaxcsi

properties (Access='public')
end

methods (Access='public')
	function self = fiaxcsi(input_name)
		self@iaxcsi(input_name);
	end

	function hdr_st = get_csi_hdr_st(self, hdr_buf) 
		hdr_st = self.get_csi_hdr_st@iaxcsi(hdr_buf);

		hdr_st.channel = hdr_buf(217);
		%{
		hdr_st.w1 = endian.le16u(hdr_buf(249:250)) + double(hdr_buf(261)) + endian.le16u(hdr_buf(265:266));
		hdr_st.w2 = endian.le16u(hdr_buf(249+4:250+4)) + double(hdr_buf(261+2)) + endian.le16u(hdr_buf(265+2:266+2));
		hdr_st.woff = double(hdr_st.w2) - double(hdr_st.w1);
		%}
	end

	function st = fill_csist(self, hdr_st, rnf_st, csi)
		st = self.fill_csist@iaxcsi(hdr_st, rnf_st, csi);
		st.channel = hdr_st.channel ;
		%st.perm = 1:st.nrx;
		st = self.calib_csi_perm(st) ; %call by hand
	end
end

methods (Static)

	function test_st(st)
		st
		subc = st.subc ;
		tones = squeeze(st.csi(1,1,:)) ;
		stones = squeeze(st.scsi(1,1,:)) ;

		title(st.rate_bw_type);
		plot(subc.subcs, abs(stones), 'LineWidth',2) ; hold on;
		plot(subc.subcs(1:length(tones)), abs(tones)-10, 'LineWidth',2) ; hold on;
	end

	function st = calib_csi_perm_ppo_qtr_lambda(st, plus_ppos, do_plot)
		if nargin < 3; do_plot = false; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,1]); end

		st = fiaxcsi.calib_csi_perm(st);
		if ~fiaxcsi.is_calib_perm_valid(st); return; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,2]); end

		st = fiaxcsi.calib_csi_dppo_qtr_lambda(st, plus_ppos);
		if ~fiaxcsi.is_calib_dppo_valid(st); return; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,3]); end
	end

	function st = calib_csi_perm_ppo(st, plus_ppos, do_plot)
		if nargin < 3; do_plot = false; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,1]); end

		st = fiaxcsi.calib_csi_perm(st);
		if ~fiaxcsi.is_calib_perm_valid(st); return; end
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,2]); end

		st = fiaxcsi.calib_csi_ppo(st, plus_ppos);
		if do_plot; csiutils.plot_ppo12(st.scsi(:,1,:), [1,3,3]); end
	end

	function r = is_calib_perm_valid(st)
		r = ~isfield(st, "permw") || st.permw >= 0.2;
		if ~r; warning("permw=%f\n", st.permw); end
	end

	function r = is_calib_dppo_valid(st)
		r = ~isfield(st, "dppow") || st.dppow >= 0.2;
		if ~r; warning("dppow=%f\n", st.dppow); end
	end

	function r = is_calib_valid(st)
		r = fiaxcsi.is_calib_perm_valid(st) && fiaxcsi.is_calib_dppo_valid(st);
	end

	%convert [k,b] to ppos
	function r_ppos = convert_from_ppos(st, ppos)
		if length(ppos) == 2
			ppos_kb = ppos;
			r_ppos = ppos_kb(1)*st.subc.subcs + ppos_kb(2);
		else
			r_ppos = ppos;
		end
		if isrow(r_ppos); r_ppos = r_ppos.'; end
		%[ppo1,ppo2] => [exp(1j*ppo1),exp(1j*ppo2)]
		%complex avoid 0 value
		if isreal(r_ppos); r_ppos = complex(exp(1j*r_ppos)); end
	end

	%ppos or [k,b]
	function st = calib_csi_ppo(st, plus_ppos)
		if st.nrx < 2
			return;
		end

		plus_ppos = fiaxcsi.convert_from_ppos(st, plus_ppos);

		for i = 1:st.ntx
			st.scsi(2,i,:) = squeeze(st.scsi(2,i,:)) .* conj(plus_ppos);
			%st.csi(2,i,:) = squeeze(st.csi(2,i,:)) .* conj(plus_ppos);
		end
	end

	%ppos or [k,b]
	function [st, w] = calib_csi_dppo_qtr_lambda(st, plus_ppos)
		st.dppow = 0;

		if st.nrx < 2
			st.dppow = 1;
			return;
		end

		plus_ppos = fiaxcsi.convert_from_ppos(st, plus_ppos);

		%judge ppo12 by subc0
		csi1 = squeeze(st.scsi(1,1,:));
		csi2 = squeeze(st.scsi(2,1,:));
		subc0_idx = find(st.subc.subcs == 0);
		subc0_po = angle(csi2(subc0_idx) .* conj(csi1(subc0_idx)));
		po_to_ppo = wrapToPi(subc0_po - angle(plus_ppos(subc0_idx)));

		%judge if hop pi under qtr lambda ant dist
		is_hop_pi = false;
		if abs(po_to_ppo) > pi/2
			warning("** abs(po_to_ppo(%.2f)) > pi/2, hop pi\n", po_to_ppo);
			is_hop_pi = true;
		end
		%calc dppo right weight, maxw for 0 or pi, for [-pi/2,pi/2], [pi/2,3pi/2]
		w = 1 - abs(wrapToPi(po_to_ppo - double(is_hop_pi)*pi)) / (pi/2);
		st.dppow = w;

		%minus pi
		%wrong, need calib plus_ppos first, then judge extra pi.
		dppo_ppos = plus_ppos * exp(-1j*double(is_hop_pi)*pi); 
		%complex avoid 0 value
		st = fiaxcsi.calib_csi_ppo(st, complex(dppo_ppos));
	end

end

end
