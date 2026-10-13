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


#ifndef __BDMA_MODULE_H__
#define __BDMA_MODULE_H__

#include <linux/types.h>
#include <linux/module.h>
#include <linux/cdev.h>
#include <linux/dma-mapping.h>
#include <linux/delay.h>
#include <linux/fb.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/jiffies.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <linux/mm_types.h>
#include <linux/poll.h>
#include <linux/pci.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/vmalloc.h>
#include <linux/workqueue.h>
#include <linux/aio.h>
#include <linux/splice.h>
#include <linux/version.h>
#include <linux/uio.h>
#include <linux/spinlock_types.h>

#include "libbdma.h"
#include "bdma_thread.h"

#define MAGIC_ENGINE	0xEEEEEEEEUL
#define MAGIC_DEVICE	0xDDDDDDDDUL
#define MAGIC_CHAR	0xCCCCCCCCUL
#define MAGIC_BITSTREAM 0xBBBBBBBBUL

extern unsigned int desc_burst_max;
extern unsigned int tx_timeout;
extern unsigned int rx_timeout;

struct bdma_cdev {
	unsigned long magic;		/* structure ID for sanity checks */
	int bar;			/* PCIe BAR for HW access, if needed */
	unsigned long base;		/* bar access offset */	
	dev_t cdevno;			/* character device major:minor */
	struct bdma_pci_dev *ppdev;
	struct bdma_dev *pddev;
	struct cdev cdev;		/* character device embedded struct */
	struct bdma_engine *engine;	/* engine instance, if needed */
	struct bdma_usr_irq *usr_irq;	/* IRQ value, if needed */
	struct device *sys_device;	/* sysfs device */
	spinlock_t lock;
};

/* BDMA PCIe device specific book-keeping */
struct bdma_pci_dev {
	int major;		/* major number */
	int instance;		/* instance number */
	int user_max_event;
	int rx_chan_max;
	int tx_chan_max;
	unsigned long magic;		/* structure ID for sanity checks */	
	unsigned int flags;
	
	struct pci_dev *pdev;	/* pci device struct from probe() */
	struct bdma_dev *pddev;	

	/* character device structures */
	struct bdma_cdev ctrl_cdev;
	struct bdma_cdev sgdma_c2h_cdev[BDMA_CHAN_NUM_MAX];
	struct bdma_cdev sgdma_h2c_cdev[BDMA_CHAN_NUM_MAX];
	struct bdma_cdev events_cdev[16];

	struct bdma_cdev user_cdev;
	struct bdma_cdev bypass_c2h_cdev[BDMA_CHAN_NUM_MAX];
	struct bdma_cdev bypass_h2c_cdev[BDMA_CHAN_NUM_MAX];
	struct bdma_cdev bypass_cdev_base;

	struct bdma_cdev pvc_cdev;

	void *data;
};

struct cdev_async_io {
	bool write;
	bool cancel;
	int cmpl_cnt;
	int req_cnt;
	ssize_t res;
	ssize_t res2;
	int err_cnt;
	
	struct kiocb *iocb;
	struct bdma_io_cb *cb;	
	struct work_struct wrk_itm;
	struct cdev_async_io *next;	
	spinlock_t lock;

};

#endif /* ifndef __BDMA_MODULE_H__ */
