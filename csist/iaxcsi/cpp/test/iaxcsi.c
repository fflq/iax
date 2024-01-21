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
#include "iaxcsi.h"

#define DEBUG
#ifdef DEBUG
#define flqstdout(fmt, ...)	fprintf(stdout, fmt, ##__VA_ARGS__)
#else
#define flqstdout(fmt, ...)	
#endif


typedef struct pair_t {
	int id ;
	char *str ;
	int num ;
} pair_t, *p_pair_t ;
#define PAIR_RSHIFTN_ROW(_id,_n,_str,_num) [_id>>_n] = {.id=_id,.str=_str,.num=_num}
#define PAIR_STR_RSHIFTN_ROW(_id,_n,_str) PAIR_RSHIFTN_ROW(_id,_n,_str,-1) 
#define PAIR_NUM_RSHIFTN_ROW(_id,_n,_num) PAIR_RSHIFTN_ROW(_id,_n,NULL,_num) 


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

typedef struct rate_info_t {
	int mod_type ;
	char *mod_type_str ;
	int he_type ;
	char *he_type_str ;
	int chan_width ;
	char *chan_width_str ;
	int ant_sel ;
	int ldpc ;
} rate_info_t, *p_rate_info_t ;


#define MOD_TYPE_ROW(_id,_str) PAIR_STR_RSHIFTN_ROW(_id,RATE_MCS_MOD_TYPE_POS,_str)
pair_t g_mod_types[(RATE_MCS_MOD_TYPE_MSK>>RATE_MCS_MOD_TYPE_POS)+1] = {
	MOD_TYPE_ROW(RATE_MCS_CCK_MSK, "CCK"), 
	MOD_TYPE_ROW(RATE_MCS_LEGACY_OFDM_MSK, "NOHT"), 
	MOD_TYPE_ROW(RATE_MCS_HT_MSK, "HT"), 
	MOD_TYPE_ROW(RATE_MCS_VHT_MSK, "VHT"), 
	MOD_TYPE_ROW(RATE_MCS_HE_MSK, "HE"), 
	MOD_TYPE_ROW(RATE_MCS_EHT_MSK, "EH"), 
} ;

#define HE_TYPE_ROW(_id,_str) PAIR_STR_RSHIFTN_ROW(_id,RATE_MCS_HE_TYPE_POS,_str)
pair_t g_he_types[(RATE_MCS_HE_TYPE_MSK>>RATE_MCS_HE_TYPE_POS)+1] = {
	HE_TYPE_ROW(RATE_MCS_HE_TYPE_SU, "HE-SU"), 
	HE_TYPE_ROW(RATE_MCS_HE_TYPE_EXT_SU, "HE-EXT-SU"), 
	HE_TYPE_ROW(RATE_MCS_HE_TYPE_MU, "HE-MU"), 
	HE_TYPE_ROW(RATE_MCS_HE_TYPE_TRIG, "HE-TRIG"), 
} ;

#define CHAN_WIDTH_ROW(_id,_num) PAIR_NUM_RSHIFTN_ROW(_id,RATE_MCS_CHAN_WIDTH_POS,_num)
pair_t g_chan_widths[(RATE_MCS_CHAN_WIDTH_MSK>>RATE_MCS_CHAN_WIDTH_POS)+1] = {
	CHAN_WIDTH_ROW(RATE_MCS_CHAN_WIDTH_20, 20), 
	CHAN_WIDTH_ROW(RATE_MCS_CHAN_WIDTH_40, 40), 
	CHAN_WIDTH_ROW(RATE_MCS_CHAN_WIDTH_80, 80), 
	CHAN_WIDTH_ROW(RATE_MCS_CHAN_WIDTH_160, 160), 
	CHAN_WIDTH_ROW(RATE_MCS_CHAN_WIDTH_320, 320), 
} ;



void handle_rate_n_flags(uint32_t rate_n_flags, p_rate_info_t p_rinfo)
{
	//Bits 10-8: rate format, mod type
	p_rinfo->mod_type = (rate_n_flags & RATE_MCS_MOD_TYPE_MSK) >> RATE_MCS_MOD_TYPE_POS ; 
	p_rinfo->mod_type_str = g_mod_types[p_rinfo->mod_type].str ;

	//Bits 24-23: HE type
	p_rinfo->he_type = (rate_n_flags & RATE_MCS_HE_TYPE_MSK) >> RATE_MCS_HE_TYPE_POS ;
	p_rinfo->he_type_str = g_he_types[p_rinfo->he_type].str ;

	//BIts 13-11: chan width
	uint32_t chan_width_type = (rate_n_flags & RATE_MCS_CHAN_WIDTH_MSK) >> RATE_MCS_CHAN_WIDTH_POS ;
	p_rinfo->chan_width = g_chan_widths[chan_width_type].num ;

	//Bits 15-14: antenna selection
	p_rinfo->ant_sel = (rate_n_flags & RATE_MCS_ANT_MSK) >> RATE_MCS_ANT_POS ; 

	//Bits 16: LDPC enables
	p_rinfo->ldpc = (rate_n_flags & RATE_MCS_LDPC_MSK) >> RATE_MCS_LDPC_POS ; 

	flqstdout("mod_type(%u,%s) he_type(%u,%s) chan_width_type(%u,%u) ant_sel(%u) ldpc(%u)\n",
			p_rinfo->mod_type, p_rinfo->mod_type_str, p_rinfo->he_type, p_rinfo->he_type_str, 
			chan_width_type, p_rinfo->chan_width, p_rinfo->ant_sel, p_rinfo->ldpc) ;
}


void handle_csi(uint8_t *csi_hdr, int csi_hdr_len, uint8_t *csi_data, int csi_data_len) 
{
	flqstdout("* %s\n", __func__) ;

	uint32_t n32 ;

	// save to file
	n32 = htonl(csi_hdr_len) ;
	fwrite(&n32, 1, 4, g_fp_csi) ;
	fwrite(csi_hdr, 1, csi_hdr_len, g_fp_csi) ;
		
	n32 = htonl(csi_data_len) ;
	fwrite(&n32, 1, 4, g_fp_csi) ;
	fwrite(csi_data, 1, csi_data_len, g_fp_csi) ;
	fflush(g_fp_csi) ;

	// decompose csi_hdr
	csi_hdr_t *pch = (p_csi_hdr_t)csi_hdr ;
	flqstdout("csi_len(%u) ftm(%u) nrx(%u) ntx(%u) ntone(%u)\n", 
			pch->csi_len, pch->ftm, pch->nrx, pch->ntx, pch->ntone) ;
	flqstdout("rssi1(%d) rssi2(%d) seq(%u) us(%u) rnf(0x%x)\n", 
			-pch->opp_rssi1, -pch->opp_rssi2, pch->seq, pch->us, pch->rate_n_flags) ;
	uint8_t *smac = pch->smac ;
	flqstdout("mac(%02x:%02x:%02x:%02x:%02x:%02x)\n", 
			smac[0], smac[1], smac[2], smac[3], smac[4], smac[5]) ;

	rate_info_t rinfo ;
	handle_rate_n_flags(pch->rate_n_flags, &rinfo) ;
	flqstdout("%s\n", rinfo.mod_type_str) ;

	output_hexs(csi_hdr, csi_hdr_len) ;
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
*/


