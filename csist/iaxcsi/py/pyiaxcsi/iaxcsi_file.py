#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import struct
from pyiaxcsi.iaxcsi_st import iaxcsi_st

class iaxcsi_file:
    csipath = None
    csist_callback = None
    iaxcsist_callback = None
    
    def __init__(self, csipath, csist_callback=None, iaxcsist_callback=None):
        self.csipath = csipath
        self.csist_callback = csist_callback
        self.iaxcsist_callback = iaxcsist_callback

    def start(self):
        with open(self.csipath, 'rb') as f:
            self.read_iaxcsi_file(f)

    def read_iaxcsi_file(self, f):
        n = 0
        while True:
            n = n + 1
            print('* file no.%d\n' % (n))

            n4 = f.read(4)
            if n4 == b'': break
            msg_len = struct.unpack('>i', n4)[0]

            csi_hdr_len = struct.unpack('>i', f.read(4))[0]
            if csi_hdr_len != 272:
                raise RuntimeError('fread csi_hdr_len(%d)!=272' % (csi_hdr_len))
            csi_hdr = f.read(csi_hdr_len)

            csi_data_len = struct.unpack('>i', f.read(4))[0]
            csi_data = f.read(csi_data_len)

            st = iaxcsi_st(csi_hdr, csi_data)
            if st.csist is None:
                continue
            if self.iaxcsist_callback:
                self.iaxcsist_callback(st); continue
            if self.csist_callback:
                self.csist_callback(st.csist); continue
