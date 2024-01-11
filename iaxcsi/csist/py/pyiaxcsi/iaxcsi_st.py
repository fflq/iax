#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# sudo pip3 install libnl3 numpy seaborn 

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from pyiaxcsi.iwl_fw_api_rs import *
from pyiaxcsi.subcarry import subcs_st, subcarry_st

from pyiaxcsi.utils import utils


class csi_st:
    csi_len:int; seq:int; us:int; us2:int; ts:int; ftm:int
    smac: str

    rnf:int; chan_width:int; ant_sel:int; ldpc:int; mcs_index:int
    mod_type_str:str; chan_type_str:str

    rssi1:int; rssi2:int; nrx:int; ntx:int; ntone:int; nstone:int

    # csi in ant-order
    csi:np.array
    scsi: np.array
    subc: subcs_st
    # add, change ant-order to chain-order
    perm: np.array

    test_perm:int

    def calib_scsi_by_phaoff12_only(self, first_phaoff):
        for i in range(self.ntx):
            self.scsi[1,i] = self.scsi[1,i] * np.exp(-1j*first_phaoff)

    # d=lambda/4
    #def calib_scsi_by_phaoff12(self, first_phaoff=0.68):
    #def calib_scsi_by_phaoff12(self, first_phaoff=2.30):
    def calib_scsi_by_phaoff12(self, first_phaoff=2.71):
        first_phaoff_ranges = np.array([-np.pi/2, np.pi/2]) + first_phaoff
        phaoff12 = np.unwrap(np.angle(self.scsi[1,0] * np.conj(self.scsi[0,0])))
        avg_phaoff12 = np.mean(phaoff12)
        avg_phaoff12 = avg_phaoff12 if avg_phaoff12 > 0 else avg_phaoff12+2*np.pi
        #print('before avg_phaoff12 {}'.format(avg_phaoff12))
        # judge a or a-pi
        if not (first_phaoff_ranges[0] < avg_phaoff12 < first_phaoff_ranges[1]):
            first_phaoff = first_phaoff - np.pi
        for i in range(self.ntx):
            self.scsi[1,i] = self.scsi[1,i] * np.exp(-1j*first_phaoff)


    @DeprecationWarning
    def calib_scsi_by_chain_phaoff12_old(self, chain_phaoff12):
        chan2 = 2-1
        if np.all(self.perm == np.array([2,1])):
            chan2 = 1-1
        chan2 = 1
        print('chan2: ', chan2)
        for i in range(self.ntx):
            self.scsi[chan2,i] = self.scsi[chan2,i] * np.exp(-1j*chain_phaoff12)


    def get_chain_scsi(self):
        ccsi = np.copy(self.scsi)
        for i in range(self.ntx):
            ccsi[:,i] = ccsi[self.perm-1,i]
        return ccsi



class iaxcsi_st:
    endian = 'little'
    csi_hdr = None
    csi_data = None
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

    chan_type_str_set = [ "NOHT20", "HT20", "HT40", "VHT20", "VHT40", 
                         "VHT80", "VHT160", "HE20", "HE40", "HE80", "HE160"]


    def __init__(self, csi_hdr, csi_data, endian='little'):
        self.csi_hdr = csi_hdr
        self.csi_data = csi_data
        self.endian = endian
        self.csist = csi_st()
        self.handle_nmsg_csi(csi_hdr, csi_data)
        #utils.output_hexs(csi_hdr, False)
        utils.output_hexs(csi_hdr[240:], False)


    def handle_nmsg_csi(self, csi_hdr, csi_data):
        # csi_hdr
        self.handle_csi_hdr(csi_hdr, self.endian)
        # rnf
        self.handle_rate_n_flags(self.csist.rnf)
        if (self.chan_type_str_set.count(self.csist.chan_type_str) <= 0):
            print("* wrong chan_type_str(%s)" % (self.csist.chan_type_str))
            print(self.csist.__dict__)
            self.csist = None
            return
        print(self.csist.__dict__)
        print("rnf(%x)" % (self.csist.rnf))
        # csi
        self.handle_csi(csi_data, self.endian)
        # for scsi calib subcs and perm
        self.handle_csi_subcs()
        self.handle_chain_perm()


    # nocertain(always chain1-pw > chain2-pw, ant-map-chain by ant pw).
    # wrong(rssin is in chain order, so always (chain1-pw==rssi1) > (chain2-pw==rssi2)).
    # 20230210
    # (*key*)by testing have-or-not-ant rssis changes, got rssin is in ant order.
    # so if [pw(csi1) > pw(csi2)] != [rssi1 > rssi2],
    ## means csi-order is not same as rssi-order(ant-order), perm=[2,1]
    # mosttime(chain1-pw > chain2-pw), lesstime-rev(two ant, all no ant)(may sel delay),
    ## certain(~)(one no ant)(pw diff large)
    # assume csi-order only in {ant-order, chain-order},
    ## due to csi-phaoff is wrong, so csi-order == ant-order.
    #@DeprecationWarning
    def handle_chain_perm(self):
        self.csist.perm = np.array([1])
        if self.csist.nrx < 2:
            return
        self.csist.perm = np.array([1, 2])


        # use csi not scsi, no interp
        pw1 = np.sum(np.abs(self.csist.csi[0,0])**2)/1e4
        pw2 = np.sum(np.abs(self.csist.csi[1,0])**2)/1e4
        pws1 = np.abs(self.csist.csi[0,0])
        pws2 = np.abs(self.csist.csi[1,0])
        ppo12 = np.unwrap(np.angle(self.csist.scsi[1,0] * np.conj(self.csist.scsi[0,0])))
        z = np.polyfit(range(len(ppo12)), ppo12, 1)
        print("* k(%f) b(%f) ppo(%f)" % (z[0], z[1], np.mean(ppo12)))

        if abs(self.csist.rssi1-self.csist.rssi2) < 2 or abs(pw1-pw2)/pw1 < 0.25:
            print("* pw rssi perm:", pw1, pw2, self.csist.rssi1, self.csist.rssi2)
            print("* perm func pass this csist")
            #self.csist = None; return

        # way1: alway pw1>pw2, diff from ant-order, so chain-order
        #if not (pw1 >= pw2): 
        #if not (self.csist.rssi1 >= self.csist.rssi2):
        # way2: obs from i53, pw and rssi are same order
        # and need rssi diff > 1+, cause some diff order in i53 that rssi diff is small.
        # ok2 in calib, but in air: >10 and notxant(rxrssi<-50)
        #if (pw1 >= pw2) != (self.csist.rssi1 > self.csist.rssi2):
        # way3: k != 0
        #if z[0] > 0:
        # way4: may test_perm field in csi_hdr
        #if self.csist.test == 1:

        #20240106:before perm, always bigger csi-pw first, so only judge rssi.
        # if not first, cause by similar offs(rssis)<2, just ignore.
        #20230320:but always somes against rssi or pw conds
        #if all(pws1 > pws2) != (self.csist.rssi1 > self.csist.rssi2):
        #if (pw1 > pw2) != (self.csist.rssi1 > self.csist.rssi2):
        if self.csist.rssi1 < self.csist.rssi2:
        #if dk > 0:
            self.csist.perm = np.array([2, 1])
            # change to ant-order
            for i in range(self.csist.ntx):
                pass; print("*********** pass perm")
                #self.csist.scsi[:,i] = self.csist.scsi[self.csist.perm-1,i]
        print("* pw rssi perm:", pw1, pw2, self.csist.rssi1, self.csist.rssi2, self.csist.perm)
        #here nerver (pw1 >= pw2) != (self.csist.rssi1 >= self.csist.rssi2):


    def handle_rate_n_flags(self, rnf):
        # Bits 3-0: MCS
        self.csist.mcs_index = RATE_HT_MCS_INDEX(rnf & RATE_MCS_CODE_MSK)

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
                    #[real, imag] = [imag, real]
                    pos = pos + 4
                    csi[irx,itx,itone] = real + 1j*imag
        self.csist.csi = csi


    # interp complex num by (mag,phase)
    def do_complex_interp(self, xv, x, y):
        mag = np.interp(xv, x, np.abs(y))
        #no unwrap then yv-unwrap-phase will fluctuate
        #phase = np.interp(xv, x, np.angle(y))
        phase = np.interp(xv, x, np.unwrap(np.angle(y)))
        return mag * np.exp(1j*phase)


    def handle_csi_subcs(self):
        # handle special
        csi = self.csist.csi
        if self.csist.chan_type_str == "VHT160": 
            csi = csi[:,:,subcarry_st.get_vht160_noextra_subc(self.csist.ntone)]
        elif self.csist.chan_type_str == "HE160":
            csi = csi[:,:,subcarry_st.get_he160_noextra_subc(self.csist.ntone)]

        subc = subcarry_st.get_subc(self.csist.chan_type_str)
        scsi = np.zeros((self.csist.nrx, self.csist.ntx, subc.subcs_len), dtype=complex)
        data_pilot_dc_tones = np.zeros(subc.subcs_len, dtype=complex)

        for irx in range(self.csist.nrx):
            for itx in range(self.csist.ntx):
                csi_data_pilot_tones = csi[irx, itx]
                data_pilot_dc_tones[subc.idx_data_pilot_subcs] = csi_data_pilot_tones

                # for raw_csi, only data_tones valid
                xv, x = subc.idx_pilot_dc_subcs, subc.idx_data_subcs
                data_pilot_dc_tones[xv] = self.do_complex_interp(xv, x, data_pilot_dc_tones[x])
                scsi[irx,itx] = data_pilot_dc_tones

        self.csist.scsi = scsi
        self.csist.subc = subc
        self.csist.nstone = len(subc.subcs)


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
        self.csist.us2 = int.from_bytes(csi_hdr[200:204], endian)
        self.csist.ts = int.from_bytes(csi_hdr[208:216], endian)

        self.csist.test_perm = int(csi_hdr[180])


    def perm_csi(csist, new_perm):
        csist.perm = new_perm
        for i in range(csist.ntx):
            #pass; print("*********** pass perm")
            csist.scsi[:,i] = csist.scsi[csist.perm-1,i]

 
    #def fit_csi(self, tones, xs):
    def fit_csi(tones, xs):
        mag = np.abs(tones)
        ang = np.angle(tones)
        uwphase = np.unwrap(ang)
        #xs = np.arange(len(tones))
        z = np.polyfit(xs, uwphase, 1)
        k, b = z[0], z[1]
        print("* k(%f) b(%f)" % (k, b))
        pha = uwphase - k*xs
        pha = uwphase - k*xs - b
        pha = uwphase - b
        #sns.lineplot(x=xs, y=pha)
        tones = mag*np.exp(1j*pha)
        return [k,b,tones]
        return pha

