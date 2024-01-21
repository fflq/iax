#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import socket
import threading
import struct
import time

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import scipy

from pyiaxcsi.iaxcsi_netlink import iaxcsi_netlink
from pyiaxcsi.iaxcsi_file import iaxcsi_file
from pyiaxcsi.iaxcsi_st import iaxcsi_st, csi_st

from spotfi import spotfi

#from realtime_ploter import realtime_ploter


def dl_phase_offset(csist: csi_st):
    if not len(gploty):
        try:
            os.truncate('phaoffs68.npy', 0)
            os.truncate('phaoffs-246.npy', 0)
        except:
            pass

    phaoff12 = np.unwrap(np.angle(csist.scsi[1,0] * np.conj(csist.scsi[0,0])))
    avg_phaoff12 = np.mean(phaoff12)
    gploty.append(phaoff12)
    print(np.mean(gploty))

    phaoff_type = 0.68 - (0 if avg_phaoff12>0 else 3.14)
    phaoff_type = int(100*phaoff_type)
    print('sel ', phaoff_type)
    with open('phaoffs{}.npy'.format(phaoff_type), 'ab') as f:
        np.save(f, phaoff12[0:50])

    sns.lineplot(x=csist.subc.subcs, y=phaoff12)


def dl_test_phase_offset(csist: csi_st):
    if not len(gploty):
        try:
            os.truncate('test.npy', 0)
        except:
            pass

    phaoff12 = np.unwrap(np.angle(csist.scsi[1,0] * np.conj(csist.scsi[0,0])))
    avg_phaoff12 = np.mean(phaoff12)
    gploty.append(phaoff12)
    print(np.mean(gploty))

    phaoff_type = 0.68 - (0 if avg_phaoff12>0 else 3.14)
    phaoff_type = int(100*phaoff_type)
    print('sel ', phaoff_type)
    with open('test.npy'.format(phaoff_type), 'ab') as f:
        np.save(f, phaoff12[0:50])

    sns.lineplot(x=csist.subc.subcs, y=phaoff12)


def plot_mag(csist, gn=0):
    csi = csist.csi
    subcs = np.arange(len(csi[0,0]))-len(csi[0,0])/2
    #sns.lineplot(y=abs(csi[0,0,:])/1, x=subcs)
    #sns.scatterplot(y=abs(csi[0,0,:])/1, x=subcs)

    csi = csist.scsi
    subcs = csist.subc.subcs
    sz = len(subcs)
    #sns.lineplot(np.abs(csi.reshape((-1))))
    #return
    sns.lineplot(y=00+abs(csi[0,0,:])/1, x=subcs)
    #sns.scatterplot(y=00+abs(csi[0,0,:])/1, x=subcs)
    #sns.lineplot(y=00+abs(csi[1,0,:])/1, x=subcs)
    plt.xlabel("Subcarrier index")
    plt.ylabel("Magnitude")
    return;
    #sns.scatterplot(y=00+abs(csi[1,0,:])/1, x=subcs)
    sns.lineplot(y=abs(csi[0,0,:])-abs(csi[1,0,:]), x=subcs)
    sns.lineplot(y=np.zeros(sz), x=subcs)

    pw1 = np.sum(np.abs(csist.csi[0,0])**2)/1e4
    pw2 = np.sum(np.abs(csist.csi[1,0])**2)/1e4
    #sns.scatterplot(x=np.array([gn]), y=np.array([pw1]))
    #sns.scatterplot(x=np.array([gn]), y=np.array([pw2]))


def plot_phase(csist: csi_st):
    csi = csist.csi
    subcs = np.arange(csist.ntone)-csist.ntone/2
    sz = len(subcs)
    #sns.lineplot(y=np.unwrap(np.angle(csi[0,0,0:sz]))/1, x=subcs)

    csi = csist.scsi
    subcs = csist.subc.subcs
    #subcs = subcs[0:5]
    sz = len(subcs)
    plt.figure(12)
    sns.lineplot(y=00+np.unwrap(np.angle(csi[0,0,0:sz])), x=subcs[0:sz])
    #sns.lineplot(y=00+np.unwrap(np.angle(csi[1,0,0:sz])), x=subcs)
    sns.scatterplot(y=00+np.unwrap(np.angle(csi[1,0,0:sz])), x=subcs[0:sz])


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

def calc_ft_theta(csi, xs):
    if (csi.ndim > 1):
        [k1, b1, tones1] = fit_csi(csi[0,0], xs)
        [k2, b2, tones2] = fit_csi(csi[1,0], xs)
        k12 = k2 - k1
        pha12 = np.unwrap(np.angle(tones2 * np.conj(tones1)))
    else:
        [k12, b12, pha12] = fit_csi(csi, xs)
    sns.scatterplot(pha12) 
    sns.lineplot(np.zeros(1000))
    input()

    if (k12 > 0.000183):
        print("* err k12 ", k12)
        #return 0
    #k12 = min(k12, 0.000183)

    c = 3e8
    d = 0.028
    d = 0.1
    df = 78.125
    df = 312.5e3
    #print(c*k12/(-2*np.pi*df*d))
    theta = np.rad2deg(np.arcsin(c*k12/(-2*np.pi*df*d)))
    print("* k12 %f, theta %f" % (k12, theta))
    return theta
   

def plot_ft(csist: csi_st):
    csi = csist.csi
    subcs = np.arange(csist.ntone)-csist.ntone/2
    csi = csist.scsi
    subcs = csist.subc.subcs
    sz = len(subcs)

    #calc_ft_theta(csi[:,:,200:-200])
    calc_ft_theta(csi)
    #sns.lineplot(x=subcs, y=fit_csi(csi[0,0]))
    #sns.scatterplot(x=subcs, y=fit_csi(csi[1,0])-fit_csi(csi[0,0]))

    #phaoff12 = np.unwrap(np.angle(csi[1,0] * np.conj(csi[0,0])))
    #sns.lineplot(x=subcs, y=phaoff12)


def plot_subc(csist: csi_st):
    csi = csist.csi
    subcs = np.arange(csist.ntone)-csist.ntone/2
    csi = csist.scsi
    subcs = csist.subc.subcs
    sz = len(subcs)
    #sns.lineplot(x=subcs, y=fit_csi(csi[0,0]))
    #sns.scatterplot(x=subcs, y=fit_csi(csi[1,0])-fit_csi(csi[0,0]))

    #phaoff12 = np.unwrap(np.angle(csi[1,0] * np.conj(csi[0,0])))
    #sns.lineplot(x=subcs, y=phaoff12)

gattack = []
def plot_attack(csist: csi_st):
    avgmag = (abs(csist.scsi[0,0,0]) + abs(csist.scsi[1,0,0])) / 2 
    gattack.append(avgmag)
    num = len(gattack)
    start = max(num-2,0)
    sns.lineplot(x=np.arange(start,num), y=gattack[start:num])


gploty = [0]
def plot_phase_offset(csist: csi_st, fid = 13, adjust=False):
    csi = csist.csi
    subcs = np.arange(csist.ntone)-csist.ntone/2
    csi = csist.scsi
    subcs = csist.subc.subcs

    [dk, db, dtone] = iaxcsi_st.fit_csi(csi[1,0] * np.conj(csi[0,0]), subcs)
    phaoff12 = np.unwrap(np.angle(csi[1,0] * np.conj(csi[0,0])))
    print("* phaoff12 ", np.mean(phaoff12), dk, db)
    '''
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
    '''
    plt.figure(fid)
    sns.lineplot(x=subcs, y=phaoff12)
    #sns.lineplot(x=subcs, y=-phaoff12)


g_ns1 = []
g_ns2 = []
#grp = realtime_ploter(10)
def plot_cir(csist: csi_st):
    cfr = csist.scsi[:,0] 
    cir = np.fft.ifft(cfr)
    #sameto, cir = np.array([cir1, cir2])
    cir = cir[:,0:60]
    dt = 1e9 / (csist.chan_width * 1e6) #ns
    xs = np.arange(0, cir.shape[1])*dt 
    #i = np.argmax(np.real(cir)) 
    #print("t({}) d({})".format(xs[i], xs[i]*0.3))
    sns.lineplot(x=xs, y=np.abs(cir[0]))
    sns.scatterplot(x=xs, y=np.abs(cir[0]))
    sns.lineplot(x=xs, y=100+np.abs(cir[1]))
    sns.scatterplot(x=xs, y=100+np.abs(cir[1]))

    g_ns = g_ns1
    max_x1 = np.argmax(np.abs(cir[0])) * dt
    g_ns.append(max_x1)
    m = np.mean(g_ns[max(0, len(g_ns)-100):-1])
    print("ns1------------", m)

    g_ns = g_ns2
    max_x2 = np.argmax(np.abs(cir[1])) * dt
    g_ns.append(max_x2)
    m = np.mean(g_ns[max(0, len(g_ns)-100):-1])
    print("ns2============", m)

    #grp.add_points(max_x2-max_x1)

    #input()
     

def plot_aoa(aoa):
    plt.figure(9)
    r = 8 
    aoa = 90 - aoa
    raoa = np.deg2rad(aoa)
    x, y = r*np.cos(raoa), r*np.sin(raoa)
    plt.clf()
    sns.lineplot(x=[0, x], y=[0, y], linewidth=10)
    plt.xlim(-10,10)
    plt.ylim(0,10)


def do_spotfi(csist: csi_st):
    #csist.calib_scsi_by_phaoff12(2.83)
    envs = spotfi.spotfi_envs_c().to_ax210(csist)
    envs.niter = 1 
    aoa = spotfi.spotfi(csist.scsi[:,0,:], envs)
    print("************* ", aoa)
    plot_aoa(aoa)


sfd, cfd = None, None
def send_csist(iaxcsist: iaxcsi_st):
    def tcp_server_thread():
        global sfd, cfd
        with socket.create_server(('0.0.0.0', 7120), reuse_port=True) as sfd:
            while True:
                cfd, addr = sfd.accept()
                print("* accept ", str(addr))
    global sfd, cfd
    if sfd is None: threading.Thread(target=tcp_server_thread).start()
    if cfd is not None:
        try:
            csi_hdr_len, csi_data_len = len(iaxcsist.csi_hdr), len(iaxcsist.csi_data)
            cfd.send(struct.pack('>i', csi_hdr_len+csi_data_len+8))
            cfd.send(struct.pack('>i', csi_hdr_len))
            cfd.send(iaxcsist.csi_hdr)
            cfd.send(struct.pack('>i', csi_data_len))
            cfd.send(iaxcsist.csi_data)
        except:
            cfd = None 
            print("* client offline")


def csist_filter(csist: csi_st):
    #if csist.mcs_index: return False
    #if not (csist.ntx==1 and csist.nrx == 2): return False
    if csist.nrx < 2: return False
    if abs(csist.rssi1 - csist.rssi2) < 2: return False

    #for calib
    #if csist.rssi1 + csist.rssi2 < -10: return
    pw1 = np.sum(np.abs(csist.csi[0,0])**2)/1e4
    pw2 = np.sum(np.abs(csist.csi[1,0])**2)/1e4

    # 1dbm => 1.25
    if abs(pw1-pw2)/pw1 < 0.25: return False

    return True

    pws1 = np.abs(csist.csi[0,0])
    pws2 = np.abs(csist.csi[1,0])
    pws_cond = len((pws1 > pws2)==True)/len(pws1) > 0.8
    print("* rssi({},{}) pw({},{},{})".format(csist.rssi1, csist.rssi2, pw1, pw2, abs(pw1-pw2)/pw1))
    #if pws_cond != (csist.rssi1 > csist.rssi2): return False
    if (abs(pw1-pw2)/pw2 < 0.2): return False
    if abs(csist.rssi1-csist.rssi2) < 3: return False
    if csist.rssi1 <= csist.rssi2 or pw1 <= pw2: return False

    print("*** dk db ")
    [dk, db, dtone] = fit_csi(csist.scsi[1,0] * np.conj(csist.scsi[0,0]), csist.subc.subcs)
    #if abs(dk) > 0.1: return False
    #if abs(dk) > 0.03: return False
    #if dk > 0: input('** dk > 0'); return False

    return True


#for same sta
last_deltab = 0
#lastb1, lastb2 = 0, 0
lastpha = None
def preprocess(csist: csi_st):
    #*cond1: (rssi1-rssi2)>=3, ((pw1-pw2)/pw1>=0.05).
    #*(no perm because always has special, eg, always use perm(1,2))
    #conn with(pw,rssi), get [0.57up, 0.3up]
    #*cond2: full conn, get [2.2up, 2.5up, piup, 0.62down]
    #csist.calib_scsi_by_phaoff12(0.53)

    #follow rx-ant2 add 20db-att
    #perm: pw rssi. filter: rssi<5 pw>0.05 pws
    #*cond: full conn, perm, get[#1d, 2.1u, 3.1u]
    #--swap att, get[3u, 0d]
    #*cond: air conn, tx-has-ant, rx-ants in split, unstable[1u,2d]
    #*cond: air conn, tx-has-ant, rx-ants, 0 deg, unstable[2.2d,1u]
    #--air unstable by dist, may mp

    #20230401
    #only handle rssi1>rssi2 and pw1>pw2
    
    #20230404
    #in (rssi1>>rssi2){rx2-att20}, (pw1>>pw2){full-conn 
    # or tx1-no-ant or tx2-with-ant(only tx1 send)}
    #*cond: full conn, get[2.2]
    #*cond: air-split txnoant, get[1.7,2.5]
    #*cond: air-split txant, get[1.8,etc]
    #csist.scsi[1] = csist.scsi[0] * np.exp(-1j*np.pi/6)
    #csist.scsi[:,0,:] = spotfi.tof_sanitization(csist.scsi[:,0,:], csist.subc.subcs)
    csi = csist.scsi
    subcs = csist.subc.subcs

    [k1, b1, tone1] = fit_csi(csi[0,0], subcs)
    [k2, b2, tone2] = fit_csi(csi[1,0], subcs)
    #sns.scatterplot(np.unwrap(np.angle(tone2*np.conj(tone1))))
    def calib_by_delta_kb(csist):
        [deltak, deltab, _] = fit_csi(csist.scsi[1,0] * np.conj(csist.scsi[0,0]), csist.subc.subcs)
        calib_phaoff = deltab + deltak*len(subcs)/2
        calib_phaoff = deltab 
        if(calib_phaoff <= 0): calib_phaoff = calib_phaoff+2*np.pi
        print("* calib_phaoff %f" % (calib_phaoff))
        calib_phaoff = np.pi
        calib_phaoff = 0.5
        calib_phaoff = 0
        #csist.calib_scsi_by_phaoff12(calib_phaoff)
        return csist
    #return calib_by_delta_kb(csist)

    #once change is less than
    def angle_mod(ang):
        r = np.mod(ang, 2*np.pi)
        #r = (r - 2*np.pi) if(r > np.pi) else r
        while r > np.pi: r = r - 2*np.pi
        while r < -np.pi: r = r + 2*np.pi
        return r

    def calib_by_last_delta_kb(csist, calib_phaoff = 0):
        global last_deltab
        [dk, deltab, _] = fit_csi(csist.scsi[1,0] * np.conj(csist.scsi[0,0]), csist.subc.subcs)
        if last_deltab == 0: last_deltab = deltab
        print("****** last_deltab(%f) deltab(%f) %f" % (last_deltab, deltab, angle_mod(last_deltab-deltab)))
        if not (np.abs(angle_mod(last_deltab - deltab)) < np.pi/3):
            print("* last_deltab(%f) - deltab(%f) > x" % (last_deltab, deltab))
            deltab = deltab - np.pi
            calib_phaoff = calib_phaoff - np.pi
        last_deltab = deltab
        csist.calib_scsi_by_phaoff12_only(calib_phaoff)
        return csist
    #return calib_by_last_delta_kb(csist, 3.5)
    #return calib_by_last_delta_kb(csist, 2.7)


    def calib_by_tof_sant(csist):
        unwrap_phase = np.unwrap(np.angle(csist.scsi), axis=1)
        x = np.tile(csist.subc.subcs, 2)
        y = np.reshape(unwrap_phase, [-1])
        z = np.polyfit(x, y, 1)
        k, b = z[0], z[1]
        unwrap_phase[0] = unwrap_phase[0] - csist.subc.subcs*k - b
        global lastpha
        calib_phaoff = 0
        if lastpha is None:
            lastpha = unwrap_phase[0] 
        loss = np.mean(np.abs(unwrap_phase[0] - lastpha))
        lastpha = unwrap_phase[0] 
        if loss > np.pi-0.2:
            lastpha = lastpha - np.pi
            calib_phaoff = calib_phaoff - np.pi
        print(lastpha)
        csist.calib_scsi_by_phaoff12_only(calib_phaoff)
        print("******* lost ", loss)
        return csist 
    #return calib_by_tof_sant(csist)


def do_perm(csist: csi_st):
    plot_phase_offset(csist, 21)

    #发现offs=0时perm12貌似可以, filter=(0,1]
    if abs(csist.rssi1 - csist.rssi2) < 2:
        print("* skip offs(rssi)<2")
        return

    if csist.rssi2 > csist.rssi1:
        iaxcsi_st.perm_csi(csist, np.array([2,1]))
        print("---")
        #input("---")
    plot_phase_offset(csist, 22)
    #input("--")


gn = 0
def iaxcsist_callback(iaxcsist: iaxcsi_st):
    csist = iaxcsist.csist
    #return
    #if not csist_filter(csist): print("*** pass"); return

    global gn 
    gn = gn + 1
    #if gn > 2: return

    print("* gn {}".format(gn))
    #preprocess(csist)
    #plot_mag(csist, gn)
    #plot_phase(csist)
    plot_phase_offset(csist)
    #plot_attack(csist)
    #plot_cir(csist)
    #plot_ft(csist)
    #dl_phase_offset(csist)
    #dl_test_phase_offset(csist)
    #do_spotfi(csist)
    #send_csist(iaxcsist); #time.sleep(1) 
    #do_perm(csist)
    #return 
    

    loopn = 10
    loopn = 1
    if not gn % loopn:
        plt.title(gn)
        plt.pause(0.01)
        #plt.show()
    if not gn % loopn:
        #plt.clf()
        pass

    #input()



sns.set_style("whitegrid", {'axes.linewidth':0.2})    

#plt.ion()
#plt.figure(1)
if sys.argv[1] == 'file':
    iaxcsi_file(sys.argv[2], None, iaxcsist_callback).start()
else:
    iaxcsi_netlink(sys.argv[1], sys.argv[2], None, iaxcsist_callback).start()
#plt.ioff()
plt.show()
