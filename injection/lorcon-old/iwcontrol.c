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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef HAVE_LINUX_WIRELESS

#include <math.h>

#include "iwcontrol.h"
#include "tx80211.h"

#ifndef rintf
#define rintf(x) (float) rint((double) (x))
#endif

float iwfreq2float(struct iwreq *inreq)
{
	return ((float)inreq->u.freq.m) * pow(10, inreq->u.freq.e);
}

void iwfloat2freq(double in_val, struct iw_freq *out_freq)
{
	out_freq->e = (short)(floor(log10(in_val)));
	if (out_freq->e > 8) {
		out_freq->m =
		    ((long)(floor(in_val / pow(10, out_freq->e - 6)))) * 100;
		out_freq->e -= 8;
	} else {
		out_freq->m = (uint32_t) in_val;
		out_freq->e = 0;
	}
}

int floatchan2int(float in_chan)
{
	int mod_chan = (int)rintf(in_chan / 1000000);
	int x = 0;
	/* 80211b frequencies to channels */
	int IEEE80211Freq[] = {
		2412, 2417, 2422, 2427, 2432,
		2437, 2442, 2447, 2452, 2457,
		2462, 2467, 2472, 2484,
		5180, 5200, 5210, 5220, 5240,
		5250, 5260, 5280, 5290, 5300,
		5320, 5745, 5760, 5765, 5785,
		5800, 5805, 5825,
		-1
	};

	int IEEE80211Ch[] = {
		1, 2, 3, 4, 5,
		6, 7, 8, 9, 10,
		11, 12, 13, 14,
		36, 40, 42, 44, 48,
		50, 52, 56, 58, 60,
		64, 149, 152, 153, 157,
		160, 161, 165
	};

	while (IEEE80211Freq[x] != -1) {
		if (IEEE80211Freq[x] == mod_chan) {
			return IEEE80211Ch[x];
		}
		x++;
	}

	return 0;
}

int iwconfig_set_ssid(const char *in_dev, char *errstr, char *in_essid)
{
	struct iwreq wrq;
	int skfd;
	char essid[IW_ESSID_MAX_SIZE + 1];

	if (in_essid == NULL) {
		essid[0] = '\0';
	} else {
		/* Trim transparently */
		snprintf(essid, IW_ESSID_MAX_SIZE + 1, "%s", in_essid);
	}

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to create ioctl socket to set SSID on %s: %s",
			 in_dev, strerror(errno));
		return -1;
	}

	/* Zero the ssid */
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);
	wrq.u.essid.pointer = (caddr_t) essid;
	wrq.u.essid.length = strlen(essid) + 1;
	wrq.u.essid.flags = 1;

	if (ioctl(skfd, SIOCSIWESSID, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to set SSID on %s: %s", in_dev,
			 strerror(errno));
		close(skfd);
		return -1;
	}

	close(skfd);
	return 0;
}

int iwconfig_get_ssid(const char *in_dev, char *errstr, char *in_essid)
{
	struct iwreq wrq;
	int skfd;
	char essid[IW_ESSID_MAX_SIZE + 1];

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to create socket to fetch SSID on %s: %s",
			 in_dev, strerror(errno));
		return -1;
	}

	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);
	wrq.u.essid.pointer = (caddr_t) essid;
	wrq.u.essid.length = IW_ESSID_MAX_SIZE + 1;
	wrq.u.essid.flags = 0;

	if (ioctl(skfd, SIOCGIWESSID, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to fetch SSID from %s: %s", in_dev,
			 strerror(errno));
		close(skfd);
		return -1;
	}

	snprintf(in_essid, min(IW_ESSID_MAX_SIZE, wrq.u.essid.length) + 1, "%s",
		 (char *)wrq.u.essid.pointer);

	close(skfd);
	return 0;
}

int iwconfig_get_name(const char *in_dev, char *errstr, char *in_name)
{
	struct iwreq wrq;
	int skfd;

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to create socket to get name on %s: %s",
			 in_dev, strerror(errno));
		return -1;
	}

	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	if (ioctl(skfd, SIOCGIWNAME, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to get name on %s :%s", in_dev,
			 strerror(errno));
		close(skfd);
		return -1;
	}

	snprintf(in_name, IFNAMSIZ, "%s", wrq.u.name);

	close(skfd);
	return 0;
}

/* 
 * Set a private ioctl that takes 1 or 2 integer parameters
 * A return of -2 means no privctl found that matches, so that the caller
 * can return a more detailed failure message
 * Code largely taken from wireless_tools
 */
int iwconfig_set_intpriv(const char *in_dev, const char *privcmd,
			 int val1, int val2, char *errstr)
{
	struct iwreq wrq;
	int skfd;
	struct iw_priv_args priv[IW_MAX_PRIV_DEF];
	u_char buffer[4096];
	int subcmd = 0;
	int offset = 0;

	memset(priv, 0, sizeof(priv));

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to create socket to set private ioctl "
			 "on %s: %s", in_dev, strerror(errno));
		return -1;
	}

	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	wrq.u.data.pointer = (caddr_t) priv;
	wrq.u.data.length = IW_MAX_PRIV_DEF;
	wrq.u.data.flags = 0;

	if (ioctl(skfd, SIOCGIWPRIV, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to retrieve list of private ioctls on %s: %s",
			 in_dev, strerror(errno));
		close(skfd);
		return -1;
	}

	int pn = -1;
	while ((++pn < wrq.u.data.length) && strcmp(priv[pn].name, privcmd)) ;

	if (pn == wrq.u.data.length) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Unable to find private ioctl '%s' on %s", 
			 privcmd, in_dev);
		close(skfd);
		return -2;
	}

	/* Find subcmds, as if this isn't ugly enough already */
	if (priv[pn].cmd < SIOCDEVPRIVATE) {
		int j = -1;

		while ((++j < wrq.u.data.length)
		       && ((priv[j].name[0] != '\0')
			   || (priv[j].set_args != priv[pn].set_args)
			   || (priv[j].get_args != priv[pn].get_args))) ;

		if (j == wrq.u.data.length) {
			snprintf(errstr, TX80211_STATUS_MAX,
				 "Unable to find subioctl '%s' on %s", 
				 privcmd, in_dev);
			close(skfd);
			return -2;
		}

		subcmd = priv[pn].cmd;
		offset = sizeof(uint32_t);
		pn = j;
	}

	/* Make sure its an iwpriv we can set */
	if ((priv[pn].set_args & IW_PRIV_TYPE_MASK) == 0 ||
	    (priv[pn].set_args & IW_PRIV_SIZE_MASK) == 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Unable to set values for private ioctl '%s' on %s",
			 privcmd, in_dev);
		close(skfd);
		return -1;
	}

	if ((priv[pn].set_args & IW_PRIV_TYPE_MASK) != IW_PRIV_TYPE_INT) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "'%s' on %s does not accept integer parameters.",
			 privcmd, in_dev);
		close(skfd);
		return -1;
	}

	/* Find out how many arguments it takes and die if we can't handle it */
	int nargs = (priv[pn].set_args & IW_PRIV_SIZE_MASK);
	if (nargs > 2) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Private ioctl '%s' on %s expects more than "
			 "2 arguments.", privcmd, in_dev);
		close(skfd);
		return -1;
	}

	/* Build the set request */
	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	/* Assign the arguments */
	wrq.u.data.length = nargs;
	((__s32 *) buffer)[0] = (__s32) val1;
	if (nargs > 1) {
		((__s32 *) buffer)[1] = (__s32) val2;
	}

	/* This is terrible! 
	 * This is also simplified from what iwpriv.c does, because we don't
	 * need to worry about get-no-set ioctls
	 */
	if ((priv[pn].set_args & IW_PRIV_SIZE_FIXED) &&
	    ((sizeof(uint32_t) * nargs) + offset <= IFNAMSIZ)) {
		if (offset)
			wrq.u.mode = subcmd;
		memcpy(wrq.u.name + offset, buffer, IFNAMSIZ - offset);
	} else {
		wrq.u.data.pointer = (caddr_t) buffer;
		wrq.u.data.flags = 0;
	}

	/* Actually do it. */
	if (ioctl(skfd, priv[pn].cmd, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to set private ioctl '%s' on %s: %s", privcmd,
			 in_dev, strerror(errno));
		close(skfd);
		return -1;
	}

	close(skfd);
	return 0;
}

int iwconfig_get_intpriv(const char *in_dev, const char *privcmd,
			 int *val, char *errstr)
{
	struct iwreq wrq;
	int skfd;
	struct iw_priv_args priv[IW_MAX_PRIV_DEF];
	u_char buffer[4096];
	int subcmd = 0;
	int offset = 0;

	memset(priv, 0, sizeof(priv));

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to create socket to fetch private ioctl "
			 "on %s: %s", in_dev, strerror(errno));
		return -1;
	}

	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	wrq.u.data.pointer = (caddr_t) priv;
	wrq.u.data.length = IW_MAX_PRIV_DEF;
	wrq.u.data.flags = 0;

	if (ioctl(skfd, SIOCGIWPRIV, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to retrieve list of private ioctls on %s: %s",
			 in_dev, strerror(errno));
		close(skfd);
		return -1;
	}

	int pn = -1;
	while ((++pn < wrq.u.data.length) && strcmp(priv[pn].name, privcmd)) ;

	if (pn == wrq.u.data.length) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Unable to find private ioctl '%s' on %s", privcmd,
			 in_dev);
		close(skfd);
		return -2;
	}

	/* Find subcmds, as if this isn't ugly enough already */
	if (priv[pn].cmd < SIOCDEVPRIVATE) {
		int j = -1;

		while ((++j < wrq.u.data.length)
		       && ((priv[j].name[0] != '\0')
			   || (priv[j].set_args != priv[pn].set_args)
			   || (priv[j].get_args != priv[pn].get_args))) ;

		if (j == wrq.u.data.length) {
			snprintf(errstr, TX80211_STATUS_MAX,
				 "Unable to find subioctl '%s' on %s", privcmd,
				 in_dev);
			close(skfd);
			return -2;
		}

		subcmd = priv[pn].cmd;
		offset = sizeof(uint32_t);
		pn = j;
	}

	/* Make sure its an iwpriv we can set */
	if ((priv[pn].get_args & IW_PRIV_TYPE_MASK) == 0 ||
	    (priv[pn].get_args & IW_PRIV_SIZE_MASK) == 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Unable to get values for private ioctl '%s' on %s",
			 privcmd, in_dev);
		close(skfd);
		return -1;
	}

	if ((priv[pn].get_args & IW_PRIV_TYPE_MASK) != IW_PRIV_TYPE_INT) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Private ioctl '%s' on %s does not return "
			 "integer parameters.", privcmd, in_dev);
		close(skfd);
		return -1;
	}

	/* Find out how many arguments it takes and die if we can't handle it */
	int nargs = (priv[pn].get_args & IW_PRIV_SIZE_MASK);
	if (nargs > 1) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Private ioctl '%s' on %s returns more than 1 "
			 "parameter and we can't handle that at the moment.",
			 privcmd, in_dev);
		close(skfd);
		return -1;
	}

	/* Build the get request */
	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	/* Assign the arguments */
	wrq.u.data.length = 0L;

	/* This is terrible! 
	 * Simplified (again) from iwpriv, since we split the command into
	 * a set and a get instead of combining the cases
	 */
	if ((priv[pn].get_args & IW_PRIV_SIZE_FIXED) &&
	    ((sizeof(uint32_t) * nargs) + offset <= IFNAMSIZ)) {
		/* Second case : no SET args, GET args fit within wrq */
		if (offset)
			wrq.u.mode = subcmd;
	} else {
		wrq.u.data.pointer = (caddr_t) buffer;
		wrq.u.data.flags = 0;
	}

	/* Actually do it. */
	if (ioctl(skfd, priv[pn].cmd, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to call get private ioctl '%s' on %s: %s",
			 privcmd, in_dev, strerror(errno));
		close(skfd);
		return -1;
	}

	/* Where do we get the data from? */
	if ((priv[pn].get_args & IW_PRIV_SIZE_FIXED) &&
	    ((sizeof(uint32_t) * nargs) + offset <= IFNAMSIZ))
		memcpy(buffer, wrq.u.name, IFNAMSIZ);

	/* Return the value of the ioctl */
	(*val) = ((__s32 *) buffer)[0];

	close(skfd);
	return 0;
}

/* 
 * Set a character-based private ioctl
 */
int iwconfig_set_charpriv(const char *in_dev, const char *privcmd,
			 char *val, char *errstr)
{
	struct iwreq wrq;
	int skfd;
	struct iw_priv_args priv[IW_MAX_PRIV_DEF];
	int subcmd = 0;
	int offset = 0;

	memset(priv, 0, sizeof(priv));

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to create socket to set private ioctl "
			 "on %s: %s", in_dev, strerror(errno));
		return -1;
	}

	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	wrq.u.data.pointer = (caddr_t) priv;
	wrq.u.data.length = IW_MAX_PRIV_DEF;
	wrq.u.data.flags = 0;

	if (ioctl(skfd, SIOCGIWPRIV, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to retrieve list of private ioctls on %s: %s",
			 in_dev, strerror(errno));
		close(skfd);
		return -1;
	}

	int pn = -1;
	while ((++pn < wrq.u.data.length) && strcmp(priv[pn].name, privcmd)) ;

	if (pn == wrq.u.data.length) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Unable to find private ioctl '%s' on %s", 
			 privcmd, in_dev);
		close(skfd);
		return -2;
	}

	/* Find subcmds, as if this isn't ugly enough already */
	if (priv[pn].cmd < SIOCDEVPRIVATE) {
		int j = -1;

		while ((++j < wrq.u.data.length)
		       && ((priv[j].name[0] != '\0')
			   || (priv[j].set_args != priv[pn].set_args)
			   || (priv[j].get_args != priv[pn].get_args))) ;

		if (j == wrq.u.data.length) {
			snprintf(errstr, TX80211_STATUS_MAX,
				 "Unable to find subioctl '%s' on %s", 
				 privcmd, in_dev);
			close(skfd);
			return -2;
		}

		subcmd = priv[pn].cmd;
		offset = sizeof(uint32_t);
		pn = j;
	}

	/* Make sure its an iwpriv we can set */
	if ((priv[pn].set_args & IW_PRIV_TYPE_MASK) == 0 ||
	    (priv[pn].set_args & IW_PRIV_SIZE_MASK) == 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Unable to set values for private ioctl '%s' on %s",
			 privcmd, in_dev);
		close(skfd);
		return -1;
	}

	if ((priv[pn].set_args & IW_PRIV_TYPE_MASK) != IW_PRIV_TYPE_CHAR) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "'%s' on %s does not accept char parameters.",
			 privcmd, in_dev);
		close(skfd);
		return -1;
	}

	/* Find out how many arguments it takes and die if we can't handle it */
#if 0
	int nargs = (priv[pn].set_args & IW_PRIV_SIZE_MASK);
	if (nargs > 1) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Private ioctl '%s' on %s expects more than 1 arguments.", privcmd, in_dev);
		close(skfd);
		return -1;
	}
#endif

	/* Build the set request */
	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	/* Assign the arguments */
	wrq.u.data.length = strlen(val) + 1;

	/* This is terrible! 
	 * This is also simplified from what iwpriv.c does, because we don't
	 * need to worry about get-no-set ioctls
	 */
	if ((priv[pn].set_args & IW_PRIV_SIZE_FIXED) &&
	    ((sizeof(char) * strlen(val) + 1) + offset <= IFNAMSIZ)) {
		if (offset)
			wrq.u.mode = subcmd;
		memcpy(wrq.u.name + offset, val, IFNAMSIZ - offset);
	} else {
		wrq.u.data.pointer = (caddr_t) val;
		wrq.u.data.flags = 0;
	}

	/* Actually do it. */
	if (ioctl(skfd, priv[pn].cmd, &wrq) < 0) {
		snprintf(errstr, TX80211_STATUS_MAX,
			 "Failed to set private ioctl '%s' on %s: %s", privcmd,
			 in_dev, strerror(errno));
		close(skfd);
		return -1;
	}

	close(skfd);
	return 0;
}

int iwconfig_get_levels(const char *in_dev, char *in_err, int *level,
			int *noise)
{
	struct iwreq wrq;
	struct iw_range range;
	struct iw_statistics stats;
	char buffer[sizeof(struct iw_range) * 2];
	int skfd;

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to create AF_INET DGRAM socket %d:%s", errno,
			 strerror(errno));
		return -1;
	}

	/* Fetch the range */
	memset(buffer, 0, sizeof(struct iw_range) * 2);
	memset(&wrq, 0, sizeof(struct iwreq));
	wrq.u.data.pointer = (caddr_t) buffer;
	wrq.u.data.length = sizeof(buffer);
	wrq.u.data.flags = 0;
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	if (ioctl(skfd, SIOCGIWRANGE, &wrq) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to fetch signal range, %s", strerror(errno));
		close(skfd);
		return -1;
	}

	/* Pull it out */
	memcpy((char *)&range, buffer, sizeof(struct iw_range));

	/* Fetch the stats */
	wrq.u.data.pointer = (caddr_t) & stats;
	wrq.u.data.length = 0;
	wrq.u.data.flags = 1;	/* Clear updated flag */
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	if (ioctl(skfd, SIOCGIWSTATS, &wrq) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to fetch signal stats, %s", strerror(errno));
		close(skfd);
		return -1;
	}

	/*
	   if (stats.qual.level <= range.max_qual.level) {
	   *level = 0;
	   *noise = 0;
	   close(skfd);
	   return 0;
	   }
	 */

	*level = stats.qual.level - 0x100;
	*noise = stats.qual.noise - 0x100;

	close(skfd);

	return 0;
}

int iwconfig_get_channel(const char *in_dev, char *in_err)
{
	struct iwreq wrq;
	int skfd;

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to create AF_INET DGRAM socket %d:%s", errno,
			 strerror(errno));
		return -1;
	}

	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	if (ioctl(skfd, SIOCGIWFREQ, &wrq) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "channel get ioctl failed %d:%s", errno,
			 strerror(errno));
		close(skfd);
		return -1;
	}

	close(skfd);
	return (floatchan2int(iwfreq2float(&wrq)));
}

int iwconfig_set_channel(const char *in_dev, char *in_err, int in_ch)
{
	struct iwreq wrq;
	int skfd;

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to create AF_INET DGRAM socket %d:%s", errno,
			 strerror(errno));
		return -1;
	}
	/* Set a channel */
	memset(&wrq, 0, sizeof(struct iwreq));

	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);
#ifdef IW_FREQ_FIXED
	wrq.u.freq.flags = IW_FREQ_FIXED;
#endif
	/* Treat channels > 1024 as frequencies in mhz not channels and 
	 * multiply by the mhz constant accordingly */
	if (in_ch > 1024) 
		iwfloat2freq(in_ch * 1e6, &wrq.u.freq);
	else
		iwfloat2freq(in_ch, &wrq.u.freq);

	/* Try twice with a tiny delay, some cards (madwifi) need a second
       	   chance... */
	if (ioctl(skfd, SIOCSIWFREQ, &wrq) < 0) {
		struct timeval tm;
		tm.tv_sec = 0;
		tm.tv_usec = 5000;
		select(0, NULL, NULL, NULL, &tm);

		if (ioctl(skfd, SIOCSIWFREQ, &wrq) < 0) {
			snprintf(in_err, TX80211_STATUS_MAX,
				 "Failed to set channel %d %d:%s", in_ch, errno,
				 strerror(errno));
			close(skfd);
			return -1;
		}
	}

	close(skfd);
	return 0;
}

int iwconfig_get_mode(const char *in_dev, char *in_err)
{
	struct iwreq wrq;
	int skfd;

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to create AF_INET DGRAM socket %d:%s", errno,
			 strerror(errno));
		return -1;
	}

	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	if (ioctl(skfd, SIOCGIWMODE, &wrq) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "mode get ioctl failed %d:%s", errno, strerror(errno));
		close(skfd);
		return -1;
	}

	close(skfd);

	return (wrq.u.mode);
}

int iwconfig_set_mode(const char *in_dev, char *in_err, int tx80211_mode)
{
	struct iwreq wrq;
	int skfd;

	if ((skfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "Failed to create AF_INET DGRAM socket %d:%s", errno,
			 strerror(errno));
		return -1;
	}

	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, in_dev, IFNAMSIZ);

	/* LORCON modes align with Linux wireless tools modes */
	wrq.u.mode = tx80211_mode;

	if (ioctl(skfd, SIOCSIWMODE, &wrq) < 0) {
		snprintf(in_err, TX80211_STATUS_MAX,
			 "mode set ioctl failed %d:%s", errno, strerror(errno));
		close(skfd);
		return -1;
	}

	close(skfd);
	return 0;
}

#endif
