# ref from iwl_fw_api.rs.h, only keep related


'''
/* rate_n_flags bit field version 2 //fflq
 *
 * The 32-bit value has different layouts in the low 8 bits depending on the
 * format. There are three formats, HT, VHT and legacy (11abg, with subformats
 * for CCK and OFDM).
 *
 */
'''


'''
/*
 * Legacy CCK rate format for bits 0:3:
 *
 * (0) 0xa - 1 Mbps
 * (1) 0x14 - 2 Mbps
 * (2) 0x37 - 5.5 Mbps
 * (3) 0x6e - 11 nbps
 *
 * Legacy OFDM rate format for bis 3:0:
 *
 * (0) 6 Mbps
 * (1) 9 Mbps
 * (2) 12 Mbps
 * (3) 18 Mbps
 * (4) 24 Mbps
 * (5) 36 Mbps
 * (6) 48 Mbps
 * (7) 54 Mbps
 *
 */
'''
RATE_LEGACY_RATE_MSK = 0x7


'''
/*
 * HT, VHT, HE, EHT rate format for bits 3:0
 * 3-0: MCS
 *
 */
'''
RATE_HT_MCS_CODE_MSK = 0x7
RATE_MCS_NSS_POS = 4
RATE_MCS_NSS_MSK = (1 << RATE_MCS_NSS_POS)
RATE_MCS_CODE_MSK = 0xf
# #define RATE_HT_MCS_INDEX(r)	((((r) & RATE_MCS_NSS_MSK) >> 1) | ((r) & RATE_HT_MCS_CODE_MSK))
def RATE_HT_MCS_INDEX(r):	
    return ((((r) & RATE_MCS_NSS_MSK) >> 1) | ((r) & RATE_HT_MCS_CODE_MSK))


'''
/* Bits 7-5: reserved */
'''


'''
/*
 * Bit 11-12: (0) 20MHz, (1) 40MHz, (2) 80MHz, (3) 160MHz
 * 0 and 1 are valid for HT and VHT, 2 and 3 only for VHT
 */
'''
RATE_MCS_CHAN_WIDTH_POS	= 11
RATE_MCS_CHAN_WIDTH_MSK_V1 = (3 << RATE_MCS_CHAN_WIDTH_POS)


'''
/* Bit 14-16: Antenna selection (1) Ant A, (2) Ant B, (4) Ant C */
'''
RATE_MCS_ANT_POS = 14
RATE_MCS_ANT_A_MSK = (1 << RATE_MCS_ANT_POS)
RATE_MCS_ANT_B_MSK = (2 << RATE_MCS_ANT_POS)
RATE_MCS_ANT_AB_MSK	= (RATE_MCS_ANT_A_MSK | RATE_MCS_ANT_B_MSK)
RATE_MCS_ANT_MSK = RATE_MCS_ANT_AB_MSK



'''
/* Bits 10-8: rate format
 * (0) Legacy CCK (1) Legacy OFDM (2) High-throughput (HT)
 * (3) Very High-throughput (VHT) (4) High-efficiency (HE)
 * (5) Extremely High-throughput (EHT)
 */
//fflqkey choose rate_n_flags to ht vht he
'''
RATE_MCS_MOD_TYPE_POS = 8
RATE_MCS_MOD_TYPE_MSK = (0x7 << RATE_MCS_MOD_TYPE_POS)
RATE_MCS_CCK_MSK = (0 << RATE_MCS_MOD_TYPE_POS)
RATE_MCS_LEGACY_OFDM_MSK = (1 << RATE_MCS_MOD_TYPE_POS)
RATE_MCS_HT_MSK	= (2 << RATE_MCS_MOD_TYPE_POS)
RATE_MCS_VHT_MSK = (3 << RATE_MCS_MOD_TYPE_POS)
RATE_MCS_HE_MSK	= (4 << RATE_MCS_MOD_TYPE_POS)
RATE_MCS_EHT_MSK = (5 << RATE_MCS_MOD_TYPE_POS)

'''
/*
 * Bits 13-11: (0) 20MHz, (1) 40MHz, (2) 80MHz, (3) 160MHz, (4) 320MHz //fflqkey bw
 */
'''
RATE_MCS_CHAN_WIDTH_MSK	= (0x7 << RATE_MCS_CHAN_WIDTH_POS)
RATE_MCS_CHAN_WIDTH_20 = (0 << RATE_MCS_CHAN_WIDTH_POS)
RATE_MCS_CHAN_WIDTH_40 = (1 << RATE_MCS_CHAN_WIDTH_POS)
RATE_MCS_CHAN_WIDTH_80 = (2 << RATE_MCS_CHAN_WIDTH_POS)
RATE_MCS_CHAN_WIDTH_160	= (3 << RATE_MCS_CHAN_WIDTH_POS)
RATE_MCS_CHAN_WIDTH_320	= (4 << RATE_MCS_CHAN_WIDTH_POS)


'''
/* Bit 16 (1) LDPC enables, (0) LDPC disabled */
'''
RATE_MCS_LDPC_POS = 16
RATE_MCS_LDPC_MSK = (1 << RATE_MCS_LDPC_POS)


'''
/* Bit 24-23: HE type. (0) SU, (1) SU_EXT, (2) MU, (3) trigger based */
'''
RATE_MCS_HE_TYPE_POS = 23
RATE_MCS_HE_TYPE_SU	= (0 << RATE_MCS_HE_TYPE_POS)
RATE_MCS_HE_TYPE_EXT_SU	= (1 << RATE_MCS_HE_TYPE_POS)
RATE_MCS_HE_TYPE_MU	= (2 << RATE_MCS_HE_TYPE_POS)
RATE_MCS_HE_TYPE_TRIG = (3 << RATE_MCS_HE_TYPE_POS)
RATE_MCS_HE_TYPE_MSK = (3 << RATE_MCS_HE_TYPE_POS)

