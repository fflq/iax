#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import math

from scipy import stats

from realtime_ploter import realtime_ploter

from pyflqcsi.flqcsi_pool import flqcsi_pool
from pyflqcsi.flqcsi import flqcsi, flqcsi_st, flqcsi_type


def plot_mag(csist: flqcsi_st):
    plt.figure(1)
    for i in range(csist.nrx):
        sns.lineplot(np.abs(csist.csi[0,i]))


gns1 = []
gns2 = []
grp12 = realtime_ploter(12)
def plot_cir(csist: flqcsi_st):
    cfr = csist.csi[0] 
    cir = np.fft.ifft(cfr)
    #sameto, cir = np.array([cir1, cir2])
    cir = cir[:,0:50]
    dt = 1e9 / (csist.bw * 1e6) #ns
    xs = np.arange(0, cir.shape[1])*dt 
    #i = np.argmax(np.real(cir)) 
    #print("t({}) d({})".format(xs[i], xs[i]*0.3))
    print("dt****** ", dt)

    #plot
    plt.figure(2)
    plt.xticks(range(0,500,50))
    sns.lineplot(x=xs, y=np.abs(cir[0]))
    sns.scatterplot(x=xs, y=np.abs(cir[0]))
    if cir.shape[0] > 1:
        cir2_offs = 100
        cir2_offs = 0
        sns.lineplot(x=xs, y=cir2_offs+np.abs(cir[1]))
        sns.scatterplot(x=xs, y=cir2_offs+np.abs(cir[1]))

    gns = gns1
    max_x1 = np.argmax(np.abs(cir[0])) * dt
    gns.append(max_x1)
    m = np.mean(gns[max(0, len(gns)-100):-1])
    print("ns1------------", m, ", ", max_x1)
    p = stats.kstest(gns, 'norm', (np.mean(gns), np.std(gns)))
    print("p---", p)

    gns = gns2
    max_x2 = np.argmax(np.abs(cir[1])) * dt
    gns.append(max_x2)
    m = np.mean(gns[max(0, len(gns)-100):-1])
    print("ns2============", m, ", ", max_x2)

    print("*******", max_x2-max_x1)
    grp12.add_points(max_x2-max_x1)
    pw1 = np.sum(np.abs(cfr[0])**2)/1e4
    pw2 = np.sum(np.abs(cfr[1])**2)/1e4
    if (max_x2 > max_x1) != (pw1 > pw2):
        pass
        #input()

    #input()
     

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


gns13 = []
#grp13 = realtime_ploter(13)
def plot_tof(csist: flqcsi_st):
    #fc = 5.21e9
    #subc_freq_range = np.arange(5.17e9, 5.25e9, 312.5e3)
    fc = 5.25e9
    subc_freq_range = np.arange(fc-80e6, fc+80e6, 312.5e3)
    subc_freq_range = subc_freq_range[0:len(csist.subcs)]
    [k, b, _] = fit_csi(csist.csi[0,0], subc_freq_range)
    tpdd = b / fc / (2*np.pi)
    tall = k / (-2*np.pi)
    ttof = tall - tpdd
    dist = ttof * 2e8
    print("***", k, b)
    print("***", tall, tpdd, ttof, dist)
    #grp13.add_points(dist)
    uwphase = np.unwrap(np.angle(csist.csi[0,0]))
    sns.lineplot(x=subc_freq_range, y=uwphase)


def plot_pll(csist: flqcsi_st):
    subc0_idx = int(np.floor(len(csist.subcs)/2))
    subc0_phase1 = np.angle(csist.csi[0,0,subc0_idx])
    subc0_phase1 = math.remainder(subc0_phase1, math.tau)
    subc0_phase2 = np.angle(csist.csi[0,1,subc0_idx])
    subc0_phase2 = math.remainder(subc0_phase2, math.tau)
    phaseoff = math.remainder(subc0_phase2-subc0_phase1, math.tau)
    print("***subc0", subc0_phase1, subc0_phase2, phaseoff)

    phase_plls = [0, 0]
    for i in range(csist.nrx):
        subc0_phase = np.angle(csist.csi[0,i,subc0_idx])
        f0 = 5.2e9
        wire_dist = 2.1
        wire_c = 2e8
        #t = wire_dist / wire_c
        #phase = -2*np.pi*f0*t
        #approx 25
        phase = -2*np.pi*wire_dist*(f0/wire_c)
        phase_pll = subc0_phase - phase
        phase_plls[i] = math.remainder(phase_pll, math.tau)
        print("***phase", subc0_phase, phase, phase_pll, phase_plls[i])
    phaseoff_pll = math.remainder(phase_plls[1]-phase_plls[0], math.tau)
    print("***phase_pll", phase_plls[0], phase_plls[1], phaseoff_pll)


#grp9 = realtime_ploter(9)
def plot_breath(csist: flqcsi_st):
    csi = csist.csi
    s = np.mean(np.abs(csi[0,1] * np.conj(csi[0,0])))
    #s = np.mean(np.angle(csi[0,1] * np.conj(csi[0,0])))
    grp9.add_points(s)


#grp8 = realtime_ploter(8)
def plot_attack(csist: flqcsi_st):
    avgmag = (np.mean(np.abs(csist.csi[0,0])) + np.mean(np.abs(csist.csi[0,1]))) / 2 
    avgmag = (np.abs(csist.csi[0,0,0]) + np.abs(csist.csi[0,1,0])) / 2 
    grp8.add_points(avgmag, move_axis=False)


def plot_phase(csist: flqcsi_st):
    csi = csist.csi[0];
    #csi[:] = csi[csist.perm-1]
    #phaoff12 = np.unwrap(np.angle(csi[1] * np.conj(csi[0])))
    #phaoff12 = np.unwrap(np.angle(csi[2] * np.conj(csi[0])))
    #sns.lineplot(phaoff12)
    #sns.scatterplot(phaoff12)
    sns.lineplot(np.unwrap(np.angle(csi[0])))
    sns.lineplot(np.unwrap(np.angle(csi[1])))


gploty = [0]
#grp9 = realtime_ploter(9)
def plot_phase_offset(csist: flqcsi_st, adjust=False):
    csi = csist.csi[0]
    subcs = csist.subcs

    phaoff12 = np.unwrap(np.angle(csi[1] * np.conj(csi[0])))
    #calc_ft_theta(phaoff12)
    #phaoff12 = np.unwrap(np.angle(csi[1,0] * (csi[0,0])))
    avg_phaoff12 = np.mean(phaoff12)
    while avg_phaoff12 < -np.pi/2:
        avg_phaoff12 = avg_phaoff12 + 2*np.pi
        #phaoff12 = phaoff12 + 2*np.pi
    if (avg_phaoff12 > 0):
        gploty.append(avg_phaoff12)
    print(avg_phaoff12, np.mean(gploty))
    #theta = np.rad2deg(np.arcsin(avg_phaoff12*2/np.pi))
    #print(theta)
    if len(gploty)>1 and abs(gploty[-1]-gploty[-2]) > 0.5:
        pass
        #input('-change')
    #plt.figure(1)
    sns.lineplot(x=subcs, y=phaoff12)
    #sns.lineplot(x=subcs, y=-phaoff12)


def csist_filter(csist:flqcsi_st):
    if csist is None:
        return False
    return True
    if not csist.smac.startswith("0:16:ea:12:34:56"):
        return False

    print("*******************")
    return True


gn = 0
def csist_callback(csist: flqcsi_st):
    if not csist_filter(csist):
        return

    global gn
    gn = gn + 1
    ranges = [500, 1600]
    if (gn < ranges[0] or gn > ranges[1]):
        pass
        #return

    #plot_phase(csist)
    plot_phase_offset(csist)
    #plot_mag(csist)
    #plot_breath(csist)
    #plot_attack(csist)
    #plot_cir(csist)
    #plot_tof(csist)
    #plot_pll(csist)

    loopn = 1
    loopn = 5
    if not gn % loopn:
        plt.title(gn)
        plt.pause(0.01)
    if not gn % 100:
        plt.clf()
        pass


def main():
    if len(sys.argv) < 4:
        print("* usage: {} iax/in file/wlan csipath/mon0 savepath.".format(sys.argv[0]))
        exit(0)

    csi_type = flqcsi_type.IAXCSI_TYPE
    if sys.argv[1] != "iax":
        csi_type = flqcsi_type.INCSI_TYPE

    wlan = None
    csipath = None
    file_not_netlink = True
    if sys.argv[2] == "file":
        csipath = sys.argv[3]
        file_not_netlink = True
    else:
        wlan = sys.argv[3]
        file_not_netlink = False

    savepath = None
    if len(sys.argv) > 4:
        savepath = sys.argv[4]

    flqcsi(csi_type=csi_type, file_not_netlink=file_not_netlink, 
        wlan=wlan, csipath=csipath, savepath=savepath, 
        csist_callback=csist_callback).start()

    #plt.show()

    exit(0)


    flqcsi_pool([
        flqcsi(flqcsi_type.INCSI_TYPE, False, savepath=None,
        csist_callback=csist_callback),
        flqcsi(flqcsi_type.INCSI_TYPE, True, csipath=in_csipath,
        csist_callback=csist_callback),
    ]).start()

    #plt.show()


sns.set_style("whitegrid", {'axes.linewidth':0.2})    
if __name__ == '__main__':
    main()
