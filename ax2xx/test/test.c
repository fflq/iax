#include <netlink/netlink.h>
#include <netlink/socket.h>
#include <netlink/msg.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/family.h>
#include <netlink/genl/ctrl.h>  
#include <linux/nl80211.h>      
#include <unistd.h>

struct nl_cb *gcb = NULL ;
int r = 0 ;

void get_nl_msg(struct nl_sock *sk, int id)
{
	r = 1 ;
  	struct nl_msg* msg = nlmsg_alloc();
  
  	genlmsg_put(msg, NL_AUTO_PORT, NL_AUTO_SEQ, id, 0,
              NLM_F_DUMP, NL80211_CMD_GET_INTERFACE, 0);
  	//nl_send_auto(sk, msg);
  	//while (nl->result1 > 0) { nl_recvmsgs(nl->socket, nl->cb1); }
  
	//nl_recvmsgs(sk, gcb) ;
  	while (r > 0) { 
		printf("wait nl_recvmsgs\n") ;
		nl_recvmsgs(sk, gcb); 
	}
}

static int valid_cb(struct nl_msg *msg, void *arg) 
{
  struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
  struct nlattr *tb_msg[NL80211_ATTR_MAX + 1];

  nl_msg_dump(msg, stdout);
  return NL_SKIP ;

  nla_parse(tb_msg,
            NL80211_ATTR_MAX,
            genlmsg_attrdata(gnlh, 0),
            genlmsg_attrlen(gnlh, 0),
            NULL);

  if (tb_msg[NL80211_ATTR_IFNAME]) {
    //strcpy(((Wifi*)arg)->ifname, nla_get_string(tb_msg[NL80211_ATTR_IFNAME]));
  }

  if (tb_msg[NL80211_ATTR_IFINDEX]) {
    //((Wifi*)arg)->ifindex = nla_get_u32(tb_msg[NL80211_ATTR_IFINDEX]);
  }

  return NL_SKIP;
}



static int finish_cb(struct nl_msg *msg, void *arg) {
  int *ret = arg;
  *ret = 0;
  return NL_SKIP;
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

	nl_socket_add_memberships(sk, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 0);

	int id = genl_ctrl_resolve(sk, "nl80211") ;
	if (id < 0) {
		perror("failed genl_ctrl_resolve\n") ;
		return -1 ;
	}

	gcb = nl_cb_alloc(NL_CB_DEFAULT);
  	nl_cb_set(gcb, NL_CB_VALID , NL_CB_CUSTOM, valid_cb, NULL);
  	nl_cb_set(gcb, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &r);

	while (1) {
		printf("get_nl_msg\n") ;
		get_nl_msg(sk, id) ;
		sleep(1) ;
	}

	return 0 ;
}





