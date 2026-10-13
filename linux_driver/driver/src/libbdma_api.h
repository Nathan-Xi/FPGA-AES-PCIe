/*
 * This file is part of the Pango BDMA IP Core driver for Linux
 *
 * Copyright (c) 2016-present,  Xilinx, Inc.
 * All rights reserved.
 * Copyright (c) 2024-present,  Pango, Inc.
 * All rights reserved.
 *
 * 2024 Changes by Pango,Inc. : modify to support BDMA IP.
 *
 * This source code is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * The full GNU General Public License is included in this distribution in
 * the file called "COPYING".
 */


#ifndef __BDMA_BASE_API_H__
#define __BDMA_BASE_API_H__

#include <linux/types.h>
#include <linux/scatterlist.h>
#include <linux/interrupt.h>

/*
 * functions exported by the bdma driver
 */

typedef struct {
	u64 read_requested;
	u64 read_completed;
	u64 write_submitted;
	u64 write_completed;
	u64 open;
	u64 close;	
	u64 restart;
	u64 msix_trigger;
} bdma_statistics;

/*
 * This struct should be constantly updated by XMDA using u64_stats_* APIs
 * The front end will read the structure without locking (That's why updating atomically is a must)
 * every time it prints the statistics.
 */
//static BDMA_Statistics stats;

/* 
 * bdma_device_open - read the pci bars and configure the fpga
 *	should be called from probe()
 * 	NOTE:
 *		user interrupt will not enabled until bdma_user_isr_enable()
 *		is called
 * @pdev: ptr to pci_dev
 * @mod_name: the module name to be used for request_irq
 * @user_max: max # of user/event (interrupts) to be configured
 * @channel_max: max # of c2h and h2c channels to be configured
 * NOTE: if the user/channel provisioned is less than the max specified,
 *	 libbdma will update the user_max/channel_max
 * returns
 *	a opaque handle (for libbdma to identify the device)
 *	NULL, in case of error  
 */
void *bdma_device_open(const char *mod_name, struct pci_dev *pdev,
		 int *user_max, int *h2c_channel_max, int *c2h_channel_max);

/* 
 * bdma_device_close - prepare fpga for removal: disable all interrupts (users
 * and bdma) and release all resources
 *	should called from remove()
 * @pdev: ptr to struct pci_dev
 * @tuples: from bdma_device_open()
 */
void bdma_device_close(struct pci_dev *pdev, void *dev_handle);

/* 
 * bdma_device_restart - restart the fpga
 * @pdev: ptr to struct pci_dev
 * TODO:
 *	may need more refining on the parameter list
 * return < 0 in case of error
 * TODO: exact error code will be defined later
 */
int bdma_device_restart(struct pci_dev *pdev, void *dev_handle);

/*
 * bdma_eng_submit - submit data for dma operation (for both read and write)
 *	This is a blocking call
 * @channel: channle number (< channel_max)
 *	== channel_max means libbdma can pick any channel available:q

 * @dir: DMA_FROM/TO_DEVICE
 * @offset: offset into the DDR/BRAM memory to read from or write to
 * @sg_tbl: the scatter-gather list of data buffers
 * @timeout: timeout in mili-seconds, *currently ignored
 * return # of bytes transfered or
 *	 < 0 in case of error
 * TODO: exact error code will be defined later
 */
ssize_t bdma_eng_submit(void *dev_hndl, int channel, bool write, u64 ep_addr,
			struct sg_table *sgt, bool dma_mapped, int timeout_ms);

ssize_t bdma_eng_submit_nowait(void *cb_hndl, void *dev_hndl, int channel, bool write, u64 ep_addr,
			struct sg_table *sgt, bool dma_mapped, int timeout_ms);


ssize_t bdma_eng_completion(void *cb_hndl, void *dev_hndl, int channel, bool write, u64 ep_addr,
			struct sg_table *sgt, bool dma_mapped, int timeout_ms);


/*
 * bdma_user_isr_enable/disable - enable or disable user interrupt
 * @pdev: ptr to the the pci_dev struct	
 * @mask: bitmask of user interrupts (0 ~ 15)to be registered
 * return < 0 in case of error
 * TODO: exact error code will be defined later
 */
int bdma_user_isr_enable(void *dev_hndl, unsigned int mask);
int bdma_user_isr_disable(void *dev_hndl, unsigned int mask);


/*
 * bdma_user_isr_register - register a user ISR handler
 * It is expected that the bdma will register the ISR, and for the user
 * interrupt, it will call the corresponding handle if it is registered and
 * enabled.
 *
 * @pdev: ptr to the the pci_dev struct	
 * @mask: bitmask of user interrupts (0 ~ 15)to be registered
 *		bit 0: user interrupt 0
 *		...
 *		bit 15: user interrupt 15
 *		any bit above bit 15 will be ignored.
 * @handler: the correspoinding handler
 *		a NULL handler will be treated as de-registeration
 * @name: to be passed to the handler, ignored if handler is NULL`
 * @dev: to be passed to the handler, ignored if handler is NULL`
 * return < 0 in case of error
 * TODO: exact error code will be defined later
 */
int bdma_user_isr_register(void *dev_hndl, unsigned int mask,
			 irq_handler_t handler, void *dev);





			

/////////////////////missing API////////////////////

//bdma_get_channle_state - if no interrupt on DMA hang is available
//bdma_channle_restart

#endif
