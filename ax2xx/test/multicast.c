#include <netlink/netlink.h>
#include <netlink/socket.h>
#include <netlink/msg.h>


/*
 * This function will be called for each valid netlink message received
 * in nl_recvmsgs_default()
 */
static int my_func(struct nl_msg *msg, void *arg)
{
	printf("recvmsgs\n") ;
	return 0;
}


int main() 
{
	struct nl_sock *sk;

	/* Allocate a new socket */
	sk = nl_socket_alloc();

	/*
	 * Notifications do not use sequence numbers, disable sequence number * checking.
	*/
	nl_socket_disable_seq_check(sk);

	/*
	 * Define a callback function, which will be called for each notification * received
	*/
	nl_socket_modify_cb(sk, NL_CB_VALID, NL_CB_CUSTOM, my_func, NULL);

	/* Connect to routing netlink protocol */
	int protocol = NETLINK_ROUTE ;
	protocol = NETLINK_CONNECTOR ;
	protocol = NETLINK_KOBJECT_UEVENT ;
	protocol = NETLINK_GENERIC ;
	nl_connect(sk, protocol);

	/* Subscribe to link notifications group */
	//nl_socket_add_memberships(sk, RTNLGRP_LINK, 0);
	//nl_socket_add_memberships(sk, NL80211_MCGRP_VENDOR, 0);
	//nl_socket_add_memberships(sk, 4, 0);
	nl_socket_add_memberships(sk, 4, 0);

	/*
	 * Start receiving messages. The function nl_recvmsgs_default() will block
	 * until one or more netlink messages (notification) are received which
	 * will be passed on to my_func().
	*/

	while (1) {
		nl_recvmsgs_default(sk);
	}

}
