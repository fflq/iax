#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from iwl_fw_api_rs import *
from subcarry import subcarry_st


class csi_st:
    csi_len:int; seq:int; us:int; ftm:int
    smac: str

    rnf:int; chan_width:int; ant_sel:int; ldpc:int
    mod_type_str:str; chan_type_str:str

    rssi1:int; rssi2:int; nrx:int; ntx:int; ntone:int

    csi:np.array
    scsi: np.array
    subc: subcarry_st


class axcsi_st:
    endian = 'little'
    csi_hdr = None
    csist: csi_st = None

    mod_type_map = {
        RATE_MCS_CCK_MSK: "CCK", 
        RATE_MCS_LEGACY_OFDM_MSK: "NOHT", 
        RATE_MCS_HT_MSK: "HT", 
        RATE_MCS_VHT_MSK: "VHT", 
        RATE_MCS_HE_MSK: "HE", 
        RATE_MCS_EHT_MSK: "EH", 
    } 

    he_type_map = {
        RATE_MCS_HE_TYPE_SU: "HE-SU", 
        RATE_MCS_HE_TYPE_EXT_SU: "HE-EXT-SU", 
        RATE_MCS_HE_TYPE_MU: "HE-MU", 
        RATE_MCS_HE_TYPE_TRIG: "HE-TRIG", 
    }

    chan_width_map = {
        RATE_MCS_CHAN_WIDTH_20: 20, 
        RATE_MCS_CHAN_WIDTH_40: 40, 
        RATE_MCS_CHAN_WIDTH_80: 80, 
        RATE_MCS_CHAN_WIDTH_160: 160, 
        RATE_MCS_CHAN_WIDTH_320: 320, 
    }


    def __init__(self, csi_hdr, csi_data, endian='little'):
        #self.csi_hdr = csi_hdr
        self.endian = endian
        self.csist = csi_st()
        self.handle_nmsg_csi(csi_hdr, csi_data)


    def handle_nmsg_csi(self, csi_hdr, csi_data):
        # csi_hdr
        self.handle_csi_hdr(csi_hdr, self.endian)
        # rnf
        self.handle_rate_n_flags(self.csist.rnf)
        print(self.csist.__dict__)
        # csi
        self.handle_csi(csi_data, self.endian)
        self.handle_csi_subcs()


    def handle_rate_n_flags(self, rnf):
        # Bits 10-8: rate format, mod type
        rate_mcs_mod_type = rnf & RATE_MCS_MOD_TYPE_MSK 
        self.csist.mod_type = rate_mcs_mod_type >> RATE_MCS_MOD_TYPE_POS 
        self.csist.mod_type_str = self.mod_type_map[rate_mcs_mod_type]

        # Bits 24-23: HE type
        if self.csist.mod_type == (RATE_MCS_HE_MSK>>RATE_MCS_MOD_TYPE_POS):
            rate_mcs_he_type = rnf & RATE_MCS_HE_TYPE_MSK 
            self.csist.he_type = rate_mcs_he_type >> RATE_MCS_HE_TYPE_POS 
            self.csist.he_type_str = self.he_type_map[rate_mcs_he_type]

        # Bits 13-11: chan width
        rate_mcs_chan_width = rnf & RATE_MCS_CHAN_WIDTH_MSK 
        self.csist.chan_width_type = rate_mcs_chan_width >> RATE_MCS_CHAN_WIDTH_POS 
        self.csist.chan_width = self.chan_width_map[rate_mcs_chan_width] 

        self.csist.chan_type_str = self.csist.mod_type_str + str(self.csist.chan_width)

        # Bits 15-14: antenna selection
        self.csist.ant_sel = (rnf & RATE_MCS_ANT_MSK) >> RATE_MCS_ANT_POS ; 

        # Bits 16: LDPC enables
        self.csist.ldpc = (rnf & RATE_MCS_LDPC_MSK) >> RATE_MCS_LDPC_POS ; 

        '''
        print("* mod_type(%u,%s) he_type(%d,%s) chan_width_type(%u,%u) ant_sel(%u) ldpc(%u)\n" %
                (csist.mod_type, csist.mod_type_str, csist.he_type, csist.he_type_str, 
                csist.chan_width_type, csist.chan_width, csist.ant_sel, csist.ldpc)) ;
        '''


    def handle_csi(self, csi_data, endian):
        pos = 0
        csi = np.zeros((self.csist.nrx, self.csist.ntx, self.csist.ntone), dtype=complex)
        for irx in range(self.csist.nrx):
            for itx in range(self.csist.ntx):
                for itone in range(self.csist.ntone):
                    imag = int.from_bytes(csi_data[pos:pos+2], endian, signed=True)
                    real = int.from_bytes(csi_data[pos+2:pos+4], endian, signed=True)
                    pos = pos + 4
                    csi[irx,itx,itone] = real + 1j*imag
        self.csist.csi = csi


    def handle_csi_subcs(self):
        #if csist.chan_type_str == "VHT160": return 
        subc = subcarry_st.get_subc(self.csist.chan_type_str)
        scsi = np.zeros((self.csist.nrx, self.csist.ntx, subc.subcs_len), dtype='complex')
        data_pilot_dc_tones = np.zeros(subc.subcs_len, dtype=complex)

        for irx in range(self.csist.nrx):
            for itx in range(self.csist.ntx):
                csi_data_pilot_tones = self.csist.csi[irx, itx]
                data_pilot_dc_tones[subc.idx_data_pilot_subcs] = csi_data_pilot_tones

                # interp complex num by (mag,phase)
                # for raw_csi, only data_tones valid
                x = subc.idx_data_subcs
                mag = np.interp(subc.idx_data_pilot_dc_subcs, x, np.abs(data_pilot_dc_tones[x]))
                phase = np.interp(subc.idx_data_pilot_dc_subcs, x, np.angle(data_pilot_dc_tones[x]))
                x = subc.idx_pilot_dc_subcs
                data_pilot_dc_tones[x] = mag[x] * np.exp(1j*phase[x])
                scsi[irx,itx] = data_pilot_dc_tones

        self.csist.scsi = scsi
        self.csist.subc = subc


    def handle_csi_hdr(self, csi_hdr, endian):
        self.csist.csi_len = int.from_bytes(csi_hdr[0:4], endian)
        self.csist.ftm = int.from_bytes(csi_hdr[8:12], endian)
        self.csist.nrx = int(csi_hdr[46])
        self.csist.ntx = int(csi_hdr[47])
        self.csist.ntone = int.from_bytes(csi_hdr[52:56], endian)
        self.csist.rssi1 = -int(csi_hdr[60])
        self.csist.rssi2 = -int(csi_hdr[64])
        #self.csist.smac = ':'.join(csi_hdr[68:74].hex())
        self.csist.smac = ':'.join([hex(b)[2:] for b in csi_hdr[68:74]])
        self.csist.seq = int(csi_hdr[76])
        self.csist.us = int.from_bytes(csi_hdr[88:92], endian)
        self.csist.rnf = int.from_bytes(csi_hdr[92:96], endian)


 