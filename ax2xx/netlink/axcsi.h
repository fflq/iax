#ifndef _AXCSI_H_
#define _AXCSI_H_


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
} __attribute__ ((packet)) ;
typedef struct csi_hdr_t csi_hdr_t, *p_csi_hdr_t ; 


//from include/netlink-private/types.h, origin struct nl_sock
struct flq_nl_sock
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
