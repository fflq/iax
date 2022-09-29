

//mvm/ops.c
module_Init(iwl_mvm_init) ;
iwl_mvm_init() {
	iwl_mvm_rate_control_register();
	iwl_opmode_register("iwlmvm", &iwl_mvm_ops) ;
}

#define IWL_MVM_COMMON_OPS					\
	/* these could be differentiated */			\
	.async_cb = iwl_mvm_async_cb,				\
	.queue_full = iwl_mvm_stop_sw_queue,			\
	.queue_not_full = iwl_mvm_wake_sw_queue,		\
	.hw_rf_kill = iwl_mvm_set_hw_rfkill_state,		\
	.free_skb = iwl_mvm_free_skb,				\
	.nic_error = iwl_mvm_nic_error,				\
	.cmd_queue_full = iwl_mvm_cmd_queue_full,		\
	.nic_config = iwl_mvm_nic_config,			\
	/* as we only register one, these MUST be common! */	\
	.start = iwl_op_mode_mvm_start,				\
	.stop = iwl_op_mode_mvm_stop,				\
	.time_point = iwl_op_mode_mvm_time_point

static const struct iwl_op_mode_ops iwl_mvm_ops = {
	IWL_MVM_COMMON_OPS,
	.rx = iwl_mvm_rx,
};

static const struct iwl_op_mode_ops iwl_mvm_ops_mq = {
	IWL_MVM_COMMON_OPS,
	.rx = iwl_mvm_rx_mq,
	.rx_rss = iwl_mvm_rx_mq_rss,
};



iwl_mvm_rx(iwl_op_mode *op_mode, napi_struct *napi, iwl_rx_cmd_buffer *rxb) {
	iwl_rx_packet *pkt = rxb_addr(rxb) ;
	iwl_mvm *mvm = IWL_OP_MODE_GET_MVM(op_mode) ;
	u16 cmd = WIDE_ID(pkt->hdr.group_id, pkt->hdr.cmd) ;

	if(cmd == WIDE_ID(LEGACY_GROUP, REPLY_RX_MPDU_CMD))
		iwl_mvm_rx_rx_mpdu(mvm, napi, rxb) ;
	else if (cmd == WIDE_ID(LEGACY_GROUP, REPLY_RX_PHY_CMD))
		iwl_mvm_rx_rx_phy_cmd(mvm, rxb) ;
	else
		iwl_mvm_rx_comm(mvm, rxb, pkt) ;

}


iwl_mvm_rx_common(iwl_mvm *mvm, iwl_rx_cmd_buffer *rxb, iwl_rx_packet *pkt) {
	iwl_mvm_rx_check_trigger(mvm, pkt) ;

	iwl_notification_wait_notify(&mvm->notif_wait, pkt) ;

	for (iwl_rx_handlers *rx_h : iwl_mvm_rx_handlers) {
		if (rx_h->context == RX_HANDLER_SYNC) {
			rx_h->fn(mvm, rxb) ;
			return ;
		}
		iwl_async_handler_entry *entry = rxb(*) ;
		entry->fn = rx_h->fn ;
		list_add_tail(&entry->list, &mvm->aync_handler_list) ;
		//key
		schedule_work(&mvm->async_handlers_wk) ;
	}
}



/*
 * Handlers for fw notifications
 * Convention: RX_HANDLER(CMD_NAME, iwl_mvm_rx_CMD_NAME
 * This list should be in order of frequency for performance purposes.
 *
 * The handler can be one from three contexts, see &iwl_rx_handler_context
 */
static const struct iwl_rx_handlers iwl_mvm_rx_handlers[] = {
	RX_HANDLER(TX_CMD, iwl_mvm_rx_tx_cmd, RX_HANDLER_SYNC,
		   struct iwl_mvm_tx_resp),
	RX_HANDLER(BA_NOTIF, iwl_mvm_rx_ba_notif, RX_HANDLER_SYNC,
		   struct iwl_mvm_ba_notif),

	RX_HANDLER_GRP(DATA_PATH_GROUP, TLC_MNG_UPDATE_NOTIF,
		       iwl_mvm_tlc_update_notif, RX_HANDLER_SYNC,
		       struct iwl_tlc_update_notif),

	RX_HANDLER(BT_PROFILE_NOTIFICATION, iwl_mvm_rx_bt_coex_notif,
		   RX_HANDLER_ASYNC_LOCKED, struct iwl_bt_coex_profile_notif),
	RX_HANDLER_NO_SIZE(BEACON_NOTIFICATION, iwl_mvm_rx_beacon_notif,
			   RX_HANDLER_ASYNC_LOCKED),
	RX_HANDLER_NO_SIZE(STATISTICS_NOTIFICATION, iwl_mvm_rx_statistics,
			   RX_HANDLER_ASYNC_LOCKED),

	RX_HANDLER(BA_WINDOW_STATUS_NOTIFICATION_ID,
		   iwl_mvm_window_status_notif, RX_HANDLER_SYNC,
		   struct iwl_ba_window_status_notif),

	RX_HANDLER(TIME_EVENT_NOTIFICATION, iwl_mvm_rx_time_event_notif,
		   RX_HANDLER_SYNC, struct iwl_time_event_notif),
	RX_HANDLER_GRP(MAC_CONF_GROUP, SESSION_PROTECTION_NOTIF,
		       iwl_mvm_rx_session_protect_notif, RX_HANDLER_SYNC,
		       struct iwl_mvm_session_prot_notif),
	RX_HANDLER(MCC_CHUB_UPDATE_CMD, iwl_mvm_rx_chub_update_mcc,
		   RX_HANDLER_ASYNC_LOCKED, struct iwl_mcc_chub_notif),

	RX_HANDLER(EOSP_NOTIFICATION, iwl_mvm_rx_eosp_notif, RX_HANDLER_SYNC,
		   struct iwl_mvm_eosp_notification),

	RX_HANDLER(SCAN_ITERATION_COMPLETE,
		   iwl_mvm_rx_lmac_scan_iter_complete_notif, RX_HANDLER_SYNC,
		   struct iwl_lmac_scan_complete_notif),
	RX_HANDLER(SCAN_OFFLOAD_COMPLETE,
		   iwl_mvm_rx_lmac_scan_complete_notif,
		   RX_HANDLER_ASYNC_LOCKED, struct iwl_periodic_scan_complete),
	RX_HANDLER_NO_SIZE(MATCH_FOUND_NOTIFICATION,
			   iwl_mvm_rx_scan_match_found,
			   RX_HANDLER_SYNC),
	RX_HANDLER(SCAN_COMPLETE_UMAC, iwl_mvm_rx_umac_scan_complete_notif,
		   RX_HANDLER_ASYNC_LOCKED, struct iwl_umac_scan_complete),
	RX_HANDLER(SCAN_ITERATION_COMPLETE_UMAC,
		   iwl_mvm_rx_umac_scan_iter_complete_notif, RX_HANDLER_SYNC,
		   struct iwl_umac_scan_iter_complete_notif),

	RX_HANDLER(CARD_STATE_NOTIFICATION, iwl_mvm_rx_card_state_notif,
		   RX_HANDLER_SYNC, struct iwl_card_state_notif),

	RX_HANDLER(MISSED_BEACONS_NOTIFICATION, iwl_mvm_rx_missed_beacons_notif,
		   RX_HANDLER_SYNC, struct iwl_missed_beacons_notif),

	RX_HANDLER(REPLY_ERROR, iwl_mvm_rx_fw_error, RX_HANDLER_SYNC,
		   struct iwl_error_resp),
	RX_HANDLER(PSM_UAPSD_AP_MISBEHAVING_NOTIFICATION,
		   iwl_mvm_power_uapsd_misbehaving_ap_notif, RX_HANDLER_SYNC,
		   struct iwl_uapsd_misbehaving_ap_notif),
	RX_HANDLER_NO_SIZE(DTS_MEASUREMENT_NOTIFICATION, iwl_mvm_temp_notif,
			   RX_HANDLER_ASYNC_LOCKED),
	RX_HANDLER_GRP_NO_SIZE(PHY_OPS_GROUP, DTS_MEASUREMENT_NOTIF_WIDE,
			       iwl_mvm_temp_notif, RX_HANDLER_ASYNC_UNLOCKED),
	RX_HANDLER_GRP(PHY_OPS_GROUP, CT_KILL_NOTIFICATION,
		       iwl_mvm_ct_kill_notif, RX_HANDLER_SYNC,
		       struct ct_kill_notif),

	RX_HANDLER(TDLS_CHANNEL_SWITCH_NOTIFICATION, iwl_mvm_rx_tdls_notif,
		   RX_HANDLER_ASYNC_LOCKED,
		   struct iwl_tdls_channel_switch_notif),
	RX_HANDLER(MFUART_LOAD_NOTIFICATION, iwl_mvm_rx_mfuart_notif,
		   RX_HANDLER_SYNC, struct iwl_mfuart_load_notif_v1),
	RX_HANDLER_GRP(LOCATION_GROUP, TOF_RESPONDER_STATS,
		       iwl_mvm_ftm_responder_stats, RX_HANDLER_ASYNC_LOCKED,
		       struct iwl_ftm_responder_stats),

	RX_HANDLER_GRP_NO_SIZE(LOCATION_GROUP, TOF_RANGE_RESPONSE_NOTIF,
			       iwl_mvm_ftm_range_resp, RX_HANDLER_ASYNC_LOCKED),
	RX_HANDLER_GRP_NO_SIZE(LOCATION_GROUP, TOF_LC_NOTIF,
			       iwl_mvm_ftm_lc_notif, RX_HANDLER_ASYNC_LOCKED),

	RX_HANDLER_GRP(DEBUG_GROUP, MFU_ASSERT_DUMP_NTF,
		       iwl_mvm_mfu_assert_dump_notif, RX_HANDLER_SYNC,
		       struct iwl_mfu_assert_dump_notif),
	RX_HANDLER_GRP(PROT_OFFLOAD_GROUP, STORED_BEACON_NTF,
		       iwl_mvm_rx_stored_beacon_notif, RX_HANDLER_SYNC,
		       struct iwl_stored_beacon_notif_v2),
	RX_HANDLER_GRP(DATA_PATH_GROUP, MU_GROUP_MGMT_NOTIF,
		       iwl_mvm_mu_mimo_grp_notif, RX_HANDLER_SYNC,
		       struct iwl_mu_group_mgmt_notif),
	RX_HANDLER_GRP(DATA_PATH_GROUP, STA_PM_NOTIF,
		       iwl_mvm_sta_pm_notif, RX_HANDLER_SYNC,
		       struct iwl_mvm_pm_state_notification),
	RX_HANDLER_GRP(MAC_CONF_GROUP, PROBE_RESPONSE_DATA_NOTIF,
		       iwl_mvm_probe_resp_data_notif,
		       RX_HANDLER_ASYNC_LOCKED,
		       struct iwl_probe_resp_data_notif),
	RX_HANDLER_GRP(MAC_CONF_GROUP, CHANNEL_SWITCH_NOA_NOTIF,
		       iwl_mvm_channel_switch_noa_notif,
		       RX_HANDLER_SYNC, struct iwl_channel_switch_noa_notif),
	RX_HANDLER_GRP(DATA_PATH_GROUP, MONITOR_NOTIF,
		       iwl_mvm_rx_monitor_notif, RX_HANDLER_ASYNC_LOCKED,
		       struct iwl_datapath_monitor_notif),

	RX_HANDLER_GRP(DATA_PATH_GROUP, THERMAL_DUAL_CHAIN_REQUEST,
		       iwl_mvm_rx_thermal_dual_chain_req,
		       RX_HANDLER_ASYNC_LOCKED,
		       struct iwl_thermal_dual_chain_request),
};



/*
 * iwl_mvm_rx_rx_phy_cmd - REPLY_RX_PHY_CMD handler
 *
 * Copies the phy information in mvm->last_phy_info, it will be used when the
 * actual data will come from the fw in the next packet.
 */
iwl_mvm_rx_rx_phy_cmd(iwl_mvm *mvm, iwl_rx_cmd_buffer *rxb) {
	iwl_rx_packet *pkt = rxb_addr(rxb);
	memcpy(&mvm->last_phy_info, pkt->data, sizeof(mvm->last_phy_info));
	mvm->ampdu_ref++;
}


/*
 * iwl_mvm_rx_rx_mpdu - REPLY_RX_MPDU_CMD handler
 *
 * Handles the actual data of the Rx packet from the fw
 */
iwl_mvm_rx_rx_mpdu(iwl_mvm *mvm, napi_struct *napi, iwl_rx_cmd_buffer *rxb) {
	iwl_mvm_get_signal_strength(mvm, phy_info, rx_status) ;
	if (sta) {
		rs_update_last_rssi(mvm, mvmsta, rx_status) ;
	}
	iwl_mvm_pass_packet_to_mac80211(mvm, sta, napi, skb, hdr, len, crypt_len, rxb) ;
}

/*
 * iwl_mvm_pass_packet_to_mac80211 - builds the packet for mac80211
 *
 * Adds the rxb to a new skb and give it to mac80211
 */
iwl_mvm_pass_packet_to_mac80211(iwl_mvm *mvm, ieee80211_sta *sta, napi_struct *napi,
	sk_buff *skb, ieee80211_hdr *hdr, u16 len, crypt_len, iwl_rx_cmd_buffer *rxb) {
	ieee80211_rx_napi(mvm->hw, sta, skb, napi) ;
}



//mvm/ops.c
iwl_op_mode_mvm_start(iwl_trans *trans, iwl_cfg *cfg, iwl_fw *fw, dentry *dbgfs_dir) {
	ieee80211_hw *hw = ieee80211_alloc_hw(sizeof(iwl_op_mode+iwl_mvm), &iwl_mvm_hw_ops) ;
	iwl_fw_runtiome_init() ;
	iwl_mvm_get_acpi_tables() ;

	//ax210+用iwl_mvm_ops_mq,其余用的iwl_mvm_ops
	//但是picoscenes在ax200+也可,说明csi二者ops都行
	if (iwl_mnm_has_new_rx_api(mvm)) {
		op_mode->ops = &iwl_mvm_ops_mq ;
		trans->rx_mpdu_cmd_hdr_size = 
			(trans->trans_cfg->device_family >= IWL_DEVICE_FAMILY_AX210) ? 
			sizeof(iwl_rx_mpdu_desc) : IWL_RX_DESC_SIZE_V1 ;
	}
	else {
		op_mode->ops = &iwl_mvm_ops ;
		trans->rx_mpdu_cmd_hdr_size = sizeof(iwl_rx_mpdu_res_start) ;
	}

	//这里注册的函数,会在rx_common中schedule
	INIT_WORK(&mvm->async_handlers_wk, iwl_mvm_async_handlers_wk) {
		iwl_mvm_async_handlers_wk(work_struct *wk) {
			iwl_async_handler_entry *entry ;
			foreach(entry)
				entry->fn(mvm, &entry->rxb) ;
		}
	}
	//...
	
	iwl_trans_start_hw(mnm->trans) {
		trans->ops->start_hw(trans)
	}

	iwl_mvm_start_get_nvm(mvm) ;
	iwl_mvm_start_post_nvm(mvm) ;
}

struct iwl_async_handler_entry {
	struct list_head list;
	struct iwl_rx_cmd_buffer rxb;
	enum iwl_rx_handler_context context;
	void (*fn)(struct iwl_mvm *mvm, struct iwl_rx_cmd_buffer *rxb);
};





















