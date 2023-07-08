#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pyincsi.incsi_file import incsi_file
from pyincsi.incsi_netlink import incsi_netlink


class incsi:
    wlan: str = None
    csipath: str = None
    savepath: str = None
    file_not_netlink = True
    csist_callback = None

    csi_file_handler: incsi_file = None
    csi_netlink_handler: incsi_netlink = None


    def __init__(self, wlan=None, csipath=None, savepath=None, csist_callback=None): 
        self.wlan = wlan
        self.csipath = csipath
        self.savepath = savepath
        self.csist_callback = csist_callback

        if self.csipath:
            self.file_not_netlink = False
            self.csi_file_handler = incsi_file(csipath=csipath, csist_callback=self.csist_callback)
        #if self.wlan:
        else:
            self.file_not_netlink = True
            self.csi_netlink_handler = incsi_netlink(savepath=self.savepath, csist_callback=self.csist_callback)


    def start(self):
        if (self.csi_file_handler):
            self.csi_file_handler.start()

        if (self.csi_netlink_handler):
            self.csi_netlink_handler.start()


    