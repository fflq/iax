
import os
import sys

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import scipy

from pyiaxcsi.iaxcsi_st import csi_st


class spotfi_envs_c:
    def __init__(self):
        self.c = 3e8 
        self.origin_spotfi = True
        self.set_origin_spotfi()

    def recalc(self):
        self.nant_sm = int(self.nrx/2) + 1
        self.ntone_sm = int(self.ntone/2)
        self.lambd = self.c/self.fc

    def set_origin_spotfi(self):
        self.fs = 312.5e3 
        self.nrx, self.ntx, self.ntone = 3, 1, 30
        self.corr_threshold = 0.4 
        self.fc = 5.63e9
        self.d = 2.6e-2 
        self.niter = 2 
        self.nsignal = 2 
        self.corr_threshold = 0.4 ;
        self.subcs = np.arange(-58,58+1,4)
        self.en = False
        self.grid_size = np.array([181, 101])
        self.tofs_range = np.array([-50, 50])*1e-9
        self.aoas_range = np.array([-90, 90])
        self.recalc()

    def to_ax210(self, csist: csi_st):
        self.origin_spotfi = False
        self.nrx, self.ntx, self.ntone = csist.nrx, csist.ntx, csist.nstone
        self.fc = 5.2e9
        self.subcs = csist.subc.subcs
        if csist.mod_type_str == "HE":
            self.fs = 78.125e3
        self.recalc()
        return self


def spotfi(csi, envs: spotfi_envs_c):
    #envs = spotfi_envs(envs) 
    
    csi = tof_sanitization(csi, envs.subcs)
    csi = smooth_csi(csi, envs)

    aoatofs = aoatof_music(csi, envs)
    #print(aoatofs)
    return aoatofs[0,0] 


def tof_sanitization(csi, subcs):
    #subcs = envs.subcs

    unwrap_phase = np.unwrap(np.angle(csi), axis=1)
    mag = np.abs(csi)

    x = np.tile(subcs, 2)
    y = np.reshape(unwrap_phase, [-1])
    z = np.polyfit(x, y, 1)
    k, b = z[0], z[1]

    for n in range(len(subcs)):
        #unwrap_phase[:,0,n] = unwrap_phase[:,0,n] - subcs[n]*k - b
        unwrap_phase[:,n] = unwrap_phase[:,n] - subcs[n]*k - b
    phaoff12 = np.unwrap(unwrap_phase[1] - unwrap_phase[0])
    #sns.lineplot(phaoff12)
    #sns.lineplot(unwrap_phase[0])

    csi = mag * np.exp(1j * unwrap_phase)
    return csi


def smooth_csi(csi, envs):
    nrow_csi_smed = envs.nant_sm * envs.ntone_sm
    ncol_csi_smed = (envs.ntone-envs.ntone_sm+1)*(envs.nrx-envs.nant_sm+1)
    csi_smed = np.zeros((nrow_csi_smed, ncol_csi_smed),complex)
    
    colidx = 0
    for antidx in range(envs.nrx-envs.nant_sm+1):
        for toneidx in range(envs.ntone-envs.ntone_sm+1):
            tmpcsi = np.array([])
            for wantidx in range(antidx,antidx+envs.nant_sm):
                rg = np.arange(toneidx, toneidx+envs.ntone_sm)
                #union1d will wrong
                tmpcsi = np.append(tmpcsi, csi[wantidx,rg])
            csi_smed[:,colidx] = tmpcsi
            colidx = colidx + 1
    return csi_smed


def divide_eigvecs(csi, envs):
    xxt = np.matmul(csi, np.conj(csi.T))
    #xxt = np.matmul(envs.mcsi, (envs.mcsi.T))

    #little diff from matlab
    #is complex128, eigvals first 27 is <1e-8, so eigvecs diff from matlab
    [eigvals, eigvecs] = np.linalg.eigh(xxt)
    #already ordered
    #[eigvals, eigvals_idx] = [np.sort(eigvals), np.argsort(eigvals)]
    #eigvecs = eigvecs[eigvals_idx]
    #print(np.sum(np.abs(xxt)), np.sum(np.abs(eigvecs)))
    #print(np.sum(np.abs(eigvecs), axis=0))
    #eigvecs = eigvecs.T

    maxratio = 0
    for noiseidx in range(len(eigvals)-1,0,-1):
        if (eigvals[noiseidx] < 1e-6): break
        ratio = eigvals[noiseidx] / eigvals[noiseidx-1]
        if ratio < maxratio: break
        maxratio = ratio
    if envs.nsignal > 0:
        noiseidx = len(eigvals) - envs.nsignal 

    en = eigvecs[:,0:noiseidx]
    es = eigvecs[:,noiseidx:]
    esvals = eigvals[noiseidx:]
    #print(esvals, es)
    num_noise = noiseidx 
    print("* noise_num %d/%d" % (num_noise, len(eigvals)))
    return [es, en]


def get_aoas_tofs(envs):
    aoas_step = (envs.aoas_range[1] - envs.aoas_range[0]) / (envs.grid_size[0] - 1)
    tofs_step = (envs.tofs_range[1] - envs.tofs_range[0]) / (envs.grid_size[1] - 1)
    aoas = np.arange(envs.aoas_range[0], envs.aoas_range[1]+aoas_step, aoas_step)
    tofs = np.arange(envs.tofs_range[0], envs.tofs_range[1]+tofs_step, tofs_step)
    #print(aoas_step, aoas.shape, tofs_step, tofs.shape)
    return [aoas, tofs]


def get_aoatofs_rapmusic(aoas, tofs, es, en, envs):
    aoatofs = np.array([])
    nsignal = es.shape[1]
    max_corr = np.zeros((nsignal, 1))
    nloop = min(nsignal, envs.niter)

    for i in range(nloop):
        print("* no.%d iter" % (i))
        pmu = rapmusic_spectrum(aoas, tofs, es, en, aoatofs, envs)
        #print(pmu)
        #sns.scatterplot(pmu.flatten())
        #sns.lineplot(pmu.flatten())
        #plt.show()
        [aoa, tof, max_corr[i]] = find_pmu_max(pmu, aoas, tofs)
        print(aoa, tof*1e9, max_corr[i])

        if (max_corr[i] <= envs.corr_threshold*max(max_corr)):
            print("* break %f <= %f*%f" % (max_corr[i], envs.corr_threshold, max(max_corr)))
            break
        #aoatofs = np.append(aoatofs, [aoa, tof])
        if len(aoatofs) == 0:
            aoatofs = np.array([[aoa, tof]])
        else:
            aoatofs = np.concatenate([aoatofs, [[aoa, tof]]])
    return aoatofs


def aoatof_music(csi, envs: spotfi_envs_c):
    [es, en] = divide_eigvecs(csi, envs)
    [aoas, tofs] = get_aoas_tofs(envs)
    aoatofs = get_aoatofs_rapmusic(aoas, tofs, es, en, envs)
    return aoatofs


############# rapmuic
def get_aoatofA(aoas, tofs, envs, is_iter):
    tofA_subcs = envs.subcs[0:envs.ntone_sm]
    tofA_subcs = np.array([tofA_subcs])
    tofs = np.array([tofs])
    tofA = omega_tau(tofs, envs.fs, tofA_subcs)

    radius = (envs.nant_sm-1)/2
    aoaA_range = np.arange(-radius, radius+0.5)
    aoaA_range = np.array([aoaA_range])
    aoas = np.array([aoas])
    aoaA = phi_theta(aoas.T, envs.fc, envs.d, aoaA_range.T)

    #print(tofA.shape, aoaA.shape)
    if (envs.origin_spotfi and is_iter):
        aoatofA = np.matmul(tofA, np.transpose(aoaA))
        aoatofA = aoatofA.flatten()
    else:
        aoatofA = np.kron(aoaA, tofA)
    return aoatofA

def omega_tau(tau, fs, extras):
    return np.exp(-1j * 2*np.pi * extras.T * fs * tau)
    return np.exp(-1j * 2*np.pi * fs * tau * extras.T)

def phi_theta(theta, fc, d, extras):
    c = 3e8
    return np.exp(-1j * 2*np.pi * d * (fc/c) * np.sin(np.deg2rad(theta.T)) * extras)
    return np.exp(-1j * 2*np.pi * d * (fc/c) * np.sin(np.deg2rad(theta)) * extras.T)


def rapmusic_spectrum(aoas, tofs, es, en, aoatofs_prev, envs):
    [naoa, ntof] = [len(aoas), len(tofs)]

    pers_aoatofA = get_aoatofA(aoas, tofs, envs, False)
    perpAhat = np.eye(len(pers_aoatofA))
    if len(aoatofs_prev) != 0:
        Ahat = get_aoatofA(aoatofs_prev[:,0].T, aoatofs_prev[:,1].T, envs, True)
        AhatCT = np.conj(Ahat.T)
        aht_pinv_mul = np.matmul(Ahat, np.linalg.pinv(np.matmul(AhatCT,Ahat)))
        perpAhat = np.eye(len(Ahat)) - np.matmul(aht_pinv_mul, AhatCT)
    aoatofAP = np.matmul(perpAhat, pers_aoatofA)

    if (envs.en):
        en_ent = np.matmul(en, np.conj(en.T))
        p = np.sum(aoatofAP * np.conj(np.matmul(en_ent, aoatofAP)), axis=0).T
        m = np.abs(1/p)
    else:
        es = np.matmul(perpAhat, es)
        es_est = np.matmul(es, np.conj(es.T))
        q = np.sum(aoatofAP * np.conj(np.matmul(es_est, aoatofAP)), axis=0).T
        p = np.sum(aoatofAP * np.conj(aoatofAP), axis=0).T
        m = np.abs(q/p)

    #print(m)
    #print(len(m), ntof, naoa)
    return m.reshape(ntof, naoa).T


#pmu(naoa,ntof)
def find_pmu_max(pmu, aoas, tofs):
    [naoa, ntof] = [len(aoas), len(tofs)]
    [maxv, maxi] = [np.max(pmu), np.argmax(pmu)]
    print(maxv, maxi)
    [aoaidx, tofidx] = [int(maxi/ntof), maxi%ntof]
    return [aoas[aoaidx], tofs[tofidx], maxv]
    

############# rapmuic











