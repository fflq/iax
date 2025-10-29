// Copyright 2023 fflq

#include <netlink/netlink.h>
#include <netlink/socket.h>
#include <netlink/msg.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/family.h>
#include <netlink/genl/ctrl.h>
#include <linux/nl80211.h>
#include <net/if.h>
#include <unistd.h>
#include <errno.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <iostream>
#include <string>
#include <map>
#include <memory>

#include "iwl_fw_api_rs.h"
#include "tcp_client.h"
#include "iaxcsi.h"


FILE *g_fp_csi = nullptr;
struct nl_cb *g_nl_cb = nullptr;
unsigned int g_port_id = 0;
int g_dev_idx = -1;
std::unique_ptr<iaxcsi::TcpClient> g_tcp_client = nullptr;


void register_iwl_mvm_vendor_csi(struct nl_sock *sk, int family_id) {
    struct nl_msg* msg = nlmsg_alloc();

    // fflqkey, refer __cfg80211_alloc_vendor_skb
#define INTEL_OUI   0X001735
#define IWL_MVM_VENDOR_CMD_CSI_EVENT    0x24
    // genlmsg_put(msg, NL_AUTO_PORT, NL_AUTO_SEQ, family_id, 0, NLM_F_DUMP, NL80211_CMD_GET_INTERFACE, 0);
    genlmsg_put(msg, 0, NL_AUTO_SEQ, family_id, 0, NLM_F_MATCH, NL80211_CMD_VENDOR, 0);

    nla_put_u32(msg, NL80211_ATTR_IFINDEX, g_dev_idx);
    // or /sys/class/ieee80211/${phyname}/index
    // nla_put_u32(msg, NL80211_ATTR_WIPHY, 0) ;
    nla_put_u32(msg, NL80211_ATTR_VENDOR_ID, INTEL_OUI);
    nla_put_u32(msg, NL80211_ATTR_VENDOR_SUBCMD, IWL_MVM_VENDOR_CMD_CSI_EVENT);
    // nla_put(msg, NL80211_ATTR_VENDOR_DATA, 0, nullptr) ;
#undef INTEL_OUI
#undef IWL_MVM_VENDOR_CMD_CSI_EVENT

    int r = nl_send_auto(sk, msg);
    log("%s, send return %d\n", __func__, r);

    r = nl_recvmsgs_default(sk);
    // struct nl_cb *cb = nl_cb_alloc(NL_CB_DEFAULT);
    // r = nl_recvmsgs_report(sk, g_nl_cb);
    log("%s, recv return %d\n\n", __func__, r);
}


void output_tb_msg(struct nlattr **tb_msg) {
    for (int i = 0; i < NL80211_ATTR_MAX; ++i) {
        if (tb_msg[i])
            dbg_log("-- tb_msg[%x]: len %d, type %x\n", i, tb_msg[i]->nla_len, tb_msg[i]->nla_type);
    }
}


void output_hexs(uint8_t *data, int len) {
    for (int n = 0; n < len; ++n) {
        if (0 == n % 16)    dbg_log("\n%08d:", n);
        else if (0 == n % 8)    dbg_log("  ");
        else if (0 == n % 4)    dbg_log(" ");
        dbg_log(" %02X", data[n]);
    }
    dbg_log("\n");
}


int get_rnf_fmt_val(uint32_t rnf, int pos, int msk) {
    return (rnf & msk) >> pos;
}


void parse_rate_n_flags(uint32_t rnf, p_rate_info_t p_rinfo) {
    // Bits 3-0: MCS
    p_rinfo->mcs = get_rnf_fmt_val(rnf, RATE_HT_MCS_CODE_POS, RATE_HT_MCS_CODE_MSK);

    // Bits 5-4: nss
    p_rinfo->nss = get_rnf_fmt_val(rnf, RATE_MCS_NSS_POS, RATE_MCS_NSS_MSK)+1;

    // Bits 10-8: rate format, mod type
    // p_rinfo->rate_type = get_rnf_fmt_val(rnf, RATE_MCS_MOD_TYPE_POS, RATE_MCS_MOD_TYPE_MSK);
    p_rinfo->rate_type = get_rnf_fmt_val(rnf, 0, RATE_MCS_MOD_TYPE_MSK);
    p_rinfo->rate_type_str = g_rate_type_map[p_rinfo->rate_type].c_str();

    // Bits 24-23: HE type
    // static int he_rate_type = get_rnf_fmt_val(RATE_MCS_HE_MSK, RATE_MCS_MOD_TYPE_POS, RATE_MCS_MOD_TYPE_MSK);
    static int he_rate_type = get_rnf_fmt_val(RATE_MCS_HE_MSK, 0, RATE_MCS_MOD_TYPE_MSK);
    if (p_rinfo->rate_type == he_rate_type) {
        // p_rinfo->he_type = get_rnf_fmt_val(rnf, RATE_MCS_HE_TYPE_POS, RATE_MCS_HE_TYPE_MSK);
        p_rinfo->he_type = get_rnf_fmt_val(rnf, 0, RATE_MCS_HE_TYPE_MSK);
        p_rinfo->he_type_str = g_he_type_map[p_rinfo->he_type].c_str();
    }

    // Bits 13-11: chan width
    // p_rinfo->chan_width_type = get_rnf_fmt_val(rnf, RATE_MCS_CHAN_WIDTH_POS, RATE_MCS_CHAN_WIDTH_MSK) ;
    /* 
    static int legacy_ofdm_rate_type = get_rnf_fmt_val(RATE_MCS_LEGACY_OFDM_MSK, RATE_MCS_MOD_TYPE_POS, RATE_MCS_MOD_TYPE_MSK);
    static int legacy_ofdm_bw_type = get_rnf_fmt_val(RATE_MCS_CHAN_WIDTH_20, RATE_MCS_CHAN_WIDTH_POS, RATE_MCS_CHAN_WIDTH_MSK) ;
    */
    p_rinfo->chan_width_type = get_rnf_fmt_val(rnf, 0, RATE_MCS_CHAN_WIDTH_MSK);
    static int legacy_ofdm_rate_type = get_rnf_fmt_val(RATE_MCS_LEGACY_OFDM_MSK, 0, RATE_MCS_MOD_TYPE_MSK);
    static int legacy_ofdm_bw_type = get_rnf_fmt_val(RATE_MCS_CHAN_WIDTH_20, 0, RATE_MCS_CHAN_WIDTH_MSK);
    if (p_rinfo->rate_type == legacy_ofdm_rate_type) {
        p_rinfo->chan_width_type = legacy_ofdm_bw_type;
    }
    p_rinfo->bandwidth = g_chan_width_map[p_rinfo->chan_width_type];

    p_rinfo->rate_bw_type = (p_rinfo->rate_type_str + std::to_string(p_rinfo->bandwidth)).c_str();

    // Bits 15-14: antenna selection
    p_rinfo->ant_sel = get_rnf_fmt_val(rnf, RATE_MCS_ANT_POS, RATE_MCS_ANT_MSK);

    // Bits 16: LDPC enables
    p_rinfo->ldpc = get_rnf_fmt_val(rnf, RATE_MCS_LDPC_POS, RATE_MCS_LDPC_MSK);

    dbg_log("rate_bw(%s,%d,%s) ant_sel(%d) ldpc(%d)\n", p_rinfo->rate_type_str, p_rinfo->bandwidth,
            p_rinfo->rate_bw_type, p_rinfo->ant_sel, p_rinfo->ldpc);
    if (p_rinfo->rate_type == he_rate_type) {
        dbg_log("he_type(%d,%s)\n", p_rinfo->he_type, p_rinfo->he_type_str);
    }
}


void parse_csi_buf(uint8_t *csi_hdr, int csi_hdr_len, uint8_t *csi_data, int csi_data_len) {
    dbg_log("* %s\n", __func__);

    static uint8_t buf[20480];
    uint32_t n32;
    int pos = 0;

    pos += 4;
    n32 = htonl(csi_hdr_len);
    memcpy(buf+pos, &n32, 4);
    pos += 4;
    memcpy(buf+pos, csi_hdr, csi_hdr_len);
    pos += csi_hdr_len;
    n32 = htonl(csi_data_len);
    memcpy(buf+pos, &n32, 4);
    pos += 4;
    memcpy(buf+pos, csi_data, csi_data_len);
    pos += csi_data_len;
    // csi_len
    n32 = htonl(pos-4);
    memcpy(buf, &n32, 4);

    // save to file
    if (g_fp_csi) {
        fwrite(buf, 1, pos, g_fp_csi);
        fflush(g_fp_csi);
    }

    // send to net
    if (g_tcp_client) {
        g_tcp_client->send(buf, pos);
    }

    // parse csi_hdr in little endian
    csi_hdr_t *pch = (p_csi_hdr_t)csi_hdr;
    dbg_log("csi_len(%u) ftm(%u) (nrx,ntx,ntone)=(%u,%u,%u)\n", pch->csi_len, pch->ftm, pch->nrx, pch->ntx, pch->ntone);
    dbg_log("rssi(%d,%d) seq(%u) us(%u) rnf(0x%x) ts(%lu)\n", -pch->opp_rssi1, -pch->opp_rssi2, pch->seq,
            pch->us, pch->rate_n_flags, pch->ts);
    uint8_t *smac = pch->smac;
    dbg_log("mac(%02x:%02x:%02x:%02x:%02x:%02x)\n", smac[0], smac[1], smac[2], smac[3], smac[4], smac[5]);

    rate_info_t rinfo;
    parse_rate_n_flags(pch->rate_n_flags, &rinfo);

    // output_hexs(csi_hdr, csi_hdr_len);
}


static int valid_cb(struct nl_msg *msg, void *) {
    struct genlmsghdr *gnlh = reinterpret_cast<genlmsghdr *>(nlmsg_data(nlmsg_hdr(msg)));
    struct nlattr *tb_msg[NL80211_ATTR_MAX + 1];
    struct nlattr *msg_vendor_data, *nmsg_csi_hdr = nullptr, *nmsg_csi_data = nullptr;
    struct nlattr *nested_tb_msg[NL80211_ATTR_MAX + 1];

    dbg_log("* %s\n", __func__);
    // nl_msg_dump(msg, stdout);
    // return NL_SKIP ;

    nla_parse(tb_msg, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh, 0), genlmsg_attrlen(gnlh, 0), nullptr);
    // output_tb_msg(tb_msg) ;

    if ((msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_ID])) {
        // do for vendor_id
    }
    if ((msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_SUBCMD])) {
        // do for vendor_subcmd
    }

#define IWL_MVM_VENDOR_ATTR_CSI_HDR     0x4d
#define IWL_MVM_VENDOR_ATTR_CSI_DATA    0x4e
    if ((msg_vendor_data = tb_msg[NL80211_ATTR_VENDOR_DATA])) {
        dbg_log("-- tb_msg[%x] is vendor_data\n", NL80211_ATTR_VENDOR_DATA);
        nla_parse_nested(nested_tb_msg, NL80211_ATTR_MAX, msg_vendor_data, nullptr);
        output_tb_msg(nested_tb_msg);

        nmsg_csi_hdr = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_HDR];
        nmsg_csi_data = nested_tb_msg[IWL_MVM_VENDOR_ATTR_CSI_DATA];
#undef IWL_MVM_VENDOR_ATTR_CSI_HDR
#undef IWL_MVM_VENDOR_ATTR_CSI_DATA

        if (nmsg_csi_hdr && nmsg_csi_data) {
            dbg_log("-- (nla_type,nla_len) csi_hdr(%x,%u-4) csi_data(%x,%u-4)\n",
                    nmsg_csi_hdr->nla_type, nmsg_csi_hdr->nla_len,
                    nmsg_csi_data->nla_type, nmsg_csi_data->nla_len);

            uint16_t csi_hdr_len = nmsg_csi_hdr->nla_len - 4;
            uint8_t *csi_hdr = reinterpret_cast<uint8_t *>(nla_get_string(nmsg_csi_hdr));

            uint16_t csi_data_len = nmsg_csi_data->nla_len - 4;
            uint8_t *csi_data = reinterpret_cast<uint8_t *>(nla_get_string(nmsg_csi_data));

            if ((csi_hdr_len != 272) || !csi_hdr || !csi_data) {
                dbg_log("* %s, csi_hdr_len(%d)!=272 or !csi_hdr or !csi_data\n", __func__, csi_hdr_len);
                return NL_SKIP;
            }

            // if (nmsg_csi_data->nla_len == 420 || nmsg_csi_data->nla_len == 832) { }
            parse_csi_buf(csi_hdr, csi_hdr_len, csi_data, csi_data_len);
        }
    }

    return NL_SKIP;
}


static int finish_cb(struct nl_msg *msg, void *arg) {
    int *finished = reinterpret_cast<int *>(arg);
    *finished = 1;
    dbg_log("* %s -------\n", __func__);
    nl_msg_dump(msg, stdout);

    return NL_SKIP;
}


void loop_recv_msg(struct nl_sock *sk) {
    int n = 0;
    int finished = 0;

    // struct nl_cb *cb = nl_cb_alloc(NL_CB_DEFAULT);
    // nl_cb_set(cb, NL_CB_VALID , NL_CB_CUSTOM, valid_cb, nullptr);
    // nl_cb_set(cb, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &finished);
    nl_socket_modify_cb(sk, NL_CB_VALID, NL_CB_CUSTOM, valid_cb, nullptr);
    nl_socket_modify_cb(sk, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &finished);

    while (!finished) {
        // r = nl_recvmsgs(sk, cb);
        // r = nl_recvmsgs_report(sk, g_nl_cb) ;
        int r = nl_recvmsgs_default(sk);
        // dbg_log("* %s %d, %u nl_recvmsgs %d\n\n", __func__, ++n, g_port_id, r) ;
        log("* %s %d, %u nl_recvmsgs %d\n\n", __func__, ++n, g_port_id, r);
        // if (r < 0)   break;
        if (r < 0) {
            log("* nl_recvmsgs err %d\n\n", r);
            continue;
        }
    }
}


void handle_args(int argc, char **argv) {
    if (argc < 2) {
        log("Usage: sudo %s wlan [file] [addr]\n"
            "- wlan: eg wlp8s0\n"
            "- file: eg ./a.csi\n"
            "* eg: sudo %s wlp8s0 ./a.csi [127.0.0.1:7120]\n", argv[0], argv[0]);
        exit(EXIT_FAILURE);
    }

    g_dev_idx = if_nametoindex(argv[1]);
    if (argc > 2) {
        g_fp_csi = fopen(argv[2], "w");
        if (!g_dev_idx || !g_fp_csi) {
            log("* args err(%s), devidx(%d) fp_csi(%p)\n", strerror(errno), g_dev_idx, g_fp_csi);
            exit(EXIT_FAILURE);
        }
    }

    if (argc > 3) {
        g_tcp_client = std::make_unique<iaxcsi::TcpClient>(argv[3]);
    }
}


struct nl_sock *init_nl_socket() {
    struct nl_sock *sk = nl_socket_alloc();

    if (!sk) {
        perror("* failed nl_socket_alloc\n");
        return nullptr;
    }

    if (genl_connect(sk)) {
        perror("* failed genl_connect\n");
        return nullptr;
    }

    nl_socket_set_buffer_size(sk, 32768, 32768);
    // miss will nl_recvmsgs_default=-16
    nl_socket_disable_seq_check(sk);
    int family_id = genl_ctrl_resolve(sk, "nl80211");
    // family_id = 34 ;
    // int family_id = genl_ctrl_resolve(sk, "iwl_tm_gnl") ;
    // int family_id = genl_ctrl_resolve(sk, "vendor") ;
    if (family_id < 0) {
        perror("* failed genl_ctrl_resolve\n");
        return nullptr;
    }

    g_nl_cb = nl_cb_alloc(NL_CB_DEFAULT);
    // nl_cb_set(g_nl_cb, NL_CB_VALID , NL_CB_CUSTOM, valid_cb, nullptr);
    // nl_cb_set(g_nl_cb, NL_CB_FINISH, NL_CB_CUSTOM, finish_cb, &gr);

    struct csi_nl_sock *csi_sk = (struct csi_nl_sock*)sk;
    log("* (nl_family,nl_pid,nl_groups), s_local(%u,%u,%u), s_peer(%u,%u,%u)\n",
            csi_sk->s_local.nl_family, csi_sk->s_local.nl_pid, csi_sk->s_local.nl_groups,
            csi_sk->s_peer.nl_family, csi_sk->s_peer.nl_pid, csi_sk->s_peer.nl_groups);
    g_port_id = csi_sk->s_local.nl_pid;

    register_iwl_mvm_vendor_csi(sk, family_id);

    return sk;
}


void deinit() {
    if (g_fp_csi) {
        fclose(g_fp_csi);
    }
}


int main(int argc, char **argv) {
    handle_args(argc, argv);

    struct nl_sock *sk = init_nl_socket();
    if (sk) {
        loop_recv_msg(sk);
    }

    deinit();

    return 0;
}

#undef dbg_log
#undef log
