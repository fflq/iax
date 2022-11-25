#include <netlink/netlink.h>
#include <netlink/socket.h>
#include <netlink/msg.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/family.h>
#include <netlink/genl/ctrl.h>  
#include <linux/nl80211.h>      
#include <net/if.h>
#include <unistd.h>


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
	printf("%s, send return %d\n", __func__, r) ;

	r = nl_recvmsgs_default(sk) ;
	//struct nl_cb *cb = nl_cb_alloc(NL_CB_DEFAULT);
	//r = nl_recvmsgs_report(sk, gcb); 
	printf("%s, recv return %d\n", __func__, r) ;
}


void output_tb_msg(struct nlattr **tb_msg)
{	
	int i = 0;
	for (i = 0; i < NL80211_ATTR_MAX; ++ i)
	{
		if (tb_msg[i])
			printf("-- tb_msg[%x]: len %d, type %x\n", i, tb_msg[i]->nla_len, tb_msg[i]->nla_type) ;
	}
}


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

	printf("* %s, csi_hdr(%02x%02x), csidata(%02x%02x)\n", 
			__func__, *csi_hdr, *(csi_hdr+1), *csi_data, *(csi_data+1)) ;

	uint8_t *mac = csi_hdr+68 ;
	printf("-- mac(%02x:%02x:%02x:%02x:%02x:%02x)\n", 
			mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]) ;
}


static int valid_cb(struct nl_msg *msg, void *arg) 
{
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
	struct nlattr *tb_msg[NL80211_ATTR_MAX + 1];
	struct nlattr *msg_vendor_data, *nmsg_csi_hdr = NULL, *nmsg_csi_data = NULL ;
	struct nlattr *nested_tb_msg[NL80211_ATTR_MAX + 1];

	//printf("* %s\n", __func__) ;
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
		printf("* %s, tb_msg[%x] is vendor_data\n", __func__, NL80211_ATTR_VENDOR_DATA) ;
		nla_parse_nested(nested_tb_msg, NL80211_ATTR_MAX, msg_vendor_data, NULL) ;
		output_tb_msg(nested_tb_msg) ;

		nmsg_csi_hdr = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_HDR] ;
	 	nmsg_csi_data = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_DATA] ;
		if (nmsg_csi_hdr && nmsg_csi_data) {
			printf("** %s, (nla_type,nla_len) csi_hdr(%x,%u) csi_data(%x,%u)\n", __func__, 
					nmsg_csi_hdr->nla_type, nmsg_csi_hdr->nla_len,
					nmsg_csi_data->nla_type, nmsg_csi_data->nla_len) ;

			uint16_t csi_hdr_len = nmsg_csi_hdr->nla_len - 4 ;
			uint8_t *csi_hdr = nla_get_string(nmsg_csi_hdr) ;
						
			uint16_t csi_data_len = nmsg_csi_data->nla_len - 4 ;
			uint8_t *csi_data = nla_get_string(nmsg_csi_data) ;

			if ((csi_hdr_len != 272) || !csi_hdr || !csi_data) {
				printf("** %s, csi_hdr_len(%d)!=272 or !csi_hdr or !csi_data\n", __func__, csi_hdr_len) ;
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
  	printf("* %s -------\n", __func__) ;
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

	printf("\n\n") ;
	while (!finished) { 
		//r = nl_recvmsgs(sk, cb); 
		//r = nl_recvmsgs_report(sk, gcb) ;
		r = nl_recvmsgs_default(sk) ;
		printf("* %s %d, %u nl_recvmsgs %d\n\n", __func__, ++n, gportid, r) ;
		if (r < 0)	break ;
	}
}


void handle_args(int argc, char **argv)
{
	if (argc < 3) {
		printf("Usage: sudo %s wlan file\n- wlan: eg wlp8s0\n- file: eg ./a.csi\n"
				"* eg: sudo %s wlp8s0 ./a.csi\n", argv[0], argv[0]) ;
		exit(EXIT_FAILURE) ;
	}
	else {
 		gdevidx = if_nametoindex(argv[1]) ;
		g_fp_csi = fopen(argv[2], "w") ;
		if (!gdevidx || !g_fp_csi) {
			printf("* args err\n") ;
			exit(EXIT_FAILURE) ;
		}
		printf("* %s, %s/%d %s\n", __func__, argv[1], gdevidx, argv[2]) ;
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
	printf("* (nl_family,nl_pid,nl_groups), s_local(%u,%u,%u), s_peer(%u,%u,%u)\n", 
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





