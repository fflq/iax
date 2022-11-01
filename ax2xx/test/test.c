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



struct nl_cb *gcb = NULL ;
unsigned int gportid = 0;
int gr = 1 ;

void call_iwl_mvm_vendor_csi_register(struct nl_sock *sk, int family_id)
{
	int r ;
  	struct nl_msg* msg = nlmsg_alloc();
	int devidx = if_nametoindex("wlp8s0") ;
  
	//fflqkey, refer __cfg80211_alloc_vendor_skb
#define INTEL_OUI	0X001735
#define IWL_MVM_VENDOR_CMD_CSI_EVENT	0x24
  	//genlmsg_put(msg, NL_AUTO_PORT, NL_AUTO_SEQ, family_id, 0, NLM_F_DUMP, NL80211_CMD_GET_INTERFACE, 0);
  	void *hdr = genlmsg_put(msg, 0, NL_AUTO_SEQ, family_id, 0, NLM_F_MATCH, NL80211_CMD_VENDOR, 0);

	nla_put_u32(msg, NL80211_ATTR_IFINDEX, devidx) ;
	//or /sys/class/ieee80211/${phyname}/index
	//nla_put_u32(msg, NL80211_ATTR_WIPHY, 0) ;
  	nla_put_u32(msg, NL80211_ATTR_VENDOR_ID, INTEL_OUI); 
  	nla_put_u32(msg, NL80211_ATTR_VENDOR_SUBCMD, IWL_MVM_VENDOR_CMD_CSI_EVENT); 
	nla_put(msg, NL80211_ATTR_VENDOR_DATA, 0, NULL) ;

  	r = nl_send_auto(sk, msg);
	printf("send return %d\n", r) ;

	r = nl_recvmsgs_default(sk) ;
	//struct nl_cb *cb = nl_cb_alloc(NL_CB_DEFAULT);
	//r = nl_recvmsgs_report(sk, gcb); 
	printf("recv return %d\n", r) ;
}

static int valid_cb(struct nl_msg *msg, void *arg) 
{
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
	struct nlattr *tb_msg[NL80211_ATTR_MAX + 1];

	printf("* %s\n", __func__) ;
	nl_msg_dump(msg, stdout);
	//return NL_SKIP ;

	nla_parse(tb_msg, NL80211_ATTR_MAX,
			genlmsg_attrdata(gnlh, 0), genlmsg_attrlen(gnlh, 0), NULL);

#define IWL_MVM_VENDOR_ATTR_CSI_HDR		0x4d
#define IWL_MVM_VENDOR_ATTR_CSI_DATA	0x4e
	if (tb_msg[NL80211_ATTR_VENDOR_DATA]) {
		//strcpy(((Wifi*)arg)->ifname, nla_get_string(tb_msg[NL80211_ATTR_IFNAME]));
		printf("* %s, csi_hdr\n", __func__) ;
	}

	if (tb_msg[IWL_MVM_VENDOR_ATTR_CSI_HDR]) {
		//strcpy(((Wifi*)arg)->ifname, nla_get_string(tb_msg[NL80211_ATTR_IFNAME]));
		printf("* %s, csi_hdr\n", __func__) ;
	}

	if (tb_msg[IWL_MVM_VENDOR_ATTR_CSI_DATA]) {
		//((Wifi*)arg)->ifindex = nla_get_u32(tb_msg[NL80211_ATTR_IFINDEX]);
		printf("* %s, csi_data\n", __func__) ;
	}

	return NL_SKIP;
}



static int finish_cb(struct nl_msg *msg, void *arg) {
	int *r = arg;
  	*r = 0;
	gr = 0;
  	printf("* %s\n", __func__) ;
	nl_msg_dump(msg, stdout);
  	return NL_SKIP;
}


void recv_msg(struct nl_sock *sk)
{
	gr = 1 ;
	int r ;
	while (gr > 0) { 
		r = nl_recvmsgs(sk, gcb); 
		printf("* %s, %u nl_recvmsgs %d\n", __func__, gportid, r) ;
		if (r < 0)	break ;
	}
}


int main()
{
	struct nl_sock *sk = nl_socket_alloc() ;
	if (!sk) {
		perror("failed nl_socket_alloc\n") ;
		return -1 ;
	}

	if (genl_connect(sk)) {
		perror("failed genl_connect\n") ;
		return -1 ;
	}

	//nl_socket_add_memberships(sk, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0) ; 
	//nl_socket_add_memberships(sk, 13, 0) ; 

	int family_id = genl_ctrl_resolve(sk, "nl80211") ;
	//family_id = 34 ;
	//int family_id = genl_ctrl_resolve(sk, "iwl_tm_gnl") ;
	//int family_id = genl_ctrl_resolve(sk, "vendor") ;
	if (family_id < 0) {
		perror("failed genl_ctrl_resolve\n") ;
		return -1 ;
	}

	gcb = nl_cb_alloc(NL_CB_DEFAULT);
  	nl_cb_set(gcb, NL_CB_VALID , NL_CB_CUSTOM, valid_cb, NULL);
  	nl_cb_set(gcb, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &gr);

	struct flq_nl_sock *flqsk = sk ;
	printf("* (nl_family,nl_pid,nl_groups), s_local(%u,%u,%u), s_peer(%u,%u,%u)\n", 
			flqsk->s_local.nl_family, flqsk->s_local.nl_pid, flqsk->s_local.nl_groups,
			flqsk->s_peer.nl_family, flqsk->s_peer.nl_pid, flqsk->s_peer.nl_groups) ;
	gportid = flqsk->s_local.nl_pid ;
	getchar() ;

 	call_iwl_mvm_vendor_csi_register(sk, family_id) ;

	int n = 1 ;
	while (1) {
		printf("\nget_nl_msg, family_id%d n%d\n", family_id, n) ;
	 	recv_msg(sk) ;
		sleep(1) ;
		//nl_socket_add_memberships(sk, n, 0) ;
		++ n ;
	}

	return 0 ;
}





