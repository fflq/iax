

module_init(iwl_drv_init() {
    iwl_pci_register_driver() {
        iwl_drv_start() {
            iwl_request_firmware(first=true)
        }
    }
})

//dvm/mvm will register
IWL_EXPORT_SYMBOL(iwl_opmode_register(name,ops){
    drv->op_mode = _iwl_op_mode_start(){
        return ops->start()
    }
})






























