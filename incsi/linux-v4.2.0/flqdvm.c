
const u8 iwl_bcast_addr[ETH_ALEN] = { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };


module_init(iwl_init)
iwl_init(){
    iwlagn_register_connector(){
        cn_add_callback(connector_callback())
        INIT_WORK(connector_work(){
            connector_send_all(){
                cn_netlink_send()
            }
        })
    }

    iwl_opmode_register("iwldvm", iwl_dvm_ops) ; 
}


//dvm/main.c
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


//csi key: iwl_rx_dispatch()->iwlagn_bfee_notif()
//handlers[REPLY_BFEE_NOTIFICATION] = iwlagn_bfee_notif;
//dvm/lib.c中调用该函数
iwlagn_bfee_notif(iwl_priv *priv, iwl_rx_cmd_buffer *rxb, iwl_device_cmd *cmd) {
#define rxb_addr(r) page_address(r->page)
	iwl_rx_packet *pkt = rxb_addr(rxb) ;
	iwl_bfee_notif *bfee_notif = (void*)pkt->data ;

	if (priv->last_phy_res_valid) {
		iwl_rx_phy_res *phy = &priv->last_phy_res ;
		bfee_notif->* = f(*) ;
	}

	u16 len = le16_to_cpu(bfee_notif->len) ;
    if (priv->connector_log & IWL_CONN_BFEE_NOTIF_MSK) // 1
        connector_send_msg(bfee_notif, len+sizeof(iwl_bfee_notif), IWL_CONN_BFEE_NOTIF) // bb

	/*
	 * Each subcarrier uses Ntx * Nrx * 2 * 8 bits for matrix
	 * (2 signed 8-bit I/Q vals) plus 3 bits for SNR. I think the hardware
	 * always gives 0 for these 3 bits. See 802.11n spec section 7.3.1.28.
	 */
}

struct iwl_rx_packet {
	/*
	 * The first 4 bytes of the RX frame header contain both the RX frame
	 * size and some flags.
	 * Bit fields:
	 * 31:    flag flush RB request
	 * 30:    flag ignore TC (terminal counter) request
	 * 29:    flag fast IRQ request
	 * 28-14: Reserved
	 * 13-00: RX frame size
	 */
	__le32 len_n_flags;
	struct iwl_cmd_header hdr;
	u8 data[];
} __packed;

struct iwl_rx_cmd_buffer {
	struct page *_page;
	int _offset;
	bool _page_stolen;
	u32 _rx_page_order;
	unsigned int truesize;
};


#define DEF_CMD_PAYLOAD_SIZE 320
/**
 * struct iwl_device_cmd
 *
 * For allocation of the command and tx queues, this establishes the overall
 * size of the largest command we send to uCode, except for commands that
 * aren't fully copied and use other TFD space.
 */
struct iwl_device_cmd {
	struct iwl_cmd_header hdr;	/* uCode API */
	u8 payload[DEF_CMD_PAYLOAD_SIZE];
} __packed;

/*
 * REPLY_BFEE_NOTIFICATION = 0xbb
 *
 */
struct iwl_bfee_notif {
	__le32 timestamp_low;
	__le16 bfee_count;
	__le16 reserved1;
	u8 Nrx, Ntx;
	u8 rssiA, rssiB, rssiC;
	s8 noise;
	u8 agc, antenna_sel;
	__le16 len;
	__le16 fake_rate_n_flags;
	u8 payload[0];
} __attribute__ ((packed));



//pcie/rx.c中iwl_pcie_rx_handle_rb中调用该函数
//op_mode->ops->rx(op_mode, rxb, cmd)=iwl_dvm_ops.rx()=iwl_rx_dispatch() ;
iwl_rx_dispatch(){
    iwl_notification_wait_notify() ;
	//之前rx_handlers注册了很多函数,这里根据cmd分发调用
	//如dvm在cmd==REPLAY_BFEE_NOTIFICATION时,调用iwlagn_bfee_notif
    priv->rx_handlers[pkt->hdr.cmd](priv, rxb, cmd) ;
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



#define IWL_CMD_ENTRY(x) [x] = #x

const char *const iwl_dvm_cmd_strings[REPLY_MAX] = {
	IWL_CMD_ENTRY(REPLY_ALIVE),
	IWL_CMD_ENTRY(REPLY_ERROR),
	IWL_CMD_ENTRY(REPLY_ADD_STA),
	IWL_CMD_ENTRY(REPLY_REMOVE_STA),
	IWL_CMD_ENTRY(REPLY_REMOVE_ALL_STA),
	IWL_CMD_ENTRY(REPLY_TX),
	IWL_CMD_ENTRY(REPLY_TX_LINK_QUALITY_CMD),
	IWL_CMD_ENTRY(REPLY_CHANNEL_SWITCH),
	IWL_CMD_ENTRY(CHANNEL_SWITCH_NOTIFICATION),
	IWL_CMD_ENTRY(PM_SLEEP_NOTIFICATION),
	IWL_CMD_ENTRY(REPLY_SCAN_CMD),
	IWL_CMD_ENTRY(SCAN_START_NOTIFICATION),
	IWL_CMD_ENTRY(BEACON_NOTIFICATION),
	IWL_CMD_ENTRY(REPLY_TX_BEACON),
	IWL_CMD_ENTRY(WHO_IS_AWAKE_NOTIFICATION),
	IWL_CMD_ENTRY(QUIET_NOTIFICATION),
	IWL_CMD_ENTRY(REPLY_RX_PHY_CMD),
	IWL_CMD_ENTRY(REPLY_RX_MPDU_CMD),
	IWL_CMD_ENTRY(CALIBRATION_COMPLETE_NOTIFICATION),
	IWL_CMD_ENTRY(REPLY_TX_POWER_DBM_CMD),
	IWL_CMD_ENTRY(TX_ANT_CONFIGURATION_CMD),
	...,
	//flqbeg
	IWL_CMD_ENTRY(REPLY_BFEE_NOTIFICATION),
	//flqend
};




