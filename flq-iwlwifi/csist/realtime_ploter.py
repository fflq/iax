#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


class realtime_ploter:

    def __init__(self, fid=1, max_display_size=200):
        self.fid = fid
        self.max_display_size = max_display_size
        #f = plt.figure(self.fid)
        self.fig, self.ax = plt.subplots()
        self.xs = []
        self.ys = []
        self.line = self.ax.plot(self.xs, self.ys, marker='o', lw=2)[0]
        self.yranges = [0, 0]
        self.idx = -1
        #plt.tight_layout()


    def add_points(self, y, x = None, move_axis=True):
        if x == None:
            x = 1
            if (len(self.xs) > 0):
                x = self.xs[-1] + 1

        self.xs.append(x)
        self.ys.append(y)
        self.idx = self.idx + 1
    
        #select ranges
        #ys_norm = self.ys / np.linalg.norm(self.ys)
        ys_norm = (self.ys - np.mean(self.ys)) / np.std(self.ys)
        ys_norm = self.ys
        self.line.set_data(self.xs, ys_norm)
        #self.line.set_data(self.xs, self.ys)

        ixb, ixe = max(0, self.idx - self.max_display_size), self.idx
        #dont move for display all
        if not move_axis:
            ixb, ixe = 0, -1
        self.ax.set_xlim(self.xs[ixb], self.xs[ixe]+1)
        yreds = abs(max(self.ys)) * 0.2 + 10
        self.ax.set_ylim(min(self.ys)-yreds, max(self.ys)+yreds)
        #self.ax.set_ylim(-5, 5)

        #truncate(when all/2 blocks full, truncate first block)
        #cache more data for norm
        if self.idx > 100*self.max_display_size:
            self.idx = self.idx - self.max_display_size
            self.xs = self.xs[self.max_display_size:]
            self.ys = self.ys[self.max_display_size:]
        #print(self.xs)

        #plt.pause(0.01)
 