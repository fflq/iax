
/* *get csi order: 
 * 简单说就是在pcie的中断中注册函数,其中有rx处理函数,然后分发到具体某种rx函数,
 * 最后调用到bfee_notif,发到用户层
 * 其中csi的rxb是直接从dma搞来的没有中介,说明都是在fw固件中整理好的,驱动只是传输rxb
 * iwl_trans_pcie_alloc()->request_threaded_irq(iwl_pcie_irq_handler)
 *	->iwl_pcie_irq_handler()->iwl_pcie_rx_handle()->iwl_pcie_rx_handle_rb()
 *	->iwl_rx_dispatch()->iwlagn_bfee_notif()->connector_send_msg()
 */



//pcie/rx.c
iwl_pcie_rx_handle_rb(iwl_trans *trans, iwl_rx_mem_buffer *rxb) {
	dma_unmap_page(trans->dev, rxb->page_dma, DMA_FROM_DEVICE) ;

	foreach (u32, iwl_cmd_header) {
		iwl_rx_packet *pkt = rxb_addr() ;
		iwl_op_mode_rx(trans->op_mode, rxcb, cmd) {
			//对dvm,=iwl_dvm_ops.rx()=iwl_rx_dispatch() ;
			op_mode->ops->rx(op_mode, rxb, cmd) ;
		}
	}
}


//pcie/rx.c
//来自fw响应的main入口
//iwl_pcie_rx_handle - Main entry function for receiving responses from fw
iwl_pcie_rx_handle(iwl_trans *trans) {
	struct iwl_trans_pcie *trans_pcie = IWL_TRANS_GET_PCIE_TRANS(trans);
	struct iwl_rxq *rxq = &trans_pcie->rxq;

	// r为从ucode中收到的最近需要driver处理的rx_buffer的索引
	/* uCode's read index (stored in shared DRAM) indicates the last Rx
	 * buffer that the driver may process (last buffer filled by ucode). */
	r = le16_to_cpu(ACCESS_ONCE(rxq->rb_stts->closed_rb_num)) & 0x0FFF;
	// i是队列中最新来的第一个rx_buf索引,r是最后一个
	i = rxq->read;

	//处理queue中收到的rxb
	while (i != r) {
		iwl_rx_mem_buffer *rxb = rxq->queue[i] ;
		iwl_pcie_rx_handle_rb(trans, rxb) ;
		i = (i+1) & RX_QUEUE_MASK ;
	}
	rxq->read = i ;
}


//pcie/internal.h
/**
 * struct iwl_rxq - Rx queue
 * @bd: driver's pointer to buffer of receive buffer descriptors (rbd)
 * @bd_dma: bus address of buffer of receive buffer descriptors (rbd)
 * @pool:
 * *@queue:
 * *@read: Shared index to newest available Rx buffer
 * @write: Shared index to oldest written Rx packet
 * @free_count: Number of pre-allocated buffers in rx_free
 * @write_actual:
 * @rx_free: list of free SKBs for use
 * @rx_used: List of Rx buffers with no SKB
 * @need_update: flag to indicate we need to update read/write index
 * @rb_stts: driver's pointer to receive buffer status
 * @rb_stts_dma: bus address of receive buffer status
 * @lock:
 *
 * NOTE:  rx_free and rx_used are used as a FIFO for iwl_rx_mem_buffers
 */
struct iwl_rxq {
} ;


//pcie/rx.c
iwl_pcie_irq_handler(int irq, void *dev_id) {
	struct iwl_trans *trans = dev_id;
	struct iwl_trans_pcie *trans_pcie = IWL_TRANS_GET_PCIE_TRANS(trans);

	//...
	
	// 所有来自uCode的cmd响应
	/* All uCode command responses, including Tx command responses,
	 * Rx "responses" (frame-received notification), and other
	 * notifications from uCode come through here*/
	if (inta & (CSR_INT_BIT_FH_RX | CSR_INT_BIT_SW_RX | CSR_INT_BIT_RX_PERIODIC)) {
		/* Sending RX interrupt require many steps to be done in the device:
		 * 1- write interrupt to current index in ICT table.
		 * 2- dma RX frame.
		 * 3- update RX shared data to indicate last write index.
		 * 4- send interrupt.
		 * This could lead to RX race, driver could receive RX interrupt
		 * but the shared data changes does not reflect this;
		 * periodic interrupt will detect any dangling Rx activity.
		 */

		//...

		iwl_pcie_rx_handle(trans) ;
	}
}


//pcie/trans.c
iwl_trans_pcie_alloc(pci_dev *pdev, pci_device_id *ent, iwl_cfg *cfg) {
	iwl_trans *trans = iwl_trans_alloc(sizeof(struct iwl_trans_pcie),
				&pdev->dev, cfg, &trans_ops_pcie, 0);
	iwl_trans_pcie *trans_pcie = IWL_TRANS_GET_PCIE_TRANS(trans);
	trans_pcie->trans = trans ;

	pci_enable_device(pdev) ;
	pci_set_master(pdev) ;
	pci_request_regions(pdev, DRV_NAME) ;
	trans_pcie->hw_base = pci_ioremap_bar(pdev, 0) ;
	pci_write_config_byte(pdev, PCI_CFG_RETRY_TIMEOUT, 0x00) ;

	pci_enable_msi(pdev) ;

	//...
	
	//key
	request_threaded_irq(pdev->irq, iwl_pcie_isr, iwl_pcie_irq_handler, 
			IRQF_SHARED, DRV_NAME, trans) ; 
}


//include/linux/interrupt.h
//kernel/irq/manage.c
//分配个中断
/**
 * request_threaded_irq - allocate an interrupt line
 * @irq: Interrupt line to allocate
 * @handler: Function to be called when the IRQ occurs.
 *           Primary handler for threaded interrupts
 *           If NULL and thread_fn != NULL the default
 *           primary handler is installed
 * @thread_fn: Function called from the irq handler thread
 *             If NULL, no irq thread is created
 * @irqflags: Interrupt type flags
 * @devname: An ascii name for the claiming device
 * @dev_id: A cookie passed back to the handler function
 *
 * This call allocates interrupt resources and enables the
 * interrupt line and IRQ handling. From the point this
 * call is made your handler function may be invoked. Since
 * your handler function must clear any interrupt the board
 * raises, you must take care both to initialise your hardware
 * and to set up the interrupt handler in the right order.
 *
 * If you want to set up a threaded irq handler for your device
 * then you need to supply @handler and @thread_fn. @handler is
 * still called in hard interrupt context and has to check
 * whether the interrupt originates from the device. If yes it
 * needs to disable the interrupt on the device and return
 * IRQ_WAKE_THREAD which will wake up the handler thread and run
 * @thread_fn. This split handler design is necessary to support
 * shared interrupts.
 *
 * Dev_id must be globally unique. Normally the address of the
 * device data structure is used as the cookie. Since the handler
 * receives this value it makes sense to use it.
 *
 * If your interrupt is shared you must pass a non NULL dev_id
 * as this is required when freeing the interrupt.
 *
 * Flags:
 *
 * IRQF_SHARED             Interrupt is shared
 * IRQF_TRIGGER_*          Specify active edge(s) or level
 *
 */
request_threaded_irq(unsigned int irq, irq_handler_t handler, irq_handler_t thread_fn, 
		unsigned long irqflags, const char *devname, void *dev_id) {

	action->handler = handler;
	action->thread_fn = thread_fn;
	action->flags = irqflags;
	action->name = devname;
	action->dev_id = dev_id;

	irq_to_desc(irq) ;
	irq_settings_can_request(desc) ;
	__setup_irq(irq, desc, action) ;
}









