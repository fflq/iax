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

#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

#include <tx80211.h>
#include <tx80211_packet.h>

void usage()
{

	struct tx80211_cardlist *cardlist = NULL;
	int i;

	cardlist = tx80211_getcardlist();

	printf("tx (c) 2005 Joshua Wright and dragorn\n"
	       "Usage : tx [options]\n"
	       "  -i <interface>       specify the interface name\n"
	       "  -n <number>          number of packets to send\n"
	       "  -c <channel>         channel to transmit packets on.\n"
	       "  -s <sleep>           sleep time in usec between packets.\n"
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

	// WEP encrypted packet 
	unsigned char packet[108] = {
		0x08, 0x41, 0x0a, 0x00, 0x00, 0x03, 0x1b, 0xc2,
		0x45, 0x33, 0x00, 0x1b, 0x4b, 0x29, 0x61, 0xb1,
		0xff, 0x10, 0x07, 0x00, 0x12, 0x53, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3e, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00,
		0x00, 0x00, 0x75, 0x41, 0x37, 0x5a, 0x4b, 0xbc,
		0x55, 0x69, 0x07, 0x58, 0x4c, 0x03, 0xf4, 0xa7,
		0x69, 0xbc, 0xdf, 0x46, 0x27, 0x4d, 0xd0, 0xb6,
		0xcc, 0x7c, 0x8b, 0x8b, 0x46, 0x06, 0x30, 0x72,
		0x67, 0x72, 0x5d, 0x49, 0xe6, 0x0a, 0xfb, 0x74,
		0xef, 0x59, 0x1c, 0x24, 0x0b, 0x07, 0x60, 0xee,
		0x1b, 0x87, 0xf1, 0x6f, 0x3a, 0x88, 0x54, 0x25,
		0x5a, 0x90, 0xb4, 0x68
	};

//ACK frame
    /*
    unsigned char packet[10] = {
        0xd4, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x66, 0xe3,
        0x76, 0x3b};
    */

    // Beacon frame
    /*
    unsigned char packet[115] = {
        0x80, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // dur ffff
        0xff, 0xff, 0x00, 0x0f, 0x66, 0xe3, 0xe4, 0x03, 
        0x00, 0x0f, 0x66, 0xe3, 0xe4, 0x03, 0x00, 0x00, // 0x0000 - seq no.
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // BSS timestamp 
        0x64, 0x00, 0x11, 0x00, 0x00, 0x0f, 0x73, 0x6f, 
        0x6d, 0x65, 0x74, 0x68, 0x69, 0x6e, 0x67, 0x63, 
        0x6c, 0x65, 0x76, 0x65, 0x72, 0x01, 0x08, 0x82, 
        0x84, 0x8b, 0x96, 0x24, 0x30, 0x48, 0x6c, 0x03, 
        0x01, 0x01, 0x05, 0x04, 0x00, 0x01, 0x00, 0x00, 
        0x2a, 0x01, 0x05, 0x2f, 0x01, 0x05, 0x32, 0x04, 
        0x0c, 0x12, 0x18, 0x60, 0xdd, 0x05, 0x00, 0x10, 
        0x18, 0x01, 0x01, 0xdd, 0x16, 0x00, 0x50, 0xf2, 
        0x01, 0x01, 0x00, 0x00, 0x50, 0xf2, 0x02, 0x01, 
        0x00, 0x00, 0x50, 0xf2, 0x02, 0x01, 0x00, 0x00, 
        0x50, 0xf2, 0x02};
    */

    // small fragmented WEP packet
    /*
    unsigned char packet[] = {
        0x08, 0x45, 0xd5, 0x00, 0x00, 0x0f, 0x66, 0xe3, 
        0x76, 0x3b, 0x00, 0x02, 0x6f, 0x35, 0x73, 0x0f, 
        0x00, 0x0f, 0x66, 0xe3, 0xe4, 0x01, 0xa3, 0x4c, 
        0xa8, 0x34, 0x00, 0x00, 0xc4, 0x42, 0x86, 0x90, 
        0x4f, 0x76, 0xa5, 0x4d};
    */

/*
    char packet[] = {
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
*/

	struct tx80211 in_tx;
	struct tx80211_packet in_packet;
	int cnt = 1, delay = 0, ret = 0, c = 0, channel = 0, txcnt=0;
	int drivertype = INJ_NODRIVER;
	char iface[16 + 1];

	memset(iface, 0, sizeof(iface));
	memset(&in_tx, 0, sizeof(struct tx80211));

	while ((c = getopt(argc, argv, "n:i:d:c:s:")) != EOF) {
		switch (c) {
		case 's':
			if (sscanf(optarg, "%d", &delay) != 1) {
				fprintf(stderr, "%s: Illegal delay on cmd line"
					".\n", argv[0]);
				usage();
				return -1;
			}
			break;
		case 'n':
			if (sscanf(optarg, "%d", &cnt) != 1) {
				fprintf(stderr, "%s: Illegal count on cmd line",
					".\n", argv[0]);
				usage();
				return -1;
			}
			break;
		case 'i':
			strncpy(iface, optarg, sizeof(iface) - 1);
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

	if (drivertype == INJ_NODRIVER) {
		fprintf(stderr, "Driver name not recognized.\n");
		usage();
		return -1;
	}

	if (tx80211_init(&in_tx, iface, drivertype) < 0) {
		fprintf(stderr, "Error initializing interface: %s\n",
				tx80211_geterrstr(&in_tx));
		return 1;
	}

	/* Set monitor mode */
	ret = tx80211_setfunctionalmode(&in_tx, TX80211_FUNCMODE_INJECT);
	if (ret != 0) {
		fprintf(stderr, "Error setting mode: %s.\n",
				tx80211_geterrstr(&in_tx));
		return 1;
	}

	/* Switch to the given channel */
	if (channel > 0) {
		ret = tx80211_setchannel(&in_tx, channel);
		if (ret < 0) {
			fprintf(stderr, "Error setting channel, returned %d.\n",					ret);
			return 1;
		}
	}

	/* Open the interface to get a socket */
	ret = tx80211_open(&in_tx);
	if (ret < 0) {
		fprintf(stderr, "Unable to open interface %s.\n", in_tx.ifname);
		return 1;
	}

	/* Initialize the packet structure */
	tx80211_initpacket(&in_packet);

	/* Modulation and rate are per-packet parameters */
	if ((tx80211_getcapabilities(&in_tx) & 
			TX80211_CAP_SETMODULATION) != 0) {

		ret = tx80211_setmodulation(&in_tx, &in_packet,
				TX80211_MOD_DSSS);
		if (ret < 0) {
			fprintf(stderr, "Error setting modulation mechanism: "
					"%s\n", in_tx.errstr);
		}

	}

	if ((tx80211_getcapabilities(&in_tx) & TX80211_CAP_SETRATE) != 0) {
		ret = tx80211_settxrate(&in_tx, &in_packet, TX80211_RATE_2MB);
		if (ret < 0) {
			fprintf(stderr, "Error setting TX rate: "
					"%s\n", in_tx.errstr);
		}
	}

	in_packet.packet = packet;
	in_packet.plen = sizeof(packet);

	/* Send the packets */
	for (; cnt > 0; cnt--) {
		ret = tx80211_txpacket(&in_tx, &in_packet);
		if (ret < 0) {
			fprintf(stderr,
				"Unable to transmit packet: %s\n", 
				in_tx.errstr);
			return 1;
		}

		txcnt++;
		if (delay > 0) {
			usleep(delay);
		}
	}

	tx80211_close(&in_tx);
	printf("%d packets transmitted.\n", txcnt);
	return 0;
}
