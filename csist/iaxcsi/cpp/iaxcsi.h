#ifndef _IAXCSI_H_
#define _IAXCSI_H_

static map<uint32_t, string> g_mod_type_map = {
	{ RATE_MCS_CCK_MSK, "CCK" }, 
	{ RATE_MCS_LEGACY_OFDM_MSK, "NOHT" }, 
	{ RATE_MCS_HT_MSK, "HT" }, 
	{ RATE_MCS_VHT_MSK, "VHT" }, 
	{ RATE_MCS_HE_MSK, "HE" }, 
	{ RATE_MCS_EHT_MSK, "EH" }, 
} ;

static map<uint32_t, string> g_he_type_map = {
	{ RATE_MCS_HE_TYPE_SU, "HE-SU" }, 
	{ RATE_MCS_HE_TYPE_EXT_SU, "HE-EXT-SU" }, 
	{ RATE_MCS_HE_TYPE_MU, "HE-MU" }, 
	{ RATE_MCS_HE_TYPE_TRIG, "HE-TRIG" }, 
} ;

static map<uint32_t, int> g_chan_width_map = {
	{ RATE_MCS_CHAN_WIDTH_20, 20 }, 
	{ RATE_MCS_CHAN_WIDTH_40, 40 }, 
	{ RATE_MCS_CHAN_WIDTH_80, 80 }, 
	{ RATE_MCS_CHAN_WIDTH_160, 160 }, 
	{ RATE_MCS_CHAN_WIDTH_320, 320 }, 
} ;


/*
%len=(nrx,ntx,ntone)*4
%NOHT/BCC
%NOHT20: 208=(1,1,52), 416=(2,1,52), 832=(2,2,52)
%HT/BCC
%HT20: 224=(1,1,56), 448=(2,1,56), 896=(2,2,56)
%HT40: 456=(1,1,114), 912=(2,1,114), 1824=(2,2,114)
%VHT/BCC
%VHT80: 968=(1,1,242), 1936=(2,1,242), 3872=(2,2,242)
%doc 484(fit data+pilot). rp(3872,484)
%VHT160: 1992=(1,1,498), 3984=(2,1,498), 7968=(2,2,498) 
%HE/LDPC
%HE20: 968=(1,1,242), 1936=(2,1,242), 3872=(2,2,242)
%HE40: 1936=(1,1,484), 3872=(2,1,484), 7744=(2,2,484)
%HE80: 3984=(1,1,996), 7968=(2,1,996), 15936=(2,2,996)
% may 1992. rp(15936/1992), 2020[23, 32, 1970, 2002, 2025]
%HE160: 8080=(1,1,2020), 16160=(2,1,2020), 32320=(2,2,2020) 
*/

//little endian
typedef struct __attribute__((packed)) csi_hdr_t {
	uint32_t csi_len ; // 0
	uint8_t v4_7[4] ; // 4
	uint32_t ftm ; // 8
	uint8_t v12_45[34] ; // 12
	uint8_t nrx ; // 46
	uint8_t ntx ; // 47
	uint8_t v48_51[4] ; // 48
	uint32_t ntone ; // 52
	uint8_t v56_59[4] ; // 56
	
	uint8_t opp_rssi1 ; // 60
	uint8_t v61[3] ;
	uint8_t opp_rssi2 ; // 64
	uint8_t v65[3] ;
	uint8_t smac[6] ; // 68
	uint8_t v74_75[2] ; // 74
	uint8_t seq ; // 76
	uint8_t v77_87[11] ; // 77
	uint32_t us ; // 88
	uint32_t rate_n_flags ; // 92
	uint8_t v96_207[112] ; // 96
	uint64_t ts ; // 208

	uint8_t v214_271[0] ; // 214
} csi_hdr_t, *p_csi_hdr_t ; 


typedef struct rate_info_t {
	int mod_type ;
	const char *mod_type_str ;
	int he_type = -1 ;
	const char *he_type_str = nullptr ;
	int chan_width_type ;
	int chan_width ;
	const char *chan_type_str = nullptr ;
	int ant_sel ;
	int ldpc ;
} rate_info_t, *p_rate_info_t ;


//from include/netlink-private/types.h, origin struct nl_sock
struct csi_nl_sock
{
	struct sockaddr_nl s_local;
	struct sockaddr_nl s_peer;
	int	s_fd;
	int	s_proto;
	unsigned int s_seq_next;
	unsigned int s_seq_expect;
	int	s_flags;
	struct nl_cb *s_cb;
	size_t s_bufsize;
};

#endif
