
classdef subcarry < handle

properties (Constant)
	range_end = 0 ; % for matlab, noneed. for py, need=1
	subc_space = 312.5 ;
	subc_space2 = 78.125 ;
end	
	
methods (Static)

	%data+pilot should 484, but csi get 498
	function r = get_vht160_noextra_subc(ntone)
		r = subcarry.get_noextra_subc(ntone, 484);
	end

	%data+pilot should 1992, but csi get 2020
	function r = get_he160_noextra_subc(ntone)
		r = subcarry.get_noextra_subc(ntone, 1992);
	end

	% extra subc is part dc
	function r = get_noextra_subc(ntone, ntone_data_plot)
		half_extra = int32((ntone - ntone_data_plot) / 2) ;
		half = int32(ntone / 2);
		r = union(1:half-half_extra, half+half_extra+1:ntone);
	end


	function subc = get_subc(chan_type_str)
		switch(chan_type_str)
			case "NOHT20"; subc = subcarry.get_subc_noht20() ;

			case {"HT20", "VHT20"}; subc = subcarry.get_subc_ht20() ;
			case {"HT40", "VHT40"}; subc = subcarry.get_subc_ht40() ;

			case "VHT80"; subc = subcarry.get_subc_vht80() ;
			case "VHT160"; subc = subcarry.get_subc_vht160() ;

			case "HE20"; subc = subcarry.get_subc_he20() ;
			case "HE40"; subc = subcarry.get_subc_he40() ;
			case "HE80"; subc = subcarry.get_subc_he80() ;
			case "HE160"; subc = subcarry.get_subc_he160() ;

			otherwise; subc = subcarry.get_subc_noht20() ;
		end
	end


	% for st.data_pilot_dc_subcs = [-st.subcs_radius:st.subcs_radius] ;
	% not csi_tones, it hasnt dc_tones
	%function st = gen_subc_common(subcs_radius, data_pilot_subcs, pilot_subcs, dc_subcs)
	function st = gen_subc_common(subcs_radius, pos_data_pilot_subcs, pos_pilot_subcs)
		% __init__
		st = struct() ;
		%st.subcs_radius = subcs_radius ;
		%st.data_pilot_subcs = data_pilot_subcs ;
		%st.pilot_subcs = pilot_subcs ;
		%st.dc_subcs = dc_subcs ;

		% preproc
		st.subcs = [-subcs_radius:subcs_radius+subcarry.range_end] ;
		st.data_pilot_subcs = union(-pos_data_pilot_subcs, pos_data_pilot_subcs) ;
		st.csi_subcs = st.data_pilot_subcs ;
		st.pilot_subcs = union(-pos_pilot_subcs, pos_pilot_subcs) ;

		st.dc_subcs = setdiff(st.subcs, st.data_pilot_subcs);
		st.data_subcs = setdiff(st.data_pilot_subcs, st.pilot_subcs) ;
		st.pilot_dc_subcs = union(st.pilot_subcs, st.dc_subcs) ;
		st.data_pilot_dc_subcs = union(st.pilot_dc_subcs, st.data_subcs) ;

		st.subcs_len = length(st.subcs) ;
		st.subcs_nums = [length(st.dc_subcs), length(st.pilot_subcs), length(st.data_subcs), ... 
			length(st.csi_subcs), length(st.data_pilot_dc_subcs)] ;

		if st.subcs_len ~= st.subcs_nums(5)
			error("* data_pilot_dc_subcs(%d) != subcs(%d)", st.subcs_len, st.subcs_nums(5)) ;
		end

		% add offset
		st.subcs_list_offset = subcs_radius + 1 ;
		st.idx_data_subcs = st.data_subcs + st.subcs_list_offset ;
		st.idx_data_pilot_subcs = st.data_pilot_subcs + st.subcs_list_offset ;
		st.idx_pilot_dc_subcs = st.pilot_dc_subcs + st.subcs_list_offset ;
		st.idx_data_pilot_dc_subcs = st.data_pilot_dc_subcs + st.subcs_list_offset ;
	end


	% NOHT
	function st = get_subc_noht20()
		%st = subcarry.gen_subc_common(26, [1:26+subcarry.range_end], [7,21], [0]) ;
		st = subcarry.gen_subc_common(26, [1:26], [7,21]) ;
	end


	% HT
	function st = get_subc_ht20()
		st = subcarry.gen_subc_common(28, [1:28], [7,21]) ;
	end

	function st = get_subc_ht40()
		st = subcarry.gen_subc_common(58, [2:58], [11,25,53]) ;
	end


	% VHT
	function st = get_subc_vht80()
		st = subcarry.gen_subc_common(122, [2:122], [11,39,75,103]) ;
	end

	function st = get_subc_vht160()
		pilot_subcs = [25, 53, 89, 117, 139, 167, 203, 231];
		pilot_subcs = union(pilot_subcs, [190:194]); %self add
		st = subcarry.gen_subc_common(250, [6:126, 130:250], pilot_subcs);
	end


	% HE
	function st = get_subc_he20()
		st = subcarry.gen_subc_common(122, [2:122], [22,48,90,116]) ;
	end

	function st = get_subc_he40()
		st = subcarry.gen_subc_common(244, [3:244], [10,36,78,104,144,170,212,238]) ;
	end

	function st = get_subc_he80()
		st = subcarry.gen_subc_common(500, [3:500], [24,92,158,226,266,334,400,468]) ;
	end

	function st = get_subc_he160()
		%pilot_subcs = [44,112,178,246,286,354,420,488, 536,604,670,738,778,846,912,980];
		pilot_subcs = subcarry.get_subc_he80().pilot_subcs + 512; % from 80211ax doc
		pilot_subcs = union(pilot_subcs, [766:770]); %self add
		st = subcarry.gen_subc_common(1012, [12:509, 515:1012], pilot_subcs);
	end


end

end

