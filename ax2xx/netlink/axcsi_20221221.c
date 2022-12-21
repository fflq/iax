#include <netlink/netlink.h>
#include <netlink/socket.h>
#include <netlink/msg.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/family.h>
#include <netlink/genl/ctrl.h>  
#include <linux/nl80211.h>      
#include <net/if.h>
#include <unistd.h>
#include <errno.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "iwl_fw_api_rs.h"

#define DEBUG
#ifdef DEBUG
#define flqstdout(fmt, ...)	fprintf(stdout, fmt, ##__VA_ARGS__)
#else
#define flqstdout(fmt, ...)	
#endif


enum {
	CH_TYPE_NOHT,
	CH_TYPE_HT20,
	CH_TYPE_HT40,
	CH_TYPE_VHT80,
	CH_TYPE_VHT160,
	CH_TYPE_HE20,
	CH_TYPE_HE40,
	CH_TYPE_HE80,
	CH_TYPE_HE160,
	CH_TYPE_MAX
} ;
//#define GET_CH_TYPE_STR(ch_type) ##
typedef struct ch_type {
	int idx ;
	int ntone ;
	int single_stream_len ;
	char *name ;
	int same_to ;
} ch_type_t, *p_ch_type_t ;

#define CH_TYPE_ROW_SAME(_ch_type,_ntone,_sslen,_same_to) [_ch_type] = \
	{.idx=_ch_type, .ntone=_ntone, .single_stream_len=_sslen, .name=#_ch_type, .same_to=_same_to}
#define CH_TYPE_ROW(_ch_type,_ntone,_sslen) CH_TYPE_ROW_SAME(_ch_type,_ntone,_sslen,-1)
// NOHT HT20 HT40 VHT80 VHT160 HE20 HE40 HE80 HE160
const ch_type_t g_ch_types[CH_TYPE_MAX] = { 
	CH_TYPE_ROW(CH_TYPE_NOHT, 52, 208), 
	CH_TYPE_ROW(CH_TYPE_HT20, 56, 224), 
	CH_TYPE_ROW(CH_TYPE_HT40, 114, 456), 
	CH_TYPE_ROW_SAME(CH_TYPE_VHT80, 242, 968, CH_TYPE_HE20), 
	CH_TYPE_ROW(CH_TYPE_VHT160, 498, 1992), 
	CH_TYPE_ROW_SAME(CH_TYPE_HE20, 242, 968, CH_TYPE_VHT80), 
	CH_TYPE_ROW(CH_TYPE_HE40, 484, 1936), 
	CH_TYPE_ROW(CH_TYPE_HE80, 996, 3984), 
	CH_TYPE_ROW(CH_TYPE_HE160, 2020, 8080), 
} ;


typedef struct id_str_t {
	int id ;
	char *str ;
}
#define ID_STR_ROW(_id) [_id] = {.id=_ch_type, .str=#_ch_type}
const id_str_t g_mod_types[16] = {
} ;


//from include/netlink-private/types.h, origin struct nl_sock
struct flq_nl_sock
{
	struct sockaddr_nl	s_local;
	struct sockaddr_nl	s_peer;
	int			s_fd;
	int			s_proto;
	unsigned int		s_seq_next;
	unsigned int		s_seq_expect;
	int			s_flags;
	struct nl_cb *		s_cb;
	size_t			s_bufsize;
};


FILE *g_fp_csi = NULL ;
struct nl_cb *gcb = NULL ;
unsigned int gportid = 0;
int gdevidx = -1 ;


void call_iwl_mvm_vendor_csi_register(struct nl_sock *sk, int family_id)
{
  	struct nl_msg* msg = nlmsg_alloc();
  
	//fflqkey, refer __cfg80211_alloc_vendor_skb
#define INTEL_OUI	0X001735
#define IWL_MVM_VENDOR_CMD_CSI_EVENT	0x24
  	//genlmsg_put(msg, NL_AUTO_PORT, NL_AUTO_SEQ, family_id, 0, NLM_F_DUMP, NL80211_CMD_GET_INTERFACE, 0);
  	void *hdr = genlmsg_put(msg, 0, NL_AUTO_SEQ, family_id, 0, NLM_F_MATCH, NL80211_CMD_VENDOR, 0);

	nla_put_u32(msg, NL80211_ATTR_IFINDEX, gdevidx) ;
	//or /sys/class/ieee80211/${phyname}/index
	//nla_put_u32(msg, NL80211_ATTR_WIPHY, 0) ;
  	nla_put_u32(msg, NL80211_ATTR_VENDOR_ID, INTEL_OUI); 
  	nla_put_u32(msg, NL80211_ATTR_VENDOR_SUBCMD, IWL_MVM_VENDOR_CMD_CSI_EVENT); 
	//nla_put(msg, NL80211_ATTR_VENDOR_DATA, 0, NULL) ;

	int r = nl_send_auto(sk, msg);
	flqstdout("%s, send return %d\n", __func__, r) ;

	r = nl_recvmsgs_default(sk) ;
	//struct nl_cb *cb = nl_cb_alloc(NL_CB_DEFAULT);
	//r = nl_recvmsgs_report(sk, gcb); 
	flqstdout("%s, recv return %d\n", __func__, r) ;
}


void output_tb_msg(struct nlattr **tb_msg)
{	
	int i = 0;
	for (i = 0; i < NL80211_ATTR_MAX; ++ i)
	{
		if (tb_msg[i])
			flqstdout("-- tb_msg[%x]: len %d, type %x\n", i, tb_msg[i]->nla_len, tb_msg[i]->nla_type) ;
	}
}


/*
%len=(nrx,ntx,ntone)*4
%NOHT/BCC
%NOHT20: 208=(1,1,52), 416=(2,1,52), 832=(2,2,52)
%HT/BCC
%HT20: 224=(1,1,56), 448=(2,1,56), 896=(2,2,56)
%HT40: 456=(1,1,114), 912=(2,1,114), 1824=(2,2,114)
%VHT/BCC
%VHT80: 968=(1,1,242), 1936=(2,1,242), 3872=(2,2,242)
%VHT160: 1992=(1,1,498), 3984=(2,1,498), 7968=(2,2,498)
%HE/LDPC
%HE20: 968=(1,1,242), 1936=(2,1,242), 3872=(2,2,242)
%HE40: 1936=(1,1,484), 3872=(2,1,484), 7744=(2,2,484)
%HE80: 3984=(1,1,996), 7968=(2,1,996), 15936=(2,2,996)
%HE160: 8080=(1,1,2020), 16160=(2,1,2020), 32320=(2,2,2020)
%Note
%VHT80 and HE20 are same, avoid use
*/
int get_ch_type(int csi_len, int nrx, int ntx, int ntone)
{
	for (int i = CH_TYPE_MAX-1; i >= 0; -- i)
		if (0 == csi_len % g_ch_types[i].single_stream_len)
			return i ;
}


void output_hexs(uint8_t *data, int len)
{
	int n = 0 ;
	for (n = 0; n < len; ++n) {
		if (0 == n % 16)	printf("\n%08d:", n) ;
		else if (0 == n % 8)	printf("  ") ;
		else if (0 == n % 4)	printf(" ") ;
		printf(" %02X", data[n]) ;
	}
	printf("\n") ;
}


void handle_rate_n_flags(uint32_t rate_n_flags)
{
	//Bits 10-8: rate format, mod type
	switch (rate_n_flags & RATE_MCS_MOD_TYPE_MSK) {
		case RATE_MCS_CCK_MSK: 
			printf("*mod_type cck\n") ;
			break ;
		case RATE_MCS_LEGACY_OFDM_MSK:
			printf("*mod_type noht\n") ;
			break ;
		case RATE_MCS_HT_MSK:
			printf("*mod_type ht\n") ;
			break ;
		case RATE_MCS_VHT_MSK:
			printf("*mod_type vht\n") ;
			break ;
		case RATE_MCS_HE_MSK:
			printf("*mod_type he\n") ;
	//Bits 24-23: HE type
	switch (rate_n_flags & RATE_MCS_HE_TYPE_MSK) {
		case RATE_MCS_HE_TYPE_SU :
			printf("* he_type su\n") ;
			break ;
		case RATE_MCS_HE_TYPE_EXT_SU :
			printf("* he_type ext_su\n") ;
			break ;
		case RATE_MCS_HE_TYPE_MU :
			printf("* he_type mu_su\n") ;
			break ;
		case RATE_MCS_HE_TYPE_TRIG :
			printf("* he_type trig\n") ;
			break ;
	}

			break ;
		case RATE_MCS_EHT_MSK:
			printf("*mod_type eht\n") ;
			break ;
	}

	//BIts 13-11: chan width
	switch (rate_n_flags & RATE_MCS_CHAN_WIDTH_MSK) {
		case RATE_MCS_CHAN_WIDTH_20:
			printf("*chan_width 20\n") ;
			break ;
		case RATE_MCS_CHAN_WIDTH_40:
			printf("*chan_width 40\n") ;
			break ;
		case RATE_MCS_CHAN_WIDTH_80:
			printf("*chan_width 80\n") ;
			break ;
		case RATE_MCS_CHAN_WIDTH_160:
			printf("*chan_width 160\n") ;
			break ;
		case RATE_MCS_CHAN_WIDTH_320:
			printf("*chan_width 320\n") ;
			break ;
	}

	//Bits 15-14: antenna selection
	switch (rate_n_flags & RATE_MCS_ANT_MSK) {
	}

	//Bits 16: LDPC enables
	if (rate_n_flags & RATE_MCS_LDPC_MSK) 
		printf("* ldpc\n") ;
	else
		printf("* bcc\n") ;

}

//for little endian
struct csi_hdr_t {
	uint32_t csi_len ; // 0
	uint8_t v4_7[4] ; // 4
	uint32_t ftm ; // 8
	uint8_t v12_45[34] ; // 12
	uint8_t nrx ; // 46
	uint8_t ntx ; // 47
	uint8_t v48_51[4] ; // 48
	uint8_t ntone ; // 52
	uint8_t v53_59[7] ; // 53
	
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
	uint8_t v96_271[0] ; // 96

} __attribute__((packet)) ;
typedef struct csi_hdr_t csi_hdr_t, *p_csi_hdr_t ; 

void handle_csi(uint8_t *csi_hdr, int csi_hdr_len, uint8_t *csi_data, int csi_data_len) 
{
	uint32_t n32 ;

	n32 = htonl(csi_hdr_len) ;
	fwrite(&n32, 1, 4, g_fp_csi) ;
	fwrite(csi_hdr, 1, csi_hdr_len, g_fp_csi) ;
		
	n32 = htonl(csi_data_len) ;
	fwrite(&n32, 1, 4, g_fp_csi) ;
	fwrite(csi_data, 1, csi_data_len, g_fp_csi) ;
	fflush(g_fp_csi) ;

	printf("%d----\n", sizeof(csi_hdr_t)) ;
	csi_hdr_t *pch = (p_csi_hdr_t)csi_hdr ;
	flqstdout("csi_len(%u) ftm(%u) nrx(%u) ntx(%u) ntone(%u)\n", 
			pch->csi_len, pch->ftm, pch->nrx, pch->ntx, pch->ntone) ;
	flqstdout("rssi1(%d) rssi2(%d) seq(%u) us(%u) rnf(0x%x)\n", 
			-pch->opp_rssi1, -pch->opp_rssi2, pch->seq, pch->us, pch->rate_n_flags) ;
	uint8_t *smac = pch->smac ;
	flqstdout("-- mac(%02x:%02x:%02x:%02x:%02x:%02x)\n", 
			smac[0], smac[1], smac[2], smac[3], smac[4], smac[5]) ;


	/*
	flqstdout("* %s, csi_hdr(%02x%02x), csidata(%02x%02x)\n", 
			__func__, *csi_hdr, *(csi_hdr+1), *csi_data, *(csi_data+1)) ;
	*/
	flqstdout("* %s\n", __func__) ;

	uint32_t hdr_csi_len = *(uint32_t*)csi_hdr ;
	uint32_t hdr_ftm = *(uint32_t*)(csi_hdr+8) ;

	uint8_t hdr_nrx = *(csi_hdr+46) ;
	uint8_t hdr_ntx = *(csi_hdr+47) ;
	uint32_t hdr_ntone = *(uint32_t*)(csi_hdr+52) ;
	uint32_t calc_nrx, calc_ntx, calc_ntone ;
	int ch_type = get_ch_type(hdr_csi_len, hdr_nrx, hdr_ntx, hdr_ntone) ;
	int ch_type2 = g_ch_types[ch_type].same_to ; 
	char *ch_type2_name = ch_type2 >= 0 ? g_ch_types[ch_type2].name : "" ;
		
	// rssi in net/mac80211/sta_info.c/sta_set_sinfo() is s8 named x.(from iw dev link)
	// and csi_hdr get is -x, so convert. just compare and guess. 
	// why sep 4B, may struct support 4 ants
	//uint32_t hdr_rssi1 = *(uint32_t*)(csi_hdr+60) - 128 ;
	//uint32_t hdr_rssi2 = *(uint32_t*)(csi_hdr+64) - 128 ;
	uint32_t hdr_rssi1 = -*(csi_hdr+60) ;
	uint32_t hdr_rssi2 = -*(csi_hdr+64) ;

	uint8_t *hdr_mac = csi_hdr+68 ;

	//1B,0-255-loop,may seq
	uint8_t hdr_seq = *(csi_hdr+76) ;

	uint32_t hdr_us = *(uint32_t*)(csi_hdr+88) ;

	uint32_t hdr_rate_n_flags = *(uint32_t*)(csi_hdr+92) ;
	handle_rate_n_flags(hdr_rate_n_flags) ;

	flqstdout("-- mac(%02x:%02x:%02x:%02x:%02x:%02x)\n", 
			hdr_mac[0], hdr_mac[1], hdr_mac[2], hdr_mac[3], hdr_mac[4], hdr_mac[5]) ;
	flqstdout("-- (nrx,ntx,ntone)=(%d,%d,%d), %s %s\n", hdr_nrx, hdr_ntx, hdr_ntone, 
			g_ch_types[ch_type].name, ch_type2_name) ;

	printf("-- rssi(%d,%d) seq(%d) us(%u) ftm(%u) rnf(0x%x)\n", 
			hdr_rssi1, hdr_rssi2, hdr_seq, hdr_us, hdr_ftm, hdr_rate_n_flags) ;
	//system("iw wlp8s0 link | grep signal") ;
	
	//if (hdr_ntx*hdr_nrx*hdr_ntone == 2*2*56)
	output_hexs(csi_hdr, csi_hdr_len) ;
	/*
		*/
}


static int valid_cb(struct nl_msg *msg, void *arg) 
{
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
	struct nlattr *tb_msg[NL80211_ATTR_MAX + 1];
	struct nlattr *msg_vendor_data, *nmsg_csi_hdr = NULL, *nmsg_csi_data = NULL ;
	struct nlattr *nested_tb_msg[NL80211_ATTR_MAX + 1];

	flqstdout("* %s\n", __func__) ;
	//nl_msg_dump(msg, stdout);
	//return NL_SKIP ;

	nla_parse(tb_msg, NL80211_ATTR_MAX,
			genlmsg_attrdata(gnlh, 0), genlmsg_attrlen(gnlh, 0), NULL);
	//output_tb_msg(tb_msg) ;

	if ((msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_ID])) { }
	if ((msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_SUBCMD])) { }

#define IWL_MVM_VENDOR_ATTR_CSI_HDR		0x4d
#define IWL_MVM_VENDOR_ATTR_CSI_DATA	0x4e
	if ((msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_DATA])) {
		flqstdout("-- tb_msg[%x] is vendor_data\n", NL80211_ATTR_VENDOR_DATA) ;
		nla_parse_nested(nested_tb_msg, NL80211_ATTR_MAX, msg_vendor_data, NULL) ;
		output_tb_msg(nested_tb_msg) ;

		nmsg_csi_hdr = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_HDR] ;
	 	nmsg_csi_data = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_DATA] ;
		if (nmsg_csi_hdr && nmsg_csi_data) {
			flqstdout("-- (nla_type,nla_len) csi_hdr(%x,%u) csi_data(%x,%u)\n", 
					nmsg_csi_hdr->nla_type, nmsg_csi_hdr->nla_len,
					nmsg_csi_data->nla_type, nmsg_csi_data->nla_len) ;

			uint16_t csi_hdr_len = nmsg_csi_hdr->nla_len - 4 ;
			uint8_t *csi_hdr = nla_get_string(nmsg_csi_hdr) ;
						
			uint16_t csi_data_len = nmsg_csi_data->nla_len - 4 ;
			uint8_t *csi_data = nla_get_string(nmsg_csi_data) ;

			if ((csi_hdr_len != 272) || !csi_hdr || !csi_data) {
				flqstdout("* %s, csi_hdr_len(%d)!=272 or !csi_hdr or !csi_data\n", __func__, csi_hdr_len) ;
				return NL_SKIP;
			}

			//if (nmsg_csi_data->nla_len == 420 || nmsg_csi_data->nla_len == 832) { }
			handle_csi(csi_hdr, csi_hdr_len, csi_data, csi_data_len) ;
		}
	}

	return NL_SKIP;
}



static int finish_cb(struct nl_msg *msg, void *arg) {
	int *finished = arg;
  	*finished = 1;
  	flqstdout("* %s -------\n", __func__) ;
	nl_msg_dump(msg, stdout);
  	return NL_SKIP;
}


void loop_recv_msg(struct nl_sock *sk)
{
	int n = 0, r ;
	int finished = 0 ;

	//struct nl_cb *cb = nl_cb_alloc(NL_CB_DEFAULT);
  	//nl_cb_set(cb, NL_CB_VALID , NL_CB_CUSTOM, valid_cb, NULL);
  	//nl_cb_set(cb, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &finished);
  	nl_socket_modify_cb(sk, NL_CB_VALID, NL_CB_CUSTOM, valid_cb, NULL);
  	nl_socket_modify_cb(sk, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &finished);

	flqstdout("\n\n") ;
	while (!finished) { 
		//r = nl_recvmsgs(sk, cb); 
		//r = nl_recvmsgs_report(sk, gcb) ;
		r = nl_recvmsgs_default(sk) ;
		//flqstdout("* %s %d, %u nl_recvmsgs %d\n\n", __func__, ++n, gportid, r) ;
		printf("* %s %d, %u nl_recvmsgs %d\n\n", __func__, ++n, gportid, r) ;
		//if (r < 0)	break ;
		if (r < 0){
			flqstdout("* nl_recvmsgs err %d\n\n", r) ;
			continue ;
		}
	}
}


void handle_args(int argc, char **argv)
{
	if (argc < 3) {
		flqstdout("Usage: sudo %s wlan file\n- wlan: eg wlp8s0\n- file: eg ./a.csi\n"
				"* eg: sudo %s wlp8s0 ./a.csi\n", argv[0], argv[0]) ;
		exit(EXIT_FAILURE) ;
	}
	else {
 		gdevidx = if_nametoindex(argv[1]) ;
		g_fp_csi = fopen(argv[2], "w") ;
		if (!gdevidx || !g_fp_csi) {
			flqstdout("* args err(%s), devidx(%d) fp_csi(%p)\n", strerror(errno), gdevidx, g_fp_csi) ;
			exit(EXIT_FAILURE) ;
		}
		flqstdout("* %s, %s/%d %s\n", __func__, argv[1], gdevidx, argv[2]) ;
	}
}


struct nl_sock *init_nl_socket() 
{
	struct nl_sock *sk = nl_socket_alloc() ;

	if (!sk) {
		perror("* failed nl_socket_alloc\n") ;
		return NULL ;
	}

	if (genl_connect(sk)) {
		perror("* failed genl_connect\n") ;
		return NULL ;
	}

	//nl_socket_add_memberships(sk, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0) ; 
	//nl_socket_add_memberships(sk, 13, 0) ; 

  	nl_socket_set_buffer_size(sk, 8192, 8192);
	nl_socket_disable_seq_check(sk) ;
	int family_id = genl_ctrl_resolve(sk, "nl80211") ;
	//family_id = 34 ;
	//int family_id = genl_ctrl_resolve(sk, "iwl_tm_gnl") ;
	//int family_id = genl_ctrl_resolve(sk, "vendor") ;
	if (family_id < 0) {
		perror("* failed genl_ctrl_resolve\n") ;
		return NULL ;
	}

	gcb = nl_cb_alloc(NL_CB_DEFAULT);
  	//nl_cb_set(gcb, NL_CB_VALID , NL_CB_CUSTOM, valid_cb, NULL);
  	//nl_cb_set(gcb, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &gr);

	struct flq_nl_sock *flqsk = (struct flq_nl_sock*)sk ;
	flqstdout("* (nl_family,nl_pid,nl_groups), s_local(%u,%u,%u), s_peer(%u,%u,%u)\n", 
			flqsk->s_local.nl_family, flqsk->s_local.nl_pid, flqsk->s_local.nl_groups,
			flqsk->s_peer.nl_family, flqsk->s_peer.nl_pid, flqsk->s_peer.nl_groups) ;
	gportid = flqsk->s_local.nl_pid ;
	
	//getchar() ;
 	call_iwl_mvm_vendor_csi_register(sk, family_id) ;

	return sk ;
}


void deinit()
{
	if (g_fp_csi)	fclose(g_fp_csi) ;
}


int main(int argc, char **argv)
{
	handle_args(argc, argv) ;
		
	struct nl_sock *sk = init_nl_socket() ;

	loop_recv_msg(sk) ;
	
	deinit() ;

	return 0 ;
}





/*
 * nonuse

void calc_ntxrx(int csi_len, int ntone, int *p_nrx, int *p_ntx, int *p_ntone)
{
	int type, _ntone ;

	if (0 == csi_len%208) {
		type = -20 ;
		_ntone = 52 ;
	}
	else if (0 == csi_len%224) {
		type = 20 ;
		_ntone = 56 ;
	}
	else if (0 == csi_len%456) {
		type = 40 ;
		_ntone = 114 ;
	}
	else if (0 == csi_len%968) {
		type = 80 ;
		_ntone = 242 ;
	}
	else if (0 == csi_len%1936) {
		type = 160 ;
		_ntone = 484 ;
	}
	else {
		flqstdout("* no analysis csi_len=%d?\n",csi_len) ;
		type = -999 ;
		//_ntone = csi_len/4 ;
		_ntone = ntone ;
	}

	if (_ntone != ntone) {
		flqstdout("* _ntone(%d) != ntone(%d)\n", _ntone, ntone) ;
		exit(EXIT_FAILURE) ;
	}
	int nrxtx = csi_len/ntone/4 ;
	//ntx<=ntx
	if (nrxtx >= 2) *p_nrx = 2 ;
	else *p_nrx = 1 ;
	*p_ntx = nrxtx / *p_nrx ;
	*p_ntone = _ntone ;
}

*/

