#ifndef _IWL_FLQ_MVM_H_
#define _IWL_FLQ_MVM_H_

#include <linux/flq-dbg.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/etherdevice.h>
#include <linux/timekeeping.h>
#include <net/netlink.h>
#include <net/mac80211.h>

//#include "mvm.h"
//#include "time-sync.h"
#include "fw-api.h"
#include "iwl-trans.h"
#include "fw/api/datapath.h"
#include "iwl-vendor-cmd.h"
#include "iwl-io.h"
#include "iwl-prph.h"
#include "debugfs.h"

struct iwl_mvm;

struct flq_iwl_mvm_res {
	u32 monitor_tx_rate ;
	u8 src_mac[ETH_ALEN], dst_mac[ETH_ALEN] ;
	struct iwl_rx_mpdu_desc desc ;
};

//called in mvm/debugfs.c
ssize_t iwl_dbgfs_monitor_tx_rate_read(struct file *file,
		char __user *user_buf, size_t count, loff_t *ppos) ;

//called in mvm/debugfs.c
ssize_t iwl_dbgfs_monitor_tx_rate_write(struct iwl_mvm *mvm, 
		char *buf, size_t count, loff_t *ppos) ;

//follow in mvm/debugfs.c, next in mvm/debugfs.h
//MVM_DEBUGFS_READ_WRITE_FILE_OPS(monitor_tx_rate, 32);
_MVM_DEBUGFS_READ_WRITE_FILE_OPS(monitor_tx_rate, 32, struct iwl_mvm);

//called in mvm/vendor-cmd.c/iwl_mvm_csi_complete
void flq_expand_csi_hdr(struct iwl_mvm *mvm, u_int8_t *csi_hdr) ;

//called in mvm/vendor-cmd.c/
void flq_send_test(struct iwl_mvm *mvm, void *hdr, unsigned int hdr_len) ;

//called in mvm/rxmq.c/iwl_mvm_rx_mpdu_mq
void flq_mvm_record(struct iwl_mvm *mvm, struct iwl_rx_cmd_buffer *rxb) ;

void flq_iwl_mvm_set_monitor_tx_rate(struct iwl_mvm *mvm, struct sk_buff *skb,
	    struct ieee80211_tx_info *info, struct iwl_device_tx_cmd *dev_cmd) ;

#endif
