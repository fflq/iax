#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# sudo pip3 install libnl3 numpy seaborn
# ref iaxcsi.c(genl to nl)(https://www.infradead.org/~tgr/libnl/doc/api/group__genl.html)
# pyroute2 basic support netlink may not statisfy.

import socket
import sys
import os
import time

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import libnl.linux_private.netlink as lpnetlink
import libnl.linux_private.genetlink as lpgenetlink
import libnl.misc as nlmisc
import libnl.nl80211.nl80211 as nl80211
import libnl.socket_ as nlsocket
import libnl.nl as nl
import libnl.msg as nlmsg
import libnl.attr as nlattr
import libnl.genl.genl as genl
import libnl.genl.ctrl as genlctr
import libnl.handlers as nlhandlers
import struct

from pyiaxcsi.iwl_fw_api_rs import *
from pyiaxcsi.subcarry import subcarry_st
from pyiaxcsi.iaxcsi_st import iaxcsi_st


class iaxcsi_netlink:
    sk: nlsocket.nl_sock = None
    family: int = 0

    wlan = None
    savepath = None
    devidx: int
    csist_callback = None
    iaxcsist_callback = None


    def __init__(self, wlan, savepath=None, csist_callback=None, iaxcsist_callback=None):
        self.wlan = wlan
        self.savepath = savepath
        self.csist_callback = csist_callback
        self.iaxcsist_callback = iaxcsist_callback
        self.devidx = socket.if_nametoindex(self.wlan)
        if not self.devidx:
            raise RuntimeError('* devidx(%s,%d)' % (self.wlan, self.devidx)) 
        if self.savepath and os.path.exists(self.savepath):
            t = time.strftime('.%Y%m%d%H%M%S', time.localtime())
            os.rename(self.savepath, self.savepath+t)


    def start(self):
        self.init_nl_socket()
        print(self.sk)
        self.call_iwl_mvm_vendor_csi_register()
        self.loop_recv_msg()


    def call_iwl_mvm_vendor_csi_register(self):
        msg = nlmsg.nlmsg_alloc()

        INTEL_OUI = 0X001735
        IWL_MVM_VENDOR_CMD_CSI_EVENT = 0X24
        hdr = genl.genlmsg_put(msg, 0, nl.NL_AUTO_SEQ, self.family, 0, 
            lpnetlink.NLM_F_MATCH, nl80211.NL80211_CMD_VENDOR, 0)
        if hdr is None:
            raise RuntimeError('genlmsg_pu')

        nlattr.nla_put_u32(msg, nl80211.NL80211_ATTR_IFINDEX, self.devidx)
        nlattr.nla_put_u32(msg, nl80211.NL80211_ATTR_VENDOR_ID, INTEL_OUI)
        nlattr.nla_put_u32(msg, nl80211.NL80211_ATTR_VENDOR_SUBCMD, IWL_MVM_VENDOR_CMD_CSI_EVENT)

        r = nl.nl_send_auto(self.sk, msg)
        print('* %s, send return %d' % ('a', r))

        r = nl.nl_recvmsgs_default(self.sk)
        print('* %s, recv return %d' % ('a', r))

                
    def handle_nmsg_csi(self, csi_hdr, csi_hdr_len, csi_data, csi_data_len):
        if self.savepath:
            with open(self.savepath, 'ab') as f:
                f.write(struct.pack('>i', csi_hdr_len+csi_data_len+8))
                f.write(struct.pack('>i', csi_hdr_len))
                f.write(csi_hdr)
                f.write(struct.pack('>i', csi_data_len))
                f.write(csi_data)

        try:
            st = iaxcsi_st(csi_hdr, csi_data)
            if st.csist is None:
                return
            if self.iaxcsist_callback:
                self.iaxcsist_callback(st); return
            if self.csist_callback:
                self.csist_callback(st.csist); return
        except Exception as e:
            print(e)

               
    def valid_cb(self, msg, args):
        print('* valid_cb')
        gnlh = lpgenetlink.genlmsghdr(nlmsg.nlmsg_data(nlmsg.nlmsg_hdr(msg)))
        tb_msg = [None]*(nl80211.NL80211_ATTR_MAX+1)
        nested_tb_msg = [None]*(nl80211.NL80211_ATTR_MAX+1)

        nlattr.nla_parse(tb_msg, nl80211.NL80211_ATTR_MAX, genl.genlmsg_attrdata(gnlh,0), 
            genl.genlmsg_attrlen(gnlh,0), 0)
        
        IWL_MVM_VENDOR_ATTR_CSI_HDR = 0x4d
        IWL_MVM_VENDOR_ATTR_CSI_DATA = 0x4e
        msg_vendor_data = tb_msg[nl80211.NL80211_ATTR_VENDOR_DATA]
        if msg_vendor_data is not None:
            print('-- tb_msg[%x] is vendor_data' % (nl80211.NL80211_ATTR_VENDOR_DATA))
            nlattr.nla_parse_nested(nested_tb_msg, nl80211.NL80211_ATTR_MAX, msg_vendor_data, 0)
            self.output_tb_msg(nested_tb_msg)

            nmsg_csi_hdr = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_HDR]
            nmsg_csi_data = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_DATA]
            if nmsg_csi_hdr is not None and nmsg_csi_data is not None:
                print('-- (nla_type,nla_len) csi_hdr(%x,%u-4) csi_data(%x,%u-4)' % 
                    (nmsg_csi_hdr.nla_type, nmsg_csi_hdr.nla_len,
                    nmsg_csi_data.nla_type, nmsg_csi_data.nla_len,))

                csi_hdr_len = nmsg_csi_hdr.nla_len - 4
                #csi_hdr = nla_get_string(nmsg_csi_hdr)
                csi_hdr = self.nla_get_string_with_len(nmsg_csi_hdr, csi_hdr_len)
                if csi_hdr_len != 272:
                    raise RuntimeError('* csi_hdr_len(%d) != 272' % (csi_hdr_len))

                csi_data_len = nmsg_csi_data.nla_len - 4
                csi_data = self.nla_get_string_with_len(nmsg_csi_data, csi_data_len)

                self.handle_nmsg_csi(csi_hdr, csi_hdr_len, csi_data, csi_data_len)

        return nl.NL_OK


    def finish_cb(self, msg, args):
        return nl.NL_SKIP


    def init_nl_socket(self):
        sk = nlsocket.nl_socket_alloc()
        if not sk:
            raise RuntimeError('nl_socket_alloc')

        if 0 != genl.genl_connect(sk):
            raise RuntimeError('nl_connect')

        nl.nl_socket_set_buffer_size(sk, 8192, 8192) 
        self.nl_socket_disable_seq_check(sk)
        self.family = genlctr.genl_ctrl_resolve(sk, b'nl80211')
        self.sk = sk
    

    # use self.sk will err in genlctr.genl_ctrl_resolve()
    def wrong_init_nl_socket(self):
        self.sk = nlsocket.nl_socket_alloc()
        if not self.sk:
            raise RuntimeError('nl_socket_alloc')
        
        if 0 != genl.genl_connect(self.sk):
            raise RuntimeError('nl_connect')

        nl.nl_socket_set_buffer_size(self.sk, 8192, 8192) 
        self.nl_socket_disable_seq_check(self.sk)
        self.family = genlctr.genl_ctrl_resolve(self.sk, b'nl80211')


    def loop_recv_msg(self):
        #finished = 0
        nlsocket.nl_socket_modify_cb(self.sk, nl.NL_CB_VALID, nl.NL_CB_CUSTOM, self.valid_cb, None) 
        #nlsocket.nl_socket_modify_cb(sk, nl.NL_CB_FINISH, nl.NL_CB_CUSTOM, finish_cb, None) 
        print('* loop_recv_msg\n\n')

        n = 0 ;
        while True:
            r = nl.nl_recvmsgs_default(self.sk)
            n = n + 1
            print('* recv no.%d, nl_recvmsgs %d' % (n, r))
            if r < 0:
                print('** nl_recvmsgs err %d' % (r))
                continue 
            print('\n')


    # libnl.attr.get_string(stream) return when byte=0 which is wrong(ref c bellow)
    # https://www.infradead.org/~tgr/libnl/doc/api/attr_8c_source.html#l00684
    @staticmethod
    def get_string_with_len(stream, len):
        ba = bytearray()
        for c in stream:
            if not len:
                break
            len = len - 1
            ba.append(c)
        return bytes(ba)


    def nla_get_string_with_len(self, nla, len):
        #return get_string(nla_data(nla))
        return self.get_string_with_len(nlattr.nla_data(nla), len)


    def noop_seq_check(self, msg, args):
        return nl.NL_OK


    def nl_socket_disable_seq_check(self, sk):
        #nl_cb_set(sk.s_cb, NL_CB_SEQ_CHECK, NL_CB_CUSTOM, noop_seq_check, None)
        nlsocket.nl_socket_modify_cb(sk, nl.NL_CB_SEQ_CHECK, nl.NL_CB_CUSTOM, self.noop_seq_check, None) 


    def output_tb_msg(self, tb_msg):
        for i in range(1,nl80211.NL80211_ATTR_MAX):
            if tb_msg[i] is not None:
                print('-- tb_msg[%x]: len %d, type %x' % (i, tb_msg[i].nla_len, tb_msg[i].nla_type))
 


##############################################################################
def test_csist_callback(csist):
    print('* test_csi_st_callback')
    sns.lineplot(abs(csist.csi[0,0,:]))
    plt.pause(0.01)

def main():
    iaxcsi_netlink(sys.argv[1], sys.argv[2], test_csist_callback).start()

if __name__ == '__main__':
    main()

