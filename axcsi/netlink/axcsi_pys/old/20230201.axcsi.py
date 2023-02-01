#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# sudo pip3 install libnl3 numpy seaborn
# ref axcsi.c(genl to nl)(https://www.infradead.org/~tgr/libnl/doc/api/group__genl.html)

import socket
import sys

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

from iwl_fw_api_rs import *
from subcarry import subcarry_st


class CSIST:
    csi_len:int; seq:int; us:int; ftm:int
    smac: str

    rnf:int; chan_width:int; ant_sel:int; ldpc:int
    mod_type_str:str; chan_type_str:str

    rssi1:int; rssi2:int; nrx:int; ntx:int; ntone:int

    raw_csi:np.array
    csi: np.array
    subc: subcarry_st


gcb = None
gdevidx = None
gportid = 0
gdevidx = -1
gfilepath = '/tmp/a'
csist_callback = None


def call_iwl_mvm_vendor_csi_register(sk ,family_id):
    print(sk)
    msg = nlmsg.nlmsg_alloc()

    INTEL_OUI = 0X001735
    IWL_MVM_VENDOR_CMD_CSI_EVENT = 0X24
    hdr = genl.genlmsg_put(msg, 0, nl.NL_AUTO_SEQ, family_id, 0, 
        lpnetlink.NLM_F_MATCH, nl80211.NL80211_CMD_VENDOR, 0)
    if hdr is None:
        raise RuntimeError('genlmsg_pu')

    nlattr.nla_put_u32(msg, nl80211.NL80211_ATTR_IFINDEX, gdevidx)
    nlattr.nla_put_u32(msg, nl80211.NL80211_ATTR_VENDOR_ID, INTEL_OUI)
    nlattr.nla_put_u32(msg, nl80211.NL80211_ATTR_VENDOR_SUBCMD, IWL_MVM_VENDOR_CMD_CSI_EVENT)

    r = nl.nl_send_auto(sk, msg)
    print('* %s, send return %d' % ('a', r))

    r = nl.nl_recvmsgs_default(sk)
    print('* %s, recv return %d' % ('a', r))


def output_tb_msg(tb_msg):
    for i in range(1,nl80211.NL80211_ATTR_MAX):
        if tb_msg[i] is not None:
            print('-- tb_msg[%x]: len %d, type %x' % (i, tb_msg[i].nla_len, tb_msg[i].nla_type))
            

def handle_rate_n_flags(csist, rnf, endian):
    #global g_mod_type_map, g_chan_width_map, g_he_type_map

	# Bits 10-8: rate format, mod type
    rate_mcs_mod_type = rnf & RATE_MCS_MOD_TYPE_MSK 
    csist.mod_type = rate_mcs_mod_type >> RATE_MCS_MOD_TYPE_POS 
    csist.mod_type_str = g_mod_type_map[rate_mcs_mod_type]

    # Bits 24-23: HE type
    if csist.mod_type == (RATE_MCS_HE_MSK>>RATE_MCS_MOD_TYPE_POS):
        rate_mcs_he_type = rnf & RATE_MCS_HE_TYPE_MSK 
        csist.he_type = rate_mcs_he_type >> RATE_MCS_HE_TYPE_POS 
        csist.he_type_str = g_he_type_map[rate_mcs_he_type]

	# Bits 13-11: chan width
    rate_mcs_chan_width = rnf & RATE_MCS_CHAN_WIDTH_MSK 
    csist.chan_width_type = rate_mcs_chan_width >> RATE_MCS_CHAN_WIDTH_POS 
    csist.chan_width = g_chan_width_map[rate_mcs_chan_width] 

    csist.chan_type_str = csist.mod_type_str + str(csist.chan_width)

	# Bits 15-14: antenna selection
    csist.ant_sel = (rnf & RATE_MCS_ANT_MSK) >> RATE_MCS_ANT_POS ; 

	# Bits 16: LDPC enables
    csist.ldpc = (rnf & RATE_MCS_LDPC_MSK) >> RATE_MCS_LDPC_POS ; 

    '''
    print("* mod_type(%u,%s) he_type(%d,%s) chan_width_type(%u,%u) ant_sel(%u) ldpc(%u)\n" %
			(csist.mod_type, csist.mod_type_str, csist.he_type, csist.he_type_str, 
			csist.chan_width_type, csist.chan_width, csist.ant_sel, csist.ldpc)) ;
    '''


def handle_csi(csist, csi_data, endian):
    pos = 0
    csi = np.zeros((csist.nrx, csist.ntx, csist.ntone), dtype='complex')
    for irx in range(csist.nrx):
        for itx in range(csist.ntx):
            for itone in range(csist.ntone):
                imag = int.from_bytes(csi_data[pos:pos+2], endian, signed=True)
                real = int.from_bytes(csi_data[pos+2:pos+4], endian, signed=True)
                pos = pos + 4
                csi[irx,itx,itone] = real + 1j*imag
    csist.csi = csi


def handle_csi_subcs(csist):
    #if csist.chan_type_str == "VHT160": return 
    subc = subcarry_st.get_subc(csist.chan_type_str)
    scsi = np.zeros((csist.nrx, csist.ntx, subc.subcs_len), dtype='complex')
    data_pilot_dc_tones = np.zeros(subc.subcs_len, dtype=complex)

    for irx in range(csist.nrx):
        for itx in range(csist.ntx):
            csi_data_pilot_tones = csist.csi[irx, itx]
            data_pilot_dc_tones[subc.idx_data_pilot_subcs] = csi_data_pilot_tones

            # interp complex num by (mag,phase)
            # for raw_csi, only data_tones valid
            x = subc.idx_data_subcs
            mag = np.interp(subc.idx_data_pilot_dc_subcs, x, np.abs(data_pilot_dc_tones[x]))
            phase = np.interp(subc.idx_data_pilot_dc_subcs, x, np.angle(data_pilot_dc_tones[x]))
            x = subc.idx_pilot_dc_subcs
            data_pilot_dc_tones[x] = mag[x] * np.exp(1j*phase[x])
            scsi[irx,itx] = data_pilot_dc_tones

    csist.scsi = scsi
    csist.subc = subc


def handle_csi_hdr(csist, csi_hdr, endian):
    csist.csi_len = int.from_bytes(csi_hdr[0:4], endian)
    csist.ftm = int.from_bytes(csi_hdr[8:12], endian)
    csist.nrx = int(csi_hdr[46])
    csist.ntx = int(csi_hdr[47])
    csist.ntone = int.from_bytes(csi_hdr[52:56], endian)
    csist.rssi1 = -int(csi_hdr[60])
    csist.rssi2 = -int(csi_hdr[64])
    #csist.smac = ':'.join(csi_hdr[68:74].hex())
    csist.smac = ':'.join([hex(b)[2:] for b in csi_hdr[68:74]])
    csist.seq = int(csi_hdr[76])
    csist.us = int.from_bytes(csi_hdr[88:92], endian)
    csist.rnf = int.from_bytes(csi_hdr[92:96], endian)


def get_csi_st(csi_hdr, csi_hdr_len, csi_data, csi_data_len):
    st = CSIST()
    endian = 'little'

    # csi_hdr
    handle_csi_hdr(st, csi_hdr, endian)
        
    # rnf
    #handle_rate_n_flags(st, st.rnf, endian)

    print(st.__dict__)

    # csi
    handle_csi(st, csi_data, endian)
    #handle_csi_subcs(st)

    return st


def handle_nmsg_csi(csi_hdr, csi_hdr_len, csi_data, csi_data_len):
    global gfilepath
    with open(gfilepath, 'ab') as f:
        f.write(struct.pack('>i', csi_hdr_len))
        f.write(csi_hdr)
        f.write(struct.pack('>i', csi_data_len))
        f.write(csi_data)

    csist = get_csi_st(csi_hdr, csi_hdr_len, csi_data, csi_data_len)
    global csist_callback
    csist_callback(csist)
    #sns.lineplot(abs(csist.csi[0,0,:]))
    #plt.pause(0.01)

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
    return get_string_with_len(nlattr.nla_data(nla), len)


def valid_cb(msg, args):
    gnlh = lpgenetlink.genlmsghdr(nlmsg.nlmsg_data(nlmsg.nlmsg_hdr(msg)))
    tb_msg = [None]*(nl80211.NL80211_ATTR_MAX+1)
    nested_tb_msg = [None]*(nl80211.NL80211_ATTR_MAX+1)

    print('* valid_cb')

    nlattr.nla_parse(tb_msg, nl80211.NL80211_ATTR_MAX, genl.genlmsg_attrdata(gnlh,0), 
        genl.genlmsg_attrlen(gnlh,0), 0)
    
    IWL_MVM_VENDOR_ATTR_CSI_HDR = 0x4d
    IWL_MVM_VENDOR_ATTR_CSI_DATA = 0x4e
    msg_vendor_data = tb_msg[nl80211.NL80211_ATTR_VENDOR_DATA]
    if msg_vendor_data is not None:
        print('-- tb_msg[%x] is vendor_data' % (nl80211.NL80211_ATTR_VENDOR_DATA))
        nlattr.nla_parse_nested(nested_tb_msg, nl80211.NL80211_ATTR_MAX, msg_vendor_data, 0)
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

            handle_nmsg_csi(csi_hdr, csi_hdr_len, csi_data, csi_data_len)

    return nl.NL_OK


def finish_cb(msg, args):
    return nl.NL_SKIP


def noop_seq_check(msg, args):
    return nl.NL_OK


def nl_socket_disable_seq_check(sk):
    #nl_cb_set(sk.s_cb, NL_CB_SEQ_CHECK, NL_CB_CUSTOM, noop_seq_check, None)
    nlsocket.nl_socket_modify_cb(sk, nl.NL_CB_SEQ_CHECK, nl.NL_CB_CUSTOM, noop_seq_check, None) 


def init_nl_socket():
    sk = nlsocket.nl_socket_alloc()
    if sk is None:
        raise RuntimeError('nl_socket_alloc')
    
    r = genl.genl_connect(sk)
    if r != 0:
        raise RuntimeError('nl_connect')

    nl.nl_socket_set_buffer_size(sk, 8192, 8192) 
    nl_socket_disable_seq_check(sk)
    global family_id
    family_id = genlctr.genl_ctrl_resolve(sk, b'nl80211')

    global gcb
    gcb = nlhandlers.nl_cb_alloc(nlhandlers.NL_CB_DEFAULT)
    #gportid = flqsk->s_local.nl_pid
    global gportid
    gportid = 0

    call_iwl_mvm_vendor_csi_register(sk, family_id)

    print('* family_id %d, gdevidx %d, portid %d' % (family_id, gdevidx, gportid))
    return sk


def loop_recv_msg(sk):
    #finished = 0
    nlsocket.nl_socket_modify_cb(sk, nl.NL_CB_VALID, nl.NL_CB_CUSTOM, valid_cb, None) 
    #nlsocket.nl_socket_modify_cb(sk, nl.NL_CB_FINISH, nl.NL_CB_CUSTOM, finish_cb, None) 
    print('* loop_recv_msg\n\n')

    n = 0 ;
    while True:
        r = nl.nl_recvmsgs_default(sk)
        n = n + 1
        print('* %d, nl_recvmsgs %d' % (n, r))
        if r < 0:
            print('** nl_recvmsgs err %d' % (r))
            continue 
        print('\n')


def handle_args(wlan, savepath, callback):
    global gdevidx, gfilepath, csist_callback
    gfilepath = savepath
    gdevidx = socket.if_nametoindex(wlan)
    csist_callback = callback

    if gfilepath:
        with open(gfilepath, 'wb') as f:
            f.truncate()
    if gdevidx is None:
        raise RuntimeError('* devidx(%d) filepath(%x)\n' % (gdevidx, gfilepath)) 

    print("* %s, %s/%d %s\n" % ('a', sys.argv[1], gdevidx, sys.argv[2])) 
    

def run_axcsi(wlan, savepath, callback):
    handle_args(wlan, savepath, callback)

    sk = init_nl_socket()

    loop_recv_msg(sk)


###################################################
def test_csist_callback(csist):
    print('* test_csi_st_callback')
    sns.lineplot(abs(csist.csi[0,0,:]))
    plt.pause(0.01)

def main():
    run_axcsi(sys.argv[1], sys.argv[2], test_csist_callback)

if __name__ == '__main__':
    main()

