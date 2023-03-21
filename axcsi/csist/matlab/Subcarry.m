
classdef Subcarry < handle

properties (Constant)
	range_end = 0 ; % for matlab, noneed. for py, need=1
	subc_space = 312.5 ;
	subc_space2 = 78.125 ;
end	
	
methods (Static)

	function subc = get_subc(chan_type_str)
		switch(chan_type_str)
			case "NOHT20"; subc = Subcarry.get_subc_noht20() ;

			case {"HT20", "VHT20"}; subc = Subcarry.get_subc_ht20() ;
			case {"HT40", "VHT40"}; subc = Subcarry.get_subc_ht40() ;

			case "VHT80"; subc = Subcarry.get_subc_vht80() ;
			case "VHT160"; subc = Subcarry.get_subc_vht160() ;

			case "HE20"; subc = Subcarry.get_subc_he20() ;
			case "HE40"; subc = Subcarry.get_subc_he40() ;
			case "HE80"; subc = Subcarry.get_subc_he80() ;
			case "HE160"; subc = Subcarry.get_subc_he160() ;

			otherwise; subc = Subcarry.get_subc_noht20() ;
		end
	end


	% for st.data_pilot_dc_subcs = [-st.subcs_radius:st.subcs_radius] ;
	% not csi_tones, it hasnt dc_tones
	function st = gen_subc_common(subcs_radius, data_pilot_subcs, pilot_subcs, dc_subcs)
		% __init__
		st = struct() ;
		st.subcs_radius = subcs_radius ;
		st.data_pilot_subcs = data_pilot_subcs ;
		st.pilot_subcs = pilot_subcs ;
		st.dc_subcs = dc_subcs ;

		st.subcs = [-st.subcs_radius:st.subcs_radius+Subcarry.range_end] ;
		st.subcs_len = length(st.subcs) ;

		% preproc
		st.data_pilot_subcs = union(-st.data_pilot_subcs, st.data_pilot_subcs) ;
		st.csi_subcs = st.data_pilot_subcs ;
		st.pilot_subcs = union(-st.pilot_subcs, st.pilot_subcs) ;
		st.dc_subcs = union(-st.dc_subcs, st.dc_subcs) ;

		st.data_subcs = setdiff(st.data_pilot_subcs, st.pilot_subcs) ;
		st.pilot_dc_subcs = union(st.pilot_subcs, st.dc_subcs) ;
		st.data_pilot_dc_subcs = union(st.pilot_dc_subcs, st.data_subcs) ;

		st.subcs_nums = [length(st.dc_subcs), length(st.pilot_subcs), length(st.data_subcs), ... 
			length(st.csi_subcs), length(st.data_pilot_dc_subcs)] ;

		if st.subcs_len ~= st.subcs_nums(5)
			error("* data_pilot_dc_subcs(%d) != subcs(%d)", st.subcs_len, st.subcs_nums(5)) ;
		end

		% add offset
		st.subcs_list_offset = st.subcs_radius + 1 ;
		st.idx_data_subcs = st.data_subcs + st.subcs_list_offset ;
		st.idx_data_pilot_subcs = st.data_pilot_subcs + st.subcs_list_offset ;
		st.idx_pilot_dc_subcs = st.pilot_dc_subcs + st.subcs_list_offset ;
		st.idx_data_pilot_dc_subcs = st.data_pilot_dc_subcs + st.subcs_list_offset ;
	end


	% NOHT
	function st = get_subc_noht20()
		%st = Subcarry.gen_subc_common(26, [1:26+Subcarry.range_end], [7,21], [0]) ;
		st = Subcarry.gen_subc_common(26, [1:26], [7,21], [0]) ;
	end


	% HT
	function st = get_subc_ht20()
		st = Subcarry.gen_subc_common(28, [1:28], [7,21], [0]) ;
	end

	function st = get_subc_ht40()
		st = Subcarry.gen_subc_common(58, [2:58], [11,25,53], [0,1]) ;
	end


	% VHT
	function st = get_subc_vht80()
		st = Subcarry.gen_subc_common(122, [2:122], [11,39,75,103], [0,1]) ;
	end

	function st = get_subc_vht160()
		st = Subcarry.gen_subc_common(250, [6:126, 130:250], ...
			[25, 53, 89, 117, 139, 167, 203, 231], [0:5, 127:129]) ;
	end


	% HE
	function st = get_subc_he20()
		st = Subcarry.gen_subc_common(122, [2:122], [22,48,90,116], [0,1]) ;
	end

	function st = get_subc_he40()
		st = Subcarry.gen_subc_common(244, [3:244], [10,36,78,104,144,170,212,238], [0:2]) ;
	end

	function st = get_subc_he80()
		st = Subcarry.gen_subc_common(500, [3:500], [24,92,158,226,266,334,400,468], [0:2]) ;
	end

	function st = get_subc_he160()
		st = Subcarry.gen_subc_common(1012, [12:1012], ...
			[44,112,178,246,286,354,420,488,536,604,670,738,778,846,912,980], [1:11]) ;
	end


end

end

