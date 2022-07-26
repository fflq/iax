
module_init(iwl_init(){
    iwlagn_register_connector(){
        cn_add_callback(connector_callback())
        INIT_WORK(connector_work(){
            connector_send_all(){
                cn_netlink_send()
            }
        })
    }

    iwl_opmode_register("iwldvm", iwl_dvm_ops)
})

iwl_op_mode_dvm_start(){
    iwl_trans_start_hw(){
        trans->ops->start_hw()
    }
    iwl_set_hw_params(){
        priv->lib->iwl_set_hw_params()
    }
    iwl_init_drv(){
        priv->connector_log = iwlwifi_mod_params.connector_log
        // choose which receivers/antennas to use
        iwlagn_set_rxon_chain()
        iwl_init_scan_params()
    }
    // Setup the RX handlers for each of the reply types sent from the uCode to the host.
    iwl_setup_rx_handlers(){
	    handlers[BEACON_NOTIFICATION] = iwlagn_rx_beacon_notif;
        iwl_setup_rx_scan_handlers(){ 
            priv->rx_handlers[REPLY_SCAN_CMD] = iwl_rx_reply_scan;
            priv->rx_handlers[SCAN_START_NOTIFICATION] = iwl_rx_scan_start_notif;
            priv->rx_handlers[SCAN_RESULTS_NOTIFICATION] = iwl_rx_scan_results_notif;
            priv->rx_handlers[SCAN_COMPLETE_NOTIFICATION] = iwl_rx_scan_complete_notif;
        }
	    // Rx handlers */
	    handlers[REPLY_RX_PHY_CMD] = iwlagn_rx_reply_rx_phy;
	    handlers[REPLY_RX_MPDU_CMD]	= iwlagn_rx_reply_rx;
	    // Beamforming */
	    handlers[REPLY_BFEE_NOTIFICATION] = iwlagn_bfee_notif;
    }
}

/* Cache phy data (Rx signal strength, etc) for HT frame (REPLY_RX_PHY_CMD).
 * This will be used later in iwl_rx_reply_rx() for REPLY_RX_MPDU_CMD. */
iwlagn_rx_reply_rx_phy(){ }

iwlagn_rx_reply_rx() {
    if (priv->connector_log & IWL_CONN_RX_MPDU_MSK) // 4
        connector_send_msg(header, IWL_CONN_RX_MPDU) // c1
}

// dvm/lib.c
iwlagn_bfee_notif() {
    if (priv->connector_log & IWL_CONN_BFEE_NOTIF_MSK) // 1
        connector_send_msg(bfee_notif, IWL_CONN_BFEE_NOTIF) // bb
}

iwl_rx_dispatch(){
    iwl_notification_wait_notify()
    priv->rx_handlers[pkt->hdr.cmd](priv, rxb, cmd)
}

static const struct iwl_op_mode_ops iwl_dvm_ops = {
	.start = iwl_op_mode_dvm_start,
	.stop = iwl_op_mode_dvm_stop,
	.rx = iwl_rx_dispatch,
	.queue_full = iwl_stop_sw_queue,
	.queue_not_full = iwl_wake_sw_queue,
	.hw_rf_kill = iwl_set_hw_rfkill_state,
	.free_skb = iwl_free_skb,
	.nic_error = iwl_nic_error,
	.cmd_queue_full = iwl_cmd_queue_full,
	.nic_config = iwl_nic_config,
	.wimax_active = iwl_wimax_active,
	.napi_add = iwl_napi_add,
};

// mostly 192/c0,193/c1, need 187/bb,195/c3
enum {

	/* Beamforming */
	REPLY_BFEE_NOTIFICATION = 0xbb,

	REPLY_RX_PHY_CMD = 0xc0,
	REPLY_RX_MPDU_CMD = 0xc1,
	REPLY_RX = 0xc3,
	REPLY_COMPRESSED_BA = 0xc5,

}


#define IWL_CONN_BFEE_NOTIF	REPLY_BFEE_NOTIFICATION		/* 0xbb */
#define IWL_CONN_RX_PHY		REPLY_RX_PHY_CMD		/* 0xc0 */
#define IWL_CONN_RX_MPDU	REPLY_RX_MPDU_CMD		/* 0xc1 */
#define IWL_CONN_RX		REPLY_RX			/* 0xc3 */
#define IWL_CONN_NOISE		0xd0		/* new ID not a command */
#define IWL_CONN_TX_RESP	REPLY_TX			/* 0x1c */
#define IWL_CONN_TX_BLOCK_AGG	REPLY_COMPRESSED_BA		/* 0xc5 */
#define IWL_CONN_STATUS		0xd1		/* new ID not a command */

enum {
	IWL_CONN_BFEE_NOTIF_MSK		= (1 << 0),
	IWL_CONN_RX_PHY_MSK		= (1 << 1),
	IWL_CONN_RX_MPDU_MSK		= (1 << 2),
	IWL_CONN_RX_MSK			= (1 << 3),
	IWL_CONN_NOISE_MSK		= (1 << 4),
	IWL_CONN_TX_RESP_MSK		= (1 << 5),
	IWL_CONN_TX_BLOCK_AGG_MSK	= (1 << 6),
	IWL_CONN_STATUS_MSK		= (1 << 7),
};











