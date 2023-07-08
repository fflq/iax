#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import struct
#from utils import utils


class csi_st:
    nrx: int; ntx: int; ntone: int;
    rssi_a: int; rssi_b: int; rssi_c: int;
    timestamp_low: int;
    bfee_count: int;
    noise: int;
    agc: int;
    rate: int;
    perm: np.array
    csi: np.array


class incsi_st:
    csist: csi_st = None

    def __init__(self, csi_data):
        self.csist = csi_st()
        self.handle_csi_data(csi_data)
        self.get_scaled_csi()


    def get_scaled_csi(self):
        csi_sq = self.csist.csi * np.conj(self.csist.csi)
        csi_pwr = sum(csi_sq)
        rssi_pwr = self.dbinv(self.get_total_rss())
        scale = rssi_pwr / (csi_pwr / 30)

        noise_db = self.csist.noise
        if (self.csist.noise == -127):
            noise_db = -92

        thermal_noise_pwr = 0
        quant_error_pwr = scale * (self.csist.nrx * self.csist.ntx)
        total_noise_pwr = thermal_noise_pwr + quant_error_pwr

        ret = self.csist.csi * np.sqrt(scale / total_noise_pwr)
        if (self.csist.ntx == 2):
            ret = ret * np.sqrt(2)
        elif (self.csist.ntx == 3):
            ret = ret * np.sqrt(self.dbinv(4.5))
        self.csist.csi = ret


    def dbinv(self, x):
        return 10**(x/10)


    def get_total_rss(self):
        rssi_mag = 0
        rssis = [self.csist.rssi_a, self.csist.rssi_b, self.csist.rssi_c]
        for rssi in rssis:
            if rssi != 0:
                rssi_mag = rssi_mag + self.dbinv(rssi)

        db = lambda x : 10*np.log10(x)
        return db(rssi_mag) - 44 - self.csist.agc


    def handle_csi_data(self, csi_data):
        code = csi_data[0]
        if (code != 187):
            return

        self.read_bfee(csi_data[1:])
        if (np.sum(self.csist.perm) != 6):
            print("* invalid perm ", self.csist.perm)
            self.csist = None
            return

        for i in range(self.csist.ntx):
            self.csist.csi[i, :] = self.csist.csi[i, self.csist.perm-1]


    def read_bfee(self, data):
        #utils.output_hexs(data)
        pos = 0
        self.csist.timestamp_low = struct.unpack("<I", data[pos:pos+4])[0]
        pos = pos + 4
        self.csist.bfee_count = struct.unpack("<H", data[pos:pos+2])[0]
        pos = pos + 2
        pos = pos + 2; # reserverd
        self.csist.nrx = data[pos]
        self.csist.ntx = data[pos+1]
        self.csist.ntone = 30
        pos = pos + 2
        self.csist.rssi_a = data[pos]
        self.csist.rssi_b = data[pos+1]
        self.csist.rssi_c = data[pos+2]
        pos = pos + 3
        self.csist.noise = struct.unpack("b", data[pos:pos+1])[0]
        self.csist.agc = data[pos+1]
        antenna_sel = data[pos+2]
        self.csist.perm = np.array([((antenna_sel) & 0x3) + 1, 
                           ((antenna_sel >> 2) & 0x3) + 1,
                           ((antenna_sel >> 4) & 0x3) + 1])
        pos = pos + 3
        length = struct.unpack("<H", data[pos:pos+2])[0]
        pos = pos + 2
        self.csist.rate = struct.unpack("<H", data[pos:pos+2])[0]
        pos = pos + 2
        payload = data[pos:]

        calc_length = int((30 * (self.csist.nrx * self.csist.ntx * 8 * 2 + 3) + 7) / 8)
        if (length != calc_length):
            print("* Wrong beamforming matrix size {} != {}.", length, calc_length)
            self.csist = None
            return

        print(self.csist.__dict__)
        self.read_csi_mat(payload)


    def read_csi_mat(self, data):
        index = 0
        remainder = 0
        to_int8 = lambda x : (((x&0xFF) + 128) & 0xFF) - 128  # must mutil-()
        self.csist.csi = np.zeros([self.csist.ntx, self.csist.nrx, self.csist.ntone], dtype=complex)
        for itone in range(self.csist.ntone):
            #every nrx*ntx, skip 3bits
            index = index + 3
            remainder = index % 8
            for irx in range(self.csist.nrx):
                for itx in range(self.csist.ntx):
                    real = (data[int(index/8)] >> remainder) | (data[int(index/8+1)] << (8-remainder))
                    real = to_int8(real)

                    imag = (data[int(index/8+1)] >> remainder) | (data[int(index/8+2)] << (8-remainder))
                    imag = to_int8(imag)

                    self.csist.csi[itx,irx,itone] = float(real) + 1j*float(imag)
                    index = index + 16





