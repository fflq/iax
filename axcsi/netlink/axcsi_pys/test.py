#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# sudo pip3 install libnl3
# ref axcsi.c(genl to nl)(https://www.infradead.org/~tgr/libnl/doc/api/group__genl.html)

import ctypes
import socket
import sys

#from libnl.error import errmsg
#from libnl.handlers import NL_CB_CUSTOM, NL_CB_VALID, NL_OK
#from libnl.linux_private.if_link import IFLA_IFNAME, IFLA_RTA
#from libnl.linux_private.netlink import NETLINK_GENERIC, NLMSG_LENGTH, NLM_F_DUMP, NLM_F_REQUEST
#from libnl.linux_private.rtnetlink import RTA_DATA, RTA_NEXT, RTA_OK, RTM_GETLINK, ifinfomsg, rtgenmsg
#from libnl.misc import get_string
#from libnl.msg import nlmsg_data, nlmsg_hdr
#from libnl.nl import nl_connect, nl_recvmsgs_default, nl_send_simple
from libnl.misc import *
from libnl.msg import *
from libnl.linux_private.netlink import *
from libnl.nl import *
from libnl.socket_ import *
from libnl.linux_private.netlink import *
from libnl.genl.genl import *
from libnl.genl.ctrl import *
from libnl.nl80211.nl80211 import *
from libnl.attr import *


gcb = None
gdevidx = None
gportid = 0
gdevidx = -1
gfilepath = '/tmp/a'


def call_iwl_mvm_vendor_csi_register(sk ,family_id):
    print(sk)
    msg = nlmsg_alloc()
    INTEL_OUI = 0X001735
    IWL_MVM_VENDOR_CMD_CSI_EVENT = 0X24
    hdr = genlmsg_put(msg, 0, NL_AUTO_SEQ, family_id, 0, NLM_F_MATCH, NL80211_CMD_VENDOR, 0)
    if hdr is None:
        raise RuntimeError('genlmsg_pu')

    nla_put_u32(msg, NL80211_ATTR_IFINDEX, gdevidx)
    nla_put_u32(msg, NL80211_ATTR_VENDOR_ID, INTEL_OUI)
    nla_put_u32(msg, NL80211_ATTR_VENDOR_SUBCMD, IWL_MVM_VENDOR_CMD_CSI_EVENT)

    r = nl_send_auto(sk, msg)
    print('* %s, send return %d' % ('a', r))

    r = nl_recvmsgs_default(sk)
    print('* %s, recv return %d' % ('a', r))


def output_tb_msg(tb_msg):
    for i in range(1,NL80211_ATTR_MAX):
        if tb_msg[i] is not None:
            print('-- tb_msg[%x]: len %d, type %x' % (i, tb_msg[i].nla_len, tb_msg[i].nla_type))
            

def handle_rate_n_flags():
    return 0


def handle_csi(csi_hdr, csi_hdr_len, csi_data, csi_data_len):
    global gfilepath
    with open(gfilepath, 'ab') as f:
        f.write(struct.pack('>i', csi_hdr_len))
        f.write(csi_hdr)
        f.write(struct.pack('>i', csi_data_len))
        f.write(csi_data)

    handle_rate_n_flags()
    return 0 
    

# libnl.attr.get_string(stream) return when byte=0 which is wrong(ref c bellow)
# https://www.infradead.org/~tgr/libnl/doc/api/attr_8c_source.html#l00684
def get_string_with_len(stream, len):
    ba = bytearray()
    for c in stream:
        if not len:
            break
        len = len - 1
        ba.append(c)
    return bytes(ba)

def nla_get_string_with_len(nla, len):
    #return get_string(nla_data(nla))
    return get_string_with_len(nla_data(nla), len)


def valid_cb(msg, args):
    gnlh = genlmsghdr(nlmsg_data(nlmsg_hdr(msg)))
    tb_msg = [None]*(NL80211_ATTR_MAX+1)
    nested_tb_msg = [None]*(NL80211_ATTR_MAX+1)

    print('* valid_cb')

    nla_parse(tb_msg, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh,0), 
        genlmsg_attrlen(gnlh,0), 0)
    
    IWL_MVM_VENDOR_ATTR_CSI_HDR = 0x4d
    IWL_MVM_VENDOR_ATTR_CSI_DATA = 0x4e
    msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_DATA]
    if msg_vendor_data is not None:
        print('-- tb_msg[%x] is vendor_data' % (NL80211_ATTR_VENDOR_DATA))
        nla_parse_nested(nested_tb_msg, NL80211_ATTR_MAX, msg_vendor_data, 0)
        output_tb_msg(nested_tb_msg)

        nmsg_csi_hdr = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_HDR]
        nmsg_csi_data = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_DATA]
        if nmsg_csi_hdr is not None and nmsg_csi_data is not None:
            print('-- (nla_type,nla_len) csi_hdr(%x,%u) csi_data(%x,%u)' % 
                (nmsg_csi_hdr.nla_type, nmsg_csi_hdr.nla_len,
                nmsg_csi_data.nla_type, nmsg_csi_data.nla_len,))

            csi_hdr_len = nmsg_csi_hdr.nla_len - 4
            #csi_hdr = nla_get_string(nmsg_csi_hdr)
            csi_hdr = nla_get_string_with_len(nmsg_csi_hdr, csi_hdr_len)

            csi_data_len = nmsg_csi_data.nla_len - 4
            csi_data = nla_get_string_with_len(nmsg_csi_data, csi_data_len)

            handle_csi(csi_hdr, csi_hdr_len, csi_data, csi_data_len)

    return NL_OK


def finish_cb(msg, args):
    return NL_SKIP


def noop_seq_check(msg, args):
    return NL_OK


def nl_socket_disable_seq_check(sk):
    #nl_cb_set(sk.s_cb, NL_CB_SEQ_CHECK, NL_CB_CUSTOM, noop_seq_check, None)
    nl_socket_modify_cb(sk, NL_CB_SEQ_CHECK, NL_CB_CUSTOM, noop_seq_check, None) 


def init_nl_socket():
    sk = nl_socket_alloc()
    if sk is None:
        raise RuntimeError('nl_socket_alloc')
    
    r = genl_connect(sk)
    if r != 0:
        raise RuntimeError('nl_connect')

    nl_socket_set_buffer_size(sk, 8192, 8192) 
    nl_socket_disable_seq_check(sk)
    global family_id
    family_id = genl_ctrl_resolve(sk, b'nl80211')

    global gcb
    gcb = nl_cb_alloc(NL_CB_DEFAULT)
    #gportid = flqsk->s_local.nl_pid
    global gportid
    gportid = 0

    call_iwl_mvm_vendor_csi_register(sk, family_id)

    print('* family_id %d, gdevidx %d, portid %d' % (family_id, gdevidx, gportid))
    return sk


def loop_recv_msg(sk):
    #finished = 0
    nl_socket_modify_cb(sk, NL_CB_VALID, NL_CB_CUSTOM, valid_cb, None) 
    #nl_socket_modify_cb(sk, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &finished) 
    nl_socket_modify_cb(sk, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, None) 
    print('* loop_recv_msg\n\n')

    n = 0 ;
    while True:
        r = nl_recvmsgs_default(sk)
        n = n + 1
        print('* %d, nl_recvmsgs %d' % (n, r))
        if r < 0:
            print('** nl_recvmsgs err %d' % (r))
            continue 
        print('\n')
    return 0


def handle_args():
    print(sys.argv)
    if len(sys.argv) < 3:
        raise RuntimeError("Usage: sudo %s wlan file\n- wlan: eg wlp8s0\n- file: eg ./a.csi\n"
				"* eg: sudo %s wlp8s0 ./a.csi\n" % (sys.argv[0], sys.argv[0])) 
    else:
        global gdevidx
        gdevidx = socket.if_nametoindex(sys.argv[1])
        #g_fp_csi = fopen()
        global gfilepath
        gfilepath = sys.argv[2]
        with open(gfilepath, 'wb') as f:
            f.truncate()
        if gdevidx is None:
            raise RuntimeError('* devidx(%d) fp_csi(%x)\n' % (gdevidx, g_fp_csi)) 
        print("* %s, %s/%d %s\n" % ('a', sys.argv[1], gdevidx, sys.argv[2])) 
        
    return 0


def main():
    handle_args()

    sk = init_nl_socket()

    loop_recv_msg(sk)


main()


