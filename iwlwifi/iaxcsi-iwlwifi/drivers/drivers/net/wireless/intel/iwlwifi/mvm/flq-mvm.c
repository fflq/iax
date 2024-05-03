#include "flq-mvm.h"
#include "mvm.h"
#include "time-sync.h"

//called in mvm/debugfs.c
ssize_t iwl_dbgfs_monitor_tx_rate_read(struct file *file,
		char __user *user_buf, size_t count, loff_t *ppos)
{
	struct iwl_mvm *mvm = file->private_data;
	char buf[16];
	int len;

	len = scnprintf(buf, sizeof(buf), "0x%x", mvm->flq_res.monitor_tx_rate);
	flq_dbge("read %s", buf) ;

	return simple_read_from_buffer(user_buf, count, ppos, buf, len);
}

//called in mvm/debugfs.c
ssize_t iwl_dbgfs_monitor_tx_rate_write(struct iwl_mvm *mvm, 
		char *buf, size_t count, loff_t *ppos)
{
	u32 val;
	int ret;

	if (count > 16)
		return -EINVAL;

	ret = kstrtou32(buf, 0, &val);
	if (ret)
		return ret;

	mvm->flq_res.monitor_tx_rate = val;
	flq_dbge("write 0x%x", mvm->flq_res.monitor_tx_rate) ;

	return count;
}

//follow in mvm/debugfs.c, next in mvm/debugfs.h
//MVM_DEBUGFS_READ_WRITE_FILE_OPS(monitor_tx_rate, 32);
//_MVM_DEBUGFS_READ_WRITE_FILE_OPS(monitor_tx_rate, 32, struct iwl_mvm);

// because csi_hdr/chunk call by schedule_work(&mvm->async_handlers_wk);
// so call here asyncly, and flq_src_mac is not realtime and reorder.
// ef:be:ad:de:ad:de
//called in mvm/vendor-cmd.c/iwl_mvm_csi_complete
void flq_expand_csi_hdr(struct iwl_mvm *mvm, u_int8_t *csi_hdr)
{
	//u32 i, sum_from_208_to_240 = 0;
    struct flq_iwl_mvm_res *flq_res = &mvm->flq_res;
	struct iwl_rx_mpdu_desc_v3 *desc3 = &(flq_res->desc.v3); ;
	time64_t unix_ts;
	int pos = 208;

	u8 *mac, *flq_smac = flq_res->src_mac, *csi_smac = csi_hdr+68;
	u64 invalid_smac_tag = 0xdeaddeadbeef;
	u64 csi_smac_tag = *(u64*)csi_smac;
	//u64 flq_smac_tag = *(u64*)flq_smac;

	flqn_dbge_fl(10000);

	//if ((csi_smac[5] != 0xde) && (flq_smac[5] != csi_smac[5])) {
	if (csi_smac_tag == invalid_smac_tag) {
		mac = flq_smac;
		flqn_dbgi(10000, "flq_smac %02x:%02x:%02x:%02x:%02x:%02x\n", 
				mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
		mac = csi_smac;
		flqn_dbgi(10000, "flq_smac %02x:%02x:%02x:%02x:%02x:%02x\n", 
				mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
	}
	//memcpy(csi_smac, flq_smac, ETH_ALEN) ;

	//[208,240) is zeros
	/*
	for (i = 208; i < 240; i += 4) {
		sum_from_208_to_240 += *(u32*)(csi_hdr+i);
	}
	if (sum_from_208_to_240) {
		flq_dbgi("%s, csi_hdr[208,240) not zero %d\n", __func__, sum_from_208_to_240);
	}
	*/

	//1.timestamp
	//unix_ts = ktime_get_real_seconds();
	unix_ts = ktime_get_real_ns();
	memcpy(csi_hdr+pos, &unix_ts, sizeof(unix_ts)); 
	pos += sizeof(unix_ts);
	//2. channel
	*(csi_hdr+pos) = desc3->channel;
	pos += 1;

	/* all zeros
	struct iwl_rx_phy_info *phy_info = &mvm->last_phy_info;
	flq_dbgi("uts%llu, sts%llu, ts%llu, %d, %d\n", 
		unix_ts, phy_info->system_timestamp, phy_info->timestamp,   
		phy_info->cfg_phy_cnt, phy_info->non_cfg_phy_cnt);
	__le16 phy_flags;
	__le16 channel;
	__le32 non_cfg_phy[IWL_RX_INFO_PHY_CNT];
	__le32 rate_n_flags;
	//2.phy_flags
	memcpy(csi_hdr+pos, &(phy_info->phy_flags), sizeof(phy_info->phy_flags));
	pos += sizeof(phy_info->phy_flags);
	//3.channel
	memcpy(csi_hdr+pos, &(phy_info->channel), sizeof(phy_info->channel));
	pos += sizeof(phy_info->channel);
	//4.non_cfg_phy
	//int size = IWL_RX_INFO_PHY_CNT * sizeof(phy_info->non_cfg_phy[0]);
	//memcpy(csi_hdr+pos, (phy_info->non_cfg_phy), size);
	//pos += size;
	//rnf
	memcpy(csi_hdr+pos, &(phy_info->channel), sizeof(phy_info->channel));
	pos += sizeof(phy_info->channel);
	*/
}

//called in mvm/vendor-cmd.c/
void flq_send_test(struct iwl_mvm *mvm, void *hdr, unsigned int hdr_len)
{
	unsigned int data_len = 0;
	struct sk_buff *msg;
	struct nlattr *dattr;
	//u8 *pos;
	//int i;

//from mvm/vendor-cmd.c/enum
#define IWL_MVM_VENDOR_EVENT_IDX_CSI 0x1
	msg = cfg80211_vendor_event_alloc_ucast(mvm->hw->wiphy, NULL,
			0, 100 + hdr_len + data_len, IWL_MVM_VENDOR_EVENT_IDX_CSI, GFP_KERNEL);
#undef IWL_MVM_VENDOR_EVENT_IDX_CSI 

	if (!msg) return;

	if (nla_put(msg, IWL_MVM_VENDOR_ATTR_CSI_HDR, hdr_len, hdr))
		return;

	dattr = nla_reserve(msg, IWL_MVM_VENDOR_ATTR_CSI_DATA, data_len);
	if (!dattr) return;

	cfg80211_vendor_event(msg, GFP_KERNEL);
}

/* 
 * that consistent during csi-hdr/chunk, and csi'mac is invalid
[36800.967908] ***fflq flq_record_macs, cc:2d:21:d4:7:91
[36800.991893] ***fflq flq_record_macs, 20:82:1a:28:3:10
[36800.991960] ***fflq iwl_mvm_rx_csi_header, 0:0:fe:0:0:8
[36800.991972] ***fflq iwl_mvm_rx_csi_chunk, fb:ff:5a:ff:d6:ff
[36800.991982] ***fflq iwl_mvm_rx_csi_chunk, idx/num, 1/2
[36800.991990] ***fflq iwl_mvm_rx_csi_chunk, 37:0:b6:ff:20:0
[36800.991999] ***fflq iwl_mvm_rx_csi_chunk, idx/num, 2/2
[36800.995844] ***fflq flq_record_macs, 66:5c:8:cd:18:11
[36800.995892] ***fflq flq_record_macs, 60:2f:33:c:3:10
 * 
[37296.943687] ***fflq iwl_mvm_csi_complete, flq_mac 66:5c:8:cd:18:11
[37296.943699] ***fflq iwl_mvm_csi_complete, csi_hdr 66:5c:8:cd:18:11
[37297.060271] ***fflq iwl_mvm_csi_complete, flq_mac 20:82:1a:28:3:10
[37297.060284] ***fflq iwl_mvm_csi_complete, csi_hdr ef:be:ad:de:ad:de
[37297.201618] ***fflq iwl_mvm_csi_complete, flq_mac 66:5c:8:cd:18:11
[37297.201631] ***fflq iwl_mvm_csi_complete, csi_hdr ef:be:ad:de:ad:de
 */
//called in mvm/rxmq.c/iwl_mvm_rx_mpdu_mq
void flq_mvm_record(struct iwl_mvm *mvm, struct iwl_rx_cmd_buffer *rxb)
{
	struct iwl_rx_packet *pkt = rxb_addr(rxb);
	struct iwl_rx_mpdu_desc *desc = (void *)pkt->data;
	struct ieee80211_hdr *hdr;
    struct flq_iwl_mvm_res *flq_res = &mvm->flq_res;
	size_t desc_size;
	u8 *dst_mac, *src_mac; //fflq key, get mac
	//u8 *mac;

	if (mvm->trans->trans_cfg->device_family >= IWL_DEVICE_FAMILY_AX210)
		desc_size = sizeof(*desc);
	else
		desc_size = IWL_RX_DESC_SIZE_V1;

	hdr = (void *)(pkt->data + desc_size);
	dst_mac = hdr->addr1; 
	src_mac = hdr->addr2; 
	memcpy(flq_res->src_mac, src_mac, ETH_ALEN);
	memcpy(flq_res->dst_mac, dst_mac, ETH_ALEN);
	//flq_dbgi("%x:%x:%x:%x:%x:%x", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

	memcpy(&(flq_res->desc), desc, sizeof(*desc));
}

// fflq set custom monitor tx rate
// called in mvm/tx.c/iwl_mvm_tx_skb_non_sta
void flq_iwl_mvm_set_monitor_tx_rate(struct iwl_mvm *mvm, struct sk_buff *skb,
		      struct ieee80211_tx_info *info, struct iwl_device_tx_cmd *dev_cmd)
{
    struct flq_iwl_mvm_res *flq_res = &mvm->flq_res;

	if (info->control.vif->type != NL80211_IFTYPE_MONITOR || 
			!flq_res->monitor_tx_rate) 
		return ;

	flqn_dbge(10000, "rate_n_flags=monitor_tx_rate=%08x", flq_res->monitor_tx_rate) ;

	if (iwl_mvm_has_new_tx_api(mvm)) {
		if (mvm->trans->trans_cfg->device_family >= IWL_DEVICE_FAMILY_AX210) {
			struct iwl_tx_cmd_gen3 *tx_cmd = (void *)dev_cmd->payload;

			tx_cmd->flags |= IWL_TX_FLAGS_CMD_RATE;
			tx_cmd->rate_n_flags = cpu_to_le32(flq_res->monitor_tx_rate);
		} 
		else {
			struct iwl_tx_cmd_gen2 *tx_cmd = (void *)dev_cmd->payload;

			tx_cmd->flags |= IWL_TX_FLAGS_CMD_RATE;
			tx_cmd->rate_n_flags = cpu_to_le32(flq_res->monitor_tx_rate);
		}
	}
	else {
		struct iwl_tx_cmd *tx_cmd = (struct iwl_tx_cmd *)dev_cmd->payload;
		tx_cmd->tx_flags |= TX_CMD_FLG_STA_RATE ; //same as IWL_TX_FLAGS_CMD_RATE
		tx_cmd->rate_n_flags = cpu_to_le32(flq_res->monitor_tx_rate);
	}
}
