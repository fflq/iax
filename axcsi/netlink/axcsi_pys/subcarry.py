import numpy as np
from dataclasses import dataclass


@dataclass
class subcs_st:
	subcs_list_offset: int
	subcs: np.array
	subcs_len: int
	subcs_nums: int
	subcs_radius: int
	csi_subcs: np.array
	data_pilot_subcs: np.array
	pilot_subcs: np.array
	dc_subcs: np.array
	data_subcs: np.array
	pilot_dc_subcs: np.array
	data_pilot_dc_subcs: np.array
	idx_data_subcs: np.array
	idx_data_pilot_subcs: np.array
	idx_pilot_dc_subcs: np.array
	idx_data_pilot_dc_subcs: np.array

	def __init__(self, subcs_radius:int, data_pilot_subcs:np.array, 
			pilot_subcs:np.array, dc_subcs:np.array):
		self.subcs_radius = subcs_radius
		self.data_pilot_subcs = data_pilot_subcs
		self.pilot_subcs = pilot_subcs
		self.dc_subcs = dc_subcs
		self.gen_subc_common()

	def gen_subc_common(self):
		self.subcs = np.arange(-self.subcs_radius,self.subcs_radius+subcarry_st.range_end) 
		self.subcs_len = len(self.subcs) 

		# preproc
		self.data_pilot_subcs = np.union1d(-self.data_pilot_subcs, self.data_pilot_subcs)
		self.csi_subcs = self.data_pilot_subcs 
		self.pilot_subcs = np.union1d(-self.pilot_subcs, self.pilot_subcs)
		self.dc_subcs = np.union1d(-self.dc_subcs, self.dc_subcs)

		self.data_subcs = np.setdiff1d(self.data_pilot_subcs, self.pilot_subcs)
		self.pilot_dc_subcs = np.union1d(self.pilot_subcs, self.dc_subcs)
		self.data_pilot_dc_subcs = np.union1d(self.pilot_dc_subcs, self.data_subcs)

		self.subcs_nums = [ len(self.dc_subcs), len(self.pilot_subcs), len(self.data_subcs), 
			len(self.csi_subcs), len(self.data_pilot_dc_subcs), ]

		if self.subcs_len != self.subcs_nums[4]:
			print(self.subcs_nums)
			raise RuntimeError("* data_pilot_dc_subcs(%d) != subcs(%d)" % 
				(self.subcs_len, self.subcs_nums[4]))

		# add offset for array ops
		self.subcs_list_offset = self.subcs_radius 
		self.idx_data_subcs = self.data_subcs + self.subcs_list_offset
		self.idx_data_pilot_subcs = self.data_pilot_subcs + self.subcs_list_offset
		self.idx_pilot_dc_subcs = self.pilot_dc_subcs + self.subcs_list_offset
		self.idx_data_pilot_dc_subcs = self.data_pilot_dc_subcs + self.subcs_list_offset



class subcarry_st:

	# py range is [), so right+1
	range_end: int = 1 
	subc_map: dict = None

	
	# init not by static func, will wrong 
	@staticmethod
	def set_subc_map():
		subcarry_st.subc_map = {
			# NOHT
			"NOHT20": subcarry_st.noht20_subc(),
			# HT
			"HT20": subcarry_st.ht20_subc(),
			"HT40": subcarry_st.ht40_subc(),

			# VHT
			"VHT20": subcarry_st.ht20_subc(),
			"VHT40": subcarry_st.ht40_subc(),
			"VHT80": subcarry_st.vht80_subc(),
			"VHT160": subcarry_st.vht160_subc(),
			# HE
			"HE20": subcarry_st.he20_subc(),
			"HE40": subcarry_st.he40_subc(),
			"HE80": subcarry_st.he80_subc(),
			# HE160 cant recv, but VHT160 can, c-HE160 can
			"HE160": subcarry_st.he160_subc(),
		}


	@staticmethod
	def get_subc(chan_type_str) -> subcs_st:
		if not subcarry_st.subc_map:
			subcarry_st.set_subc_map()
		return subcarry_st.subc_map[chan_type_str]


	# NOHT
	@staticmethod
	def noht20_subc():
		return subcs_st(
			subcs_radius = 26 ,
			data_pilot_subcs = np.arange(1, 26+subcarry_st.range_end) ,
			pilot_subcs = np.array([7, 21]) ,
			dc_subcs = np.array([0]) ,
		)


	# HT
	@staticmethod
	def ht20_subc():
		return subcs_st(
			subcs_radius = 28 ,
			data_pilot_subcs = np.arange(1, 28+subcarry_st.range_end) ,
			pilot_subcs = np.array([7, 21]) ,
			dc_subcs = np.array([0]) ,
		)

	@staticmethod
	def ht40_subc():
		return subcs_st(
			subcs_radius = 58 ,
			data_pilot_subcs = np.arange(2, 58+subcarry_st.range_end) ,
			pilot_subcs = np.array([11, 25, 53]) ,
			dc_subcs = np.array([0, 1]) ,
		)


	# VHT
	@staticmethod
	def vht80_subc():
		return subcs_st(
		    subcs_radius = 122 ,
		    data_pilot_subcs = np.arange(2, 122+subcarry_st.range_end) ,
		    pilot_subcs = np.array([11, 39, 75, 103]) ,
		    dc_subcs = np.array([0, 1]) ,
		)


	# fit to axcsi, diff from doc
	@staticmethod
	def vht160_subc():
		#nums[17, 16, 484-16, 484, 501]
		#but get csi(498) may = data_pilot484 + part_dc14, no other dc3[-1,0,1]
		return subcs_st(
			subcs_radius = 250, 
			#st.data_pilot_subcs = [6:126, 130:250] 
			data_pilot_subcs = np.union1d(
				np.arange(6, 126+subcarry_st.range_end), 
				np.arange(130, 250+subcarry_st.range_end)
			),
			pilot_subcs = np.array([25, 53, 89, 117, 139, 167, 203, 231]),
			#st.dc_subcs = [0:5, 127:129] 
			dc_subcs = np.union1d(
				#np.arange(0, 5+Subcarry.range_end),
				np.arange(0, 5+subcarry_st.range_end),
				np.arange(127, 129+subcarry_st.range_end)
			)
		)


	@staticmethod
	def doc_vht160_subc():
		return subcs_st(
			subcs_radius = 250,
			#st.data_pilot_subcs = [6:126, 130:250] 
			data_pilot_subcs = np.union1d(
				np.arange(6, 126+subcarry_st.range_end), 
				np.arange(130, 250+subcarry_st.range_end)
			),
			pilot_subcs = np.array([25, 53, 89, 117, 139, 167, 203, 231]),
			#st.dc_subcs = [0:5, 127:129] 
			dc_subcs = np.union1d(
				np.arange(0, 5+subcarry_st.range_end),
				np.arange(127, 129+subcarry_st.range_end)
			),
		)


	subc_space = 312.5
	subc_space2 = 78.125


	# HE
	@staticmethod
	def he20_subc():
		#[3, 8, 234, 242, 245]
		return subcs_st(
			subcs_radius = 122,
			data_pilot_subcs = np.arange(2, 122+subcarry_st.range_end),
			pilot_subcs = np.array([22, 48, 90, 116]),
			dc_subcs = np.arange(0, 1+subcarry_st.range_end),
		)



	@staticmethod
	def he40_subc():
		#[5, 16, 468, 484, 489]
		return subcs_st(
			subcs_radius = 244,
			data_pilot_subcs = np.arange(3, 244+subcarry_st.range_end),
			pilot_subcs = np.array([10, 36, 78, 104, 144, 170, 212, 238]),
			dc_subcs = np.arange(0, 2+subcarry_st.range_end),
		)


	@staticmethod
	def he80_subc():
		#[5, 16, 980, 996, 1001]
		return subcs_st(
			subcs_radius = 500,
			data_pilot_subcs = np.arange(3, 500+subcarry_st.range_end),
			pilot_subcs = np.array([24, 92, 158, 226, 266, 334, 400, 468]),
			dc_subcs = np.arange(0, 2+subcarry_st.range_end),
		)



	@staticmethod
	def he160_subc():
		#subcs_nums[23, 32, 2002-32, 2002, 2025]
		#but get csi(2020) may = 
		return subcs_st(
			subcs_radius = 1012,
			data_pilot_subcs = np.arange(12, 1012+subcarry_st.range_end),
			pilot_subcs = np.array([44, 112, 178, 246, 286, 354, 420, 488, 
				536, 604, 670, 738, 778, 846, 912, 980]),
			dc_subcs = np.arange(0, 11+subcarry_st.range_end),
		)

