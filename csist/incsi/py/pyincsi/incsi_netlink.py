#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# sudo pip3 install libnl3 numpy seaborn
# ref iaxcsi.c(genl to nl)(https://www.infradead.org/~tgr/libnl/doc/api/group__genl.html)

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

from pyincsi.incsi_st import incsi_st


NETLINK_CONNECTOR = 11
CN_NETLINK_USERS = 11
CN_IDX_IWLAGN = (CN_NETLINK_USERS + 0xf)
CN_VAL_IWLAGN = 0x1

SOL_NETLINK = 270
NETLINK_ADD_MEMBERSHIP = 1 

NLMSG_HDRLEN = 16
CNMSG_HDRLEN = 20


class incsi_netlink:

    class cn_msg_st:
        idx: int; val: int; seq: int; ack: int; length: int; flags: int;
        data: bytes


    sk: socket.socket = None

    savepath = None
    csist_callback = None


    def __init__(self, savepath=None, csist_callback=None): 
        self.savepath = savepath
        self.csist_callback = csist_callback
        if self.savepath and os.path.exists(self.savepath):
            t = time.strftime('.%Y%m%d%H%M%S', time.localtime())
            os.rename(self.savepath, self.savepath+t)


    def init_socket(self):
        self.sk = socket.socket(socket.AF_NETLINK, socket.SOCK_DGRAM, NETLINK_CONNECTOR)
        self.sk.bind((CN_IDX_IWLAGN, -1))
        self.sk.setsockopt(SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, CN_IDX_IWLAGN)


    def start(self):
        self.init_socket()
        print(self.sk)
        self.loop_recv_msg()


    def handle_cn_msg(self, cn_msg: cn_msg_st):
        if self.savepath:
            with open(self.savepath, 'ab') as f:
                f.write(struct.pack('>H', cn_msg.length))
                f.write(cn_msg.data)

        try:
            if self.csist_callback:
                self.csist_callback(incsi_st(cn_msg.data).csist); return
        except Exception as e:
            print(e)


    def loop_recv_msg(self):
        n = 0
        while True:
            try:
                n = n + 1
                print("\n* recv no.{}".format(n))

                buf = self.sk.recvfrom(10240)
                buf = buf[0]

                #buf[0] same to c-codes-recv-buf
                cn_msg_buf = buf[NLMSG_HDRLEN:NLMSG_HDRLEN+CNMSG_HDRLEN]
                cn_msg = self.cn_msg_st()
                [cn_msg.idx, cn_msg.val, cn_msg.seq, cn_msg.ack, cn_msg.length, cn_msg.flags] = struct.unpack('<IIIIHH', cn_msg_buf)
                print(cn_msg.__dict__)
                buf = buf[NLMSG_HDRLEN+CNMSG_HDRLEN:]
                cn_msg.data = buf[:cn_msg.length]

                self.handle_cn_msg(cn_msg)
            except Exception as e:
                print(e)





'''
#undone in iaxcsi's libnl way
class flq:
    def __init__(self, sk):
        self.sk = sk;

    def valid_cb(self, msg, args):
        print('* valid_cb')
        cmsg = nlmsg.nlmsg_data(nlmsg.nlmsg_hdr(msg))
        print(cmsg)

        return nl.NL_OK

    def loop_recv_msg(self):
        nlsocket.nl_socket_modify_cb(self.sk, nl.NL_CB_VALID, nl.NL_CB_CUSTOM, self.valid_cb, None) 
        print('* loop_recv_msg\n\n')

        n = 0 ;
        while True:
            r = nl.nl_recvmsgs_default(self.sk)
            n = n + 1
            print('* %d, nl_recvmsgs %d' % (n, r))
            if r < 0:
                print('** nl_recvmsgs err %d' % (r))
                continue 
            print('\n')

sk = nlsocket.nl_socket_alloc()
print(sk)
nl.nl_connect(sk, NETLINK_CONNECTOR)
nl.nl_socket_set_buffer_size(sk, 8192, 8192) 
nlsocket.nl_socket_modify_cb(sk, nl.NL_CB_SEQ_CHECK, nl.NL_CB_CUSTOM, lambda msg, args: nl.NL_OK, None) 
nlsocket.nl_socket_add_membership(sk, CN_IDX_IWLAGN)

flq(sk).loop_recv_msg()
'''

