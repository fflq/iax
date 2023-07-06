
//pcie/drv.c
iwl_pci_register_driver() {
	pci_register_driver(&iwl_pci_driver) ;
}

#define DRV_NAME	"iwlwifi"
static struct pci_driver iwl_pci_driver = {
	.name = DRV_NAME,
	.id_table = iwl_hw_card_ids,
	.probe = iwl_pci_probe,
	.remove = iwl_pci_remove,
	.driver.pm = IWL_PM_OPS,
};








