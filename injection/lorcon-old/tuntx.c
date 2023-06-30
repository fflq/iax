/*
    This file is part of lorcon

    lorcon is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    lorcon is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with lorcon; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Copyright (c) 2005 dragorn and Joshua Wright
*/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include <net/if_arp.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <arpa/inet.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <linux/if_tun.h>

// Because some kernels include ethtool which breaks horribly...
// // The stock ones don't but others seem to
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long u64;
#include <linux/types.h>
#include <linux/if.h>
#include <linux/wireless.h>

#include <errno.h>
#include <string.h>

#include <tx80211.h>
#include <tx80211_packet.h>

#include <pcap.h>

#define MAX_PACKET_LEN 8192

void usage()
{
	struct tx80211_cardlist *cardlist = NULL;
	int i;

	cardlist = tx80211_getcardlist();

	printf("txtun (c) 2005 Joshua Wright and dragorn\n"
	       "Usage : txtun [options]\n"
	       "  -i <interface>       specify the interface name\n"
		   "  -t <interface>       specify the tuntap interface name\n"
	       "  -c <channel>         channel to transmit packets on.\n"
	       "  -d <drivername>      string indicating driver used on interface\n");

	if (cardlist == NULL) {
		fprintf(stderr, "Error accessing supported cardlist.\n");
	} else {
		printf("\nSupported drivers are: ");
		for (i = 1; i < cardlist->num_cards; i++) {
			printf("%s ", cardlist->cardnames[i]);
		}
		printf("\n");
	}
}

int main(int argc, char *argv[])
{
	struct tx80211 in_tx;
	struct tx80211_packet in_packet;
	struct ifreq ifr;

	int ret = 0, channel = 0, c = 0, ttfd = -1, intfd = -1, flags = 0;

	int drivertype = INJ_NODRIVER;

	char iface[16 + 1];
	char tface[16 + 1];

	char errstr[PCAP_ERRBUF_SIZE + 1];

	pcap_t *pd;

	const u_char *pcap_pkt;
	struct pcap_pkthdr pcap_hdr;

	memset(iface, 0, sizeof(iface));
	memset(tface, 0, sizeof(tface));

	while ((c = getopt(argc, argv, "i:t:d:c:")) != EOF) {
		switch (c) {
		case 'i':
			strncpy(iface, optarg, sizeof(iface) - 1);
			break;
		case 't':
			strncpy(tface, optarg, sizeof(tface) - 1);
			break;
		case 'd':
			drivertype = tx80211_resolvecard(optarg);
			break;
		case 'c':
			if (sscanf(optarg, "%d", &channel) != 1) {
				fprintf(stderr,
					"%s: Illegal channel on cmd line",
					argv[0]);
				usage();
				return -1;
			}
			break;
		default:
			break;
		}
	}

	if (!strlen(iface)) {
		fprintf(stderr, "Must specify an interface name.\n");
		usage();
		return -1;
	}

	if (!strlen(tface)) {
		fprintf(stderr, "Must specify a tuntap interface name.\n");
		usage();
		return -1;
	}

	if (drivertype == INJ_NODRIVER) {
		fprintf(stderr, "Driver name not recognized.\n");
		usage();
		return -1;
	}

	if (tx80211_init(&in_tx, iface, drivertype) < 0) {
		perror("tx80211_init");
		return -1;
	}

	/* Create the tuntap device */
	if ((ttfd = open("/dev/net/tun", O_RDWR)) < 0) {
		perror("Could not open /dev/net/tun control file");
		return -1;
	}
	
	memset(&ifr, 0, sizeof(ifr));
	ifr.ifr_flags = (IFF_TAP | IFF_NO_PI);
	strncpy(ifr.ifr_name, tface, sizeof(tface) - 1);

	if (ioctl(ttfd, TUNSETIFF, (void *) &ifr) < 0) {
		perror("Unable to create tuntap interface");
		return -1;
	}

	/* bring the tuntap up */
	if ((intfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("Failed to create AF_INET socket");
		return -1;
	}

	memset(&ifr, 0, sizeof(ifr));
	strncpy(ifr.ifr_name, tface, IFNAMSIZ);
	if (ioctl(intfd, SIOCGIFFLAGS, &ifr) < 0) {
		perror("Failed to get interface flags for tuntap");
		return -1;
	}

	flags = ifr.ifr_flags;
	flags |= (IFF_UP | IFF_RUNNING | IFF_PROMISC);
	ifr.ifr_flags = flags;

	if (ioctl(intfd, SIOCSIFFLAGS, &ifr) < 0) {
		perror("Failed to set interface flags for tuntap");
		return -1;
	}

	close(intfd);

	/* Set monitor mode */
	ret = tx80211_setmode(&in_tx, IW_MODE_MONITOR);
	if (ret != 0) {
		fprintf(stderr, "Error setting mode, returned %d.\n", ret);
		return 1;
	}

	/* Switch to the given channel */
	ret = tx80211_setchannel(&in_tx, channel);
	if (ret < 0) {
		fprintf(stderr, "Error setting channel, returned %d.\n", ret);
		return 1;
	}

	/* Open the interface to get a socket */
	ret = tx80211_open(&in_tx);
	if (ret < 0) {
		fprintf(stderr, "Unable to open interface %s.\n", in_tx.ifname);
		return 1;
	}

	/* Open the pcap interface */
	pd = pcap_open_live(tface, MAX_PACKET_LEN, 1, 1000, errstr);
	if (pd == NULL) {
		perror("Failed to open tuntap with pcap");
		fprintf(stderr, "%s\n", errstr);
		return 1;
	}

	fprintf(stderr, "Linked %s to %s, waiting for packets...\n", tface, iface);
	
	while (1) {
		if ((pcap_pkt = pcap_next(pd, &pcap_hdr)) == NULL) {
			pcap_perror(pd, "Failed to get next packet from tuntap");
			break;
		}

		in_packet.packet = (u_char *) pcap_pkt;
		in_packet.plen = pcap_hdr.caplen;

		ret = tx80211_txpacket(&in_tx, &in_packet);
		if (ret < 0) {
			fprintf(stderr, "Unable to transmit packet, returned %d.\n", ret);
			perror("tx80211_txpacket");
			break;
		}
	}

	tx80211_close(&in_tx);
	return 0;
}
