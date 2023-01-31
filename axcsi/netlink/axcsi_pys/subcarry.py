import numpy as np
from dataclasses import dataclass
from functools import reduce


@dataclass
class SubcData:
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
		self.subcs = np.arange(-self.subcs_radius,self.subcs_radius+Subcarry.range_end) 
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
			raise RuntimeError("* data_pilot_dc_subcs(%d) != subcs(%d)" % 
				(self.subcs_len, self.subcs_nums[4]))

		# add offset for array ops
		self.subcs_list_offset = self.subcs_radius 
		self.idx_data_subcs = self.data_subcs + self.subcs_list_offset
		self.idx_data_pilot_subcs = self.data_pilot_subcs + self.subcs_list_offset
		self.idx_pilot_dc_subcs = self.pilot_dc_subcs + self.subcs_list_offset
		self.idx_data_pilot_dc_subcs = self.data_pilot_dc_subcs + self.subcs_list_offset



class Subcarry:

	# py range is [), so right+1
	range_end: int = 1 
	subc_map: dict = None

	
	# init not by static func, will wrong 
	@staticmethod
	def set_subc_map():
		Subcarry.subc_map = {
			# NOHT
			"NOHT20": Subcarry.noht20_subc(),
			# HT
			"HT20": Subcarry.ht20_subc(),
			"HT40": Subcarry.ht40_subc(),

			# VHT
			"VHT20": Subcarry.ht20_subc(),
			"VHT40": Subcarry.ht40_subc(),
			"VHT80": Subcarry.vht80_subc(),
			#"VHT160": Subcarry.vht160_subc(),
			# HE
			"HE20": Subcarry.he20_subc(),
			"HE40": Subcarry.he40_subc(),
			"HE80": Subcarry.he80_subc(),
			# HE160 cant recv, but VHT160 can, c-HE160 can
			"HE160": Subcarry.he160_subc(),
		}


	@staticmethod
	def get_subc(chan_type_str) -> SubcData:
		if not Subcarry.subc_map:
			Subcarry.set_subc_map()
		return Subcarry.subc_map[chan_type_str]


	# NOHT
	@staticmethod
	def noht20_subc():
		return SubcData(
			subcs_radius = 26 ,
			data_pilot_subcs = np.arange(1, 26+Subcarry.range_end) ,
			pilot_subcs = np.array([7, 21]) ,
			dc_subcs = np.array([0]) ,
		)


	# HT
	@staticmethod
	def ht20_subc():
		return SubcData(
			subcs_radius = 28 ,
			data_pilot_subcs = np.arange(1, 28+Subcarry.range_end) ,
			pilot_subcs = np.array([7, 21]) ,
			dc_subcs = np.array([0]) ,
		)

	@staticmethod
	def ht40_subc():
		return SubcData(
			subcs_radius = 58 ,
			data_pilot_subcs = np.arange(2, 58+Subcarry.range_end) ,
			pilot_subcs = np.array([11, 25, 53]) ,
			dc_subcs = np.array([0, 1]) ,
		)


	# VHT
	@staticmethod
	def vht80_subc():
		return SubcData(
		    subcs_radius = 122 ,
		    data_pilot_subcs = np.arange(2, 122+Subcarry.range_end) ,
		    pilot_subcs = np.array([11, 39, 75, 103]) ,
		    dc_subcs = np.array([0, 1]) ,
		)


	# fit to axcsi, diff from doc
	@staticmethod
	def vht160_subc():
		return SubcData(
			subcs_radius = 250, 
			#st.data_pilot_subcs = [6:126, 130:250] 
			data_pilot_subcs = np.union1d(
				np.arange(6, 126+Subcarry.range_end), 
				np.arange(130, 250+Subcarry.range_end)
			),
			pilot_subcs = np.array([25, 53, 89, 117, 139, 167, 203, 231]),
			#st.dc_subcs = [0:5, 127:129] 
			dc_subcs = np.union1d(
				#np.arange(0, 5+Subcarry.range_end),
				np.arange(2, 5+Subcarry.range_end),
				np.arange(127, 129+Subcarry.range_end)
			)
		)


	@staticmethod
	def doc_vht160_subc():
		return SubcData(
			subcs_radius = 250,
			#st.data_pilot_subcs = [6:126, 130:250] 
			data_pilot_subcs = np.union1d(
				np.arange(6, 126+Subcarry.range_end), 
				np.arange(130, 250+Subcarry.range_end)
			),
			pilot_subcs = np.array([25, 53, 89, 117, 139, 167, 203, 231]),
			#st.dc_subcs = [0:5, 127:129] 
			dc_subcs = np.union1d(
				np.arange(0, 5+Subcarry.range_end),
				np.arange(127, 129+Subcarry.range_end)
			),
		)


	subc_space = 312.5
	subc_space2 = 78.125


	# HE
	@staticmethod
	def he20_subc():
		return SubcData(
		subcs_radius = 122,
		data_pilot_subcs = np.arange(2, 122+Subcarry.range_end),
		pilot_subcs = np.array([22, 48, 90, 116]),
		dc_subcs = np.arange(0, 1+Subcarry.range_end),
		)



	@staticmethod
	def he40_subc():
		return SubcData(
			subcs_radius = 244,
			data_pilot_subcs = np.arange(3, 244+Subcarry.range_end),
			pilot_subcs = np.array([10, 36, 78, 104, 144, 170, 212, 238]),
			dc_subcs = np.arange(0, 2+Subcarry.range_end),
		)


	@staticmethod
	def he80_subc():
		return SubcData(
			subcs_radius = 500,
			data_pilot_subcs = np.arange(3, 500+Subcarry.range_end),
			pilot_subcs = np.array([24, 92, 158, 226, 266, 334, 400, 468]),
			dc_subcs = np.arange(0, 2+Subcarry.range_end),
		)



	@staticmethod
	def he160_subc():
		return SubcData(
			subcs_radius = 1012,
			data_pilot_subcs = np.arange(3, 1012+Subcarry.range_end),
			pilot_subcs = np.array([44, 112, 178, 246, 286, 354, 420, 488, 536, 
				604, 670, 738, 778, 846, 912, 980]),
			dc_subcs = np.arange(0, 11+Subcarry.range_end),
		)

