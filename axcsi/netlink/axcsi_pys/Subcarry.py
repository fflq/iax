
class Subcarry:
    class Subc:
        list_offset = None
        subcs = None
        csi_subcs = None
        pilot_subcs = None
        dc_subcs = None
        pilot_dc_subcs = None

    @staticmethod
	def get_subc_info(chan_type_str):
		match (chan_type_str):
			case "NOHT20": 
                subc = Subcarry.get_subc_noht20() ;

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


	def st = get_subc_base(st)
		st.subcs_list_offset = st.subcs_radius + 1 ;
		st.subcs = [-st.subcs_radius:st.subcs_radius] ;
		st.subcs_len = length(st.subcs) ;
		st.csi_subcs = sort([-st.csi_subcs, st.csi_subcs]) ;
		st.pilot_subcs = sort([-st.pilot_subcs, st.pilot_subcs]) ;
		st.dc_subcs = sort([-st.nozero_dc_subcs, 0, st.nozero_dc_subcs]) ;
		st.pilot_dc_subcs = sort([st.pilot_subcs, st.dc_subcs]) ;
	end


	% NOHT
	def st = get_subc_noht20()
		st.subcs_num = [48, 52] ;
		st.subcs_radius = 26 ;
		st.csi_subcs = [1:26] ;
		st.pilot_subcs = [7, 21] ;
		st.nozero_dc_subcs = [] ;
		st = Subcarry.get_subc_base(st) ;
	end


	% HT
	def st = get_subc_ht20()
		st.subcs_num = [52, 56] ;
		st.subcs_radius = 28 ;
		st.csi_subcs = [1:28] ;
		st.pilot_subcs = [7, 21] ;
		st.nozero_dc_subcs = [] ;
		st = Subcarry.get_subc_base(st) ;
	end

	def st = get_subc_ht40()
		st.subcs_num = [108, 114] ;
		st.subcs_radius = 58 ;
		st.csi_subcs = [2:58] ;
		st.pilot_subcs = [11, 25, 53] ;
		st.nozero_dc_subcs = [1] ;
		st = Subcarry.get_subc_base(st) ;
	end


	% VHT
	def st = get_subc_vht80()
		st.subcs_num = [234, 242] ;
		st.subcs_radius = 122 ;
		st.csi_subcs = [2:122] ;
		st.pilot_subcs = [11, 39, 75, 103] ;
		st.nozero_dc_subcs = [1] ;
		st = Subcarry.get_subc_base(st) ;
	end

	def st = get_subc_vht160()
		st.subcs_num = [468, 484] ;
		st.subcs_radius = 250 ;
		st.csi_subcs = [6:126, 130:250] ;
		st.pilot_subcs = [25, 53, 89, 117, 139, 167, 203, 231] ;
		st.nozero_dc_subcs = [1:5, 127:129] ;
		st = Subcarry.get_subc_base(st) ;
	end


	% HE
	def st = get_subc_he20()
		st = get_subc_ht20() ;
	end

	def st = get_subc_he40()
		st = get_subc_ht40() ;
	end

	def st = get_subc_he80()
		st.subcs_num = [234, 242] ;
		st.subcs_radius = 122 ;
		st.csi_subcs = [2:122] ;
		st.pilot_subcs = [11, 39, 75, 103] ;
		st.nozero_dc_subcs = [1] ;
		st = Subcarry.get_subc_base(st) ;
	end

	def st = get_subc_he160()
		st.subcs_num = [468, 484] ;
		st.subcs_radius = 250 ;
		st.csi_subcs = [6:126, 130:250] ;
		st.pilot_subcs = [25, 53, 89, 117, 139, 167, 203, 231] ;
		st.nozero_dc_subcs = [1:5, 127:129] ;
		st = Subcarry.get_subc_base(st) ;
	end
