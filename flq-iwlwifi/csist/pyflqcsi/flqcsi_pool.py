#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pyflqcsi.flqcsi import flqcsi


class flqcsi_pool:
    flqcsis = []
    threads = [] 


    def __init__(self, flqcsis):
        for e in flqcsis:
            if isinstance(e, flqcsi):
                self.flqcsis.append(e)


    def start(self):
        for e in self.flqcsis:
            t = e.async_start()
            self.threads.append(t)

        for t in self.threads:
            t.join()