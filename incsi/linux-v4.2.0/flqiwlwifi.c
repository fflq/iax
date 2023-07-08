

module_init(iwl_drv_init)
iwl_drv_init() {
    iwl_pci_register_driver() {
        iwl_drv_start() {
            iwl_request_firmware(first=true);
        }
    }
}


//dvm/mvm will register
IWL_EXPORT_SYMBOL(iwl_opmode_register)
iwl_opmode_register(name,ops){
	//对dvm而言,这里的ops=iwl_dvm_ops
	for ((op=iwlwifi_opmode_table[i]).name == name) {
		op->ops = ops ;
		list_for(drv, op->drv) {
			drv->op_mode = _iwl_op_mode_start(ops) {
				//对dvm,=iwl_dvm_ops.start()=iwl_op_mode_dvm_start() ;
				return ops->start() ;
			}
		}
		return 0 ;
    }
}


//iwl-drv.c
enum {
	DVM_OP_MODE =	0,
	MVM_OP_MODE =	1,
};
static struct iwlwifi_opmode_table {
	const char *name;			/* name: iwldvm, iwlmvm, etc */
	const struct iwl_op_mode_ops *ops;	/* pointer to op_mode ops */
	struct list_head drv;		/* list of devices using this op_mode */
} iwlwifi_opmode_table[] = {		/* ops set when driver is initialized */
	[DVM_OP_MODE] = { .name = "iwldvm", .ops = NULL },
	[MVM_OP_MODE] = { .name = "iwlmvm", .ops = NULL },
};





























