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


#ifndef BDMA_LIB_H
#define BDMA_LIB_H

#include <linux/version.h>
#include <linux/types.h>
#include <linux/uaccess.h>
#include <linux/module.h>
#include <linux/dma-mapping.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/jiffies.h>
#include <linux/kernel.h>
#include <linux/pci.h>
#include <linux/workqueue.h>

/* Add compatibility checking for RHEL versions */

#if defined(RHEL_RELEASE_CODE)
#	define HAS_MMIOWB (RHEL_RELEASE_CODE <= RHEL_RELEASE_VERSION(8, 0))
#else
#	define HAS_MMIOWB (LINUX_VERSION_CODE <= KERNEL_VERSION(5, 1, 0))
#endif

#if defined(RHEL_RELEASE_CODE)
#	define HAS_SWAKE_UP_ONE (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 0))
#	define HAS_SWAKE_UP (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 0))
#else
#	define HAS_SWAKE_UP_ONE (LINUX_VERSION_CODE >= KERNEL_VERSION(4, 19, 0))
#	define HAS_SWAKE_UP (LINUX_VERSION_CODE >= KERNEL_VERSION(4, 6, 0))
#endif

#if defined(RHEL_RELEASE_CODE)
#	define ACCESS_OK_2_ARGS (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 0))
#else
#	define ACCESS_OK_2_ARGS (LINUX_VERSION_CODE >= KERNEL_VERSION(5, 0, 0))
#endif

#if defined(RHEL_RELEASE_CODE)
#	define PCI_AER_NAMECHANGE (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 3))
#else
#	define PCI_AER_NAMECHANGE (LINUX_VERSION_CODE >= KERNEL_VERSION(5, 7, 0))
#endif

#if	HAS_SWAKE_UP
#include <linux/swait.h>
#endif

/*
 *  if the config bar is fixed, the driver does not neeed to search through
 *  all of the bars
 */
//#define BDMA_CONFIG_BAR_NUM	1

/*channel max num*/
#define BDMA_CHAN_NUM_MAX (4)

/* SECTION: Preprocessor macros/constants */
#define BDMA_BAR_NUM (6)

/* maximum amount of register space to map */
#define BDMA_BAR_SIZE (0x8000UL)

/* Use this definition to poll several times between calls to schedule */
#define NUM_POLLS_PER_SCHED 100

/*rx status*/
#define RX_STATUS_EOP		(1)

/*
 * inters per engine, rad2_vul.sv:237
 * .REG_IRQ_OUT	(reg_irq_from_ch[(channel*2) +: 2]),
 */
#define BDMA_ENG_IRQ_NUM	(1)
#define BDMA_MAX_ADJ_BLOCK_SIZE	0x40
#define BDMA_PAGE_SIZE		0x1000

/* Target internal components on BDMA ctrl BAR */
#define BDMA_OFS_INT_CTRL	(0x2000UL)
#define BDMA_OFS_CONFIG		(0x3000UL)

#define TX_CHANNEL_OFFSET 0x1000
#define SGDMA_OFFSET_FROM_CHANNEL 0x4000
#define CHANNEL_SPACING 0x100
#define TARGET_SPACING 0x1000

#define BYPASS_MODE_SPACING 0x0100

/* maximum number of desc per transfer request */
#define BDMA_ENGINE_CREDIT_TRAN_MAX_DESC	0x3FF
#define BDMA_ENGINE_TRAN_MAX_DESC		0x800

/* maximum size of a single DMA transfer descriptor */
#define BDMA_DESC_BLEN_BITS	28
#define BDMA_DESC_BLEN_MAX	((1 << (BDMA_DESC_BLEN_BITS)) - 1)

/* bits of the SG DMA status register */
#define BDMA_STAT_BUSY				(1UL << 0)
#define BDMA_STAT_DESC_STOPPED		(1UL << 1)
#define BDMA_STAT_DESC_COMPLETED	(1UL << 2)
#define BDMA_STAT_ALIGN_MISMATCH	(1UL << 3)
#define BDMA_STAT_MAGIC_STOPPED		(1UL << 4)
#define BDMA_STAT_INVALID_LEN		(1UL << 5)
#define BDMA_STAT_IDLE_STOPPED		(1UL << 6)


/* bits of the SG DMA ctrl register */
#define BDMA_CTRL_RUN_STOP				(1UL << 0)
#define BDMA_CTRL_IE_DESC_STOPPED		(1UL << 1)
#define BDMA_CTRL_IE_DESC_COMPLETED		(1UL << 2)
#define BDMA_CTRL_IE_DESC_ALIGN_MISMATCH	(1UL << 3)
#define BDMA_CTRL_IE_MAGIC_STOPPED		(1UL << 4)
#define BDMA_CTRL_IE_IDLE_STOPPED		(1UL << 6)
#define BDMA_CTRL_IE_READ_ERROR			(0x1FUL << 9)
#define BDMA_CTRL_IE_DESC_ERROR			(0x1FUL << 19)
#define BDMA_CTRL_NON_INCR_ADDR			(1UL << 25)
#define BDMA_CTRL_POLL_MODE_WB			(1UL << 26)
#define BDMA_CTRL_STM_MODE_WB			(1UL << 27)



#define BDMA_STAT_COMMON_ERR_MASK \
	(BDMA_STAT_ALIGN_MISMATCH | BDMA_STAT_MAGIC_STOPPED | BDMA_STAT_INVALID_LEN)



/* read error: TX */
#define BDMA_STAT_TX_R_UNSUPP_REQ	(1UL << 9)
#define BDMA_STAT_TX_R_COMPL_ABORT	(1UL << 10)
#define BDMA_STAT_TX_R_PARITY_ERR	(1UL << 11)
#define BDMA_STAT_TX_R_HEADER_EP	(1UL << 12)
#define BDMA_STAT_TX_R_UNEXP_COMPL	(1UL << 13)

#define BDMA_STAT_TX_R_ERR_MASK	\
	(BDMA_STAT_TX_R_UNSUPP_REQ | BDMA_STAT_TX_R_COMPL_ABORT | \
	 BDMA_STAT_TX_R_PARITY_ERR | BDMA_STAT_TX_R_HEADER_EP | \
	 BDMA_STAT_TX_R_UNEXP_COMPL)

/* write error, TX only */
#define BDMA_STAT_TX_W_DECODE_ERR	(1UL << 14)
#define BDMA_STAT_TX_W_SLAVE_ERR	(1UL << 15)

#define BDMA_STAT_TX_W_ERR_MASK	\
	(BDMA_STAT_TX_W_DECODE_ERR | BDMA_STAT_TX_W_SLAVE_ERR)

/* read error: RX */
#define BDMA_STAT_RX_R_DECODE_ERR	(1UL << 9)
#define BDMA_STAT_RX_R_SLAVE_ERR	(1UL << 10)

#define BDMA_STAT_RX_R_ERR_MASK	\
	(BDMA_STAT_RX_R_DECODE_ERR | BDMA_STAT_RX_R_SLAVE_ERR)

/* desc_error, RX & TX */
#define BDMA_STAT_DESC_UNSUPP_REQ	(1UL << 19)
#define BDMA_STAT_DESC_COMPL_ABORT	(1UL << 20)
#define BDMA_STAT_DESC_PARITY_ERR	(1UL << 21)
#define BDMA_STAT_DESC_HEADER_EP	(1UL << 22)
#define BDMA_STAT_DESC_UNEXP_COMPL	(1UL << 23)

#define BDMA_STAT_DESC_ERR_MASK	\
	(BDMA_STAT_DESC_UNSUPP_REQ | BDMA_STAT_DESC_COMPL_ABORT | \
	 BDMA_STAT_DESC_PARITY_ERR | BDMA_STAT_DESC_HEADER_EP | \
	 BDMA_STAT_DESC_UNEXP_COMPL)


/* all combined */
#define BDMA_STAT_TX_ERR_MASK	\
	(BDMA_STAT_COMMON_ERR_MASK | BDMA_STAT_DESC_ERR_MASK | \
	 BDMA_STAT_TX_R_ERR_MASK | BDMA_STAT_TX_W_ERR_MASK)

#define BDMA_STAT_RX_ERR_MASK	\
	(BDMA_STAT_COMMON_ERR_MASK | BDMA_STAT_DESC_ERR_MASK | \
	 BDMA_STAT_RX_R_ERR_MASK)



/* bits of the SGDMA descriptor ctrl field */

#define BDMA_PERF_RUN	(1UL << 0)
#define BDMA_PERF_CLEAR	(1UL << 1)
#define BDMA_PERF_AUTO	(1UL << 2)

#define BDMA_DESC_STOPPED	(1UL << 0)
#define BDMA_DESC_COMPLETED	(1UL << 1)
#define BDMA_DESC_EOP		(1UL << 4)

/*magic macro*/
#define MAGIC_ENGINE	0xEEEEEEEEUL
#define MAGIC_DEVICE	0xDDDDDDDDUL

//#define DESC_MAGIC 0xAD4B0000UL
#define DESC_MAGIC 0xCB2D0000UL
#define MAX_DESC_BUS_ADDR (0xffffffffULL)

#define MAX_NUM_ENGINES (BDMA_CHAN_NUM_MAX * 2)


/* upper 16-bits of engine eng_id register */
#define BDMA_ID_TX 0x8030U
#define BDMA_ID_RX 0x8031U

/* for RX AXI-ST mode */
#define CYCLIC_RX_PAGES_MAX	256

#define LS_BYTE_MASK 0x000000FFUL

#define BLOCK_ID_HEAD 0x80300000
#define BLOCK_ID_MASK 0xFFF00000


#define IRQ_BLOCK_ID 0x80320000UL
#define CONFIG_BLOCK_ID 0x80330000UL

#define RX_WB 0x52B4UL

#define WB_COUNT_MASK 0x00ffffffUL
#define WB_ERR_MASK (1UL << 31)

#define POLL_TIMEOUT_SECONDS 10

#define MAX_USER_IRQ 16


/* obtain the 32 most significant (high) bits of a 32-bit or 64-bit address */
#define PCI_DMA_H(addr) ((addr >> 16) >> 16)
/* obtain the 32 least significant (low) bits of a 32-bit or 64-bit address */

#define PCI_DMA_L(addr) (addr & 0xffffffffUL)

/* Describes a (SG DMA) single transfer for the engine */
#define TRAN_FLAG_NEED_UNMAP		0x1
#define TRAN_FLAG_ST_RX_EOP_RCVED	0x2	/* ST RX only */ 


#ifndef VM_RESERVED
	#define VMEM_FLAGS (VM_IO | VM_DONTEXPAND | VM_DONTDUMP)
#else
	#define VMEM_FLAGS (VM_IO | VM_RESERVED)
#endif

#ifdef __LIBBDMA_DEBUG__
#define dbg_init	pr_err
#define dbg_fops	pr_err
#define dbg_io		pr_err
#define dbg_irq		pr_err
#define dbg_desc	pr_err
#define dbg_tfr		pr_err
#define dbg_sg		pr_err
#define dbg_perf	pr_err
#else
/* disable debugging */
#define dbg_init(...)
#define dbg_fops(...)
#define dbg_io(...)
#define dbg_irq(...)
#define dbg_desc(...)
#define dbg_tfr(...)
#define dbg_sg(...)
#define dbg_perf(...)
#endif

/* SECTION: Enum definitions */
enum shutdown_state {
	ENGINE_SHUTDOWN_NONE = 0,	/* No shutdown in progress */
	ENGINE_SHUTDOWN_REQUEST = 1,	/* engine requested to shutdown */
	ENGINE_SHUTDOWN_IDLE = 2	/* engine has shutdown and is idle */
};

enum transfer_state {
	TRANS_STATE_NEW = 0,
	TRANS_STATE_SUBMITTED,
	TRANS_STATE_COMPLETED,
	TRANS_STATE_FAILED,
	TRANS_STATE_ABORTED
};

enum dev_caps {
	CAP_64BIT_DMA = 2,
	CAP_64BIT_DESC = 4,
	CAP_ENGINE_WRITE = 8,
	CAP_ENGINE_READ = 16
};

/* SECTION: Structure definitions */

struct bdma_io_cb {
	size_t len;
	unsigned int pages_nr;
	/** total data size */
	unsigned int count;
	/** MM only, DDR/BRAM memory addr */
	u64 ep_addr;
	void __user *buf;	
	void *private;	
	struct sg_table sgt;
	struct page **pages;	

	/** write: if write to the device */
	struct bdma_request_cb *req;
	u8 write:1;
	void (*io_done)(unsigned long cb_hndl, int err);
};

struct config_regs {
	u32 eng_id;
	u32 res_1[4];
	u32 msi_enable;
};

struct engine_sgdma_regs {
	u32 eng_id;
	u32 res_1[31];	/* padding */

	/* bus address to first descriptor in Root Complex Memory */
	u32 first_desc_lo;
	u32 first_desc_hi;
	/* number of adjacent descriptors at first_desc */
	u32 first_desc_adj;
	u32 credits;
} __packed;


/**
 * SG DMA Controller status and ctrl registers
 *
 * These registers make the ctrl interface for DMA transfers.
 *
 * It sits in End Point (FPGA) memory BAR[0] for 32-bit or BAR[0:1] for 64-bit.
 * It references the first descriptor which exists in Root Complex (PC) memory.
 *
 * @note The registers must be accessed using 32-bit (PCI DWORD) read/writes,
 * and their values are in little-endian byte ordering.
 */
struct engine_regs {
	u32 eng_id;
	u32 ctrl;
	u32 ctrl_wts;
	u32 ctrl_wtc;
	u32 res_1[12];	/* padding */

	u32 status;
	u32 status_rc;
	u32 comp_desc_cnt;
	u32 align;
	u32 res_2[14];	/* padding */

	u32 poll_wb_lo;
	u32 poll_wb_hi;
	u32 intr_en_mask_hi;
	u32 intr_en_mask_hi_wts;
	u32 intr_en_mask_hi_wtc;
	u32 res_3[9];	/* padding */

	u32 perf_ctrl;
	u32 perf_cyc_lo;
	u32 perf_cyc_hi;
	u32 perf_dat_lo;
	u32 perf_dat_hi;
	u32 perf_pnd_lo;
	u32 perf_pnd_hi;
} __packed;

struct intr_regs {
	u32 eng_id;
	u32 usr_int_en;
	u32 usr_int_en_wts;
	u32 usr_int_en_wtc;
	u32 chan_int_en;
	u32 chan_int_en_wts;
	u32 chan_int_en_wtc;
	u32 res_1[9];	/* padding */

	u32 usr_int_req;
	u32 chan_int_req;
	u32 usr_int_pend;
	u32 chan_int_pend;
	u32 res_2[12];	/* padding */

	u32 usr_msi_vec[8];
	u32 chan_msi_vec[8];
} __packed;

struct sgdma_common_regs {
	u32 padding[8];
	u32 credit_mode_enable;
	u32 credit_mode_en_wts;
	u32 credit_mode_en_wtc;
} __packed;

struct msix_vec_table_entry {
	u32 msi_vec_addr_lo;
	u32 msi_vec_addr_hi;
	u32 msi_vec_data_lo;
	u32 msi_vec_data_hi;
} __packed;

struct msix_vec_table {
	struct msix_vec_table_entry entry_list[32];
} __packed;



/* Structure for polled mode descriptor writeback */
struct bdma_poll_wb {
	u32 comp_desc_cnt;
	u32 res_1[7];
} __packed;


/**
 * Descriptor for a single contiguous memory block transfer.
 *
 * Multiple descriptors are linked by means of the next pointer. An additional
 * extra adjacent number gives the amount of extra contiguous descriptors.
 *
 * The descriptors are in root complex memory, and the bytes in the 32-bit
 * words must be in little-endian byte ordering.
 */
struct bdma_desc {
	u32 ctrl;
	u32 bytes;		/* transfer length in bytes */
	u32 src_addr_lo;	/* source address (low 32-bit) */
	u32 src_addr_hi;	/* source address (high 32-bit) */
	u32 dst_addr_lo;	/* destination address (low 32-bit) */
	u32 dst_addr_hi;	/* destination address (high 32-bit) */
	/*
	 * next descriptor in the single-linked list of descriptors;
	 * this is the PCIe (bus) address of the next descriptor in the
	 * root complex memory
	 */
	u32 next_lo;		/* next desc address (low 32-bit) */
	u32 next_hi;		/* next desc address (high 32-bit) */
} __packed;

struct sw_desc {
	dma_addr_t addr;
	unsigned int len;
};


/* 32 bytes (four 32-bit words) or 64 bytes (eight 32-bit words) */
struct bdma_result {
	u32 status;
	u32 length;
	u32 res_1[6];	/* padding */
} __packed;

struct bdma_transfer {	
	enum dma_data_direction dir;	
	enum transfer_state state;	/* state of the transfer */
	int desc_adj;		/* adjacent descriptors at desc_bus */
	int desc_num;			/* number of descriptors in transfer */
	int desc_index;			/* index for 1st desc. in transfer */
	int desc_comp;			/* completed descriptors */
	int desc_comp_th;		/* completed descriptor threshold */	
	unsigned int flags;
	int cyclic;			/* flag if transfer is cyclic */
	int last_in_req;		/* flag if last within request */
	unsigned int len;	
	dma_addr_t res_bus;		/* bus addr for result descriptors */
	dma_addr_t desc_bus;		/* bus addr of the first descriptor */	
	struct list_head entry;		/* queue of non-completed transfers */
	struct bdma_desc *desc_virt;	/* virt addr of the 1st descriptor */
	struct bdma_result *res_virt;   /* virt addr of result, RX streaming */
#if	HAS_SWAKE_UP
	struct swait_queue_head wq;
#else
	wait_queue_head_t wq;		/* wait queue for transfer completion */
#endif
	struct sg_table *sgt;
	struct bdma_io_cb *cb;
};

struct bdma_request_cb {		
	unsigned int aperture;
	unsigned int total_len;
	unsigned int offset;
	unsigned int sg_idx;
	unsigned int sg_off;
	unsigned int sw_desc_idx;
	unsigned int sw_desc_cnt;
	u64 ep_addr;
	struct sg_table *sgt;
	struct scatterlist *sg;
	/* Use two transfers in case single request needs to be split */
	struct bdma_transfer tfer[2];
	struct bdma_io_cb *cb;
	struct sw_desc sdesc[0];
};

struct bdma_engine {
	/* Engine state, configuration and flags */
	enum shutdown_state shutdown;	/* engine shutdown mode */
	enum dma_data_direction dir;
	u8 addr_align;		/* source/dest alignment in bytes */
	u8 len_of_granu;	/* transfer length multiple */
	u8 addr_bits;		/* HW datapath address width */
	u8 channel:2;		/* engine indices */
	u8 streaming:1;
	u8 device_open:1;	/* flag if engine node open, ST mode only */
	u8 running:1;		/* flag if the driver started engine */
	u8 no_inc_addr:1;	/* flag if non-incremental addressing used */
	u8 eop_flush:1;		/* st RX only, flush up the data with eop */
	u8 filler:1;
	
	char name[16];		/* name of this engine */
	int version;		/* version of this engine */
	int max_ext_adj;	/* descriptor prefetch capability */
	int desc_dequeued;	/* num descriptors of completed transfers */
	int prev_cpu;			/* remember CPU# of (last) locker */
	int msix_irq_line;		/* MSI-X vector for this engine */
	int desc_idx;			/* current descriptor index */
	int desc_used;			/* total descriptors used */
	u32 irq_bitmask;		/* IRQ bit mask for this engine */
	u32 desc_max;		/* max # descriptors per eng */
	u32 status;		/* last known status of device */
	/* cpu attached to intr_work */
	unsigned int intr_work_cpu;
	
	/* only used for MSIX mode to store per-engine inter mask value */
	u32 intr_en_mask_value;
	unsigned long magic;	/* structure ID for sanity checks */
	u32 byp_off;			/* Bypass mode BAR offset */
	dma_addr_t cyc_res_bus;	/* bus addr for transfer */
	dma_addr_t perf_buf_bus; /* bus address */
	dma_addr_t poll_bus_addr;	/* bus addr for descriptor writeback */

	u8 *perf_buf_virt;
	/* Members associated with polled mode support */
	u8 *poll_addr_virt;	/* virt addr for descriptor writeback */
	
	struct bdma_dev *pddev;	/* parent device */	
	/* HW register address offsets */
	struct engine_regs *regs;		/* Control reg BAR offset */
	struct engine_sgdma_regs *sgdma_regs;	/* SGDAM reg BAR offset */

	/* Transfer list management */
	struct list_head trans_list;	/* queue of transfers */

	/* Members applicable to AXI-ST RX (cyclic) transfers */
	struct bdma_result *cyc_res;
	/* Members associated with inter mode support */
#if	HAS_SWAKE_UP
	struct swait_queue_head shutdown_wq;
#else
	wait_queue_head_t shutdown_wq;	/* wait queue for shutdown sync */
#endif
	spinlock_t lock;		/* protects concurrent access */
	
	struct work_struct work;	/* Work queue for inter handling */

	struct mutex desc_lock;		/* protects concurrent access */
	dma_addr_t desc_bus;
	struct bdma_desc *desc;
	

	/* for performance test support */
	struct bdma_performance_ioctl *bdma_perf;	/* perf test ctrl */
#if	HAS_SWAKE_UP
	struct swait_queue_head bdma_perf_wq;
#else
	wait_queue_head_t bdma_perf_wq;	/* Perf test sync */
#endif

	struct bdma_kthread *compthp;
	/* completion status thread list for the queue */
	struct list_head compthp_list;
	/* pending work thread list */

};

struct bdma_usr_irq {
	u8 user_idx;			/* 0 ~ 15 */
	u8 events_irq;			/* accumulated IRQs */
	spinlock_t events_lock;		/* lock to safely update events_irq */
	wait_queue_head_t events_wq;	/* wait queue to sync waiting threads */
	irq_handler_t handler;
	struct bdma_dev *pddev;		/* parent device */
	void *dev;
};

/* BDMA PCIe device specific book-keeping */
#define PDEV_FLAG_OFFLINE	0x1
struct bdma_dev {
	int idx;		/* dev index */		
	int usr_bar_idx;	/* BAR index of user logic */
	int cfg_bar_idx; /* BAR index of BDMA config logic */
	int byp_bar_idx; /* BAR index of BDMA bypass logic */
	int dev_is_use; /* flag if dev was in use during probe() */
	int got_dev;	/* flag if probe() obtained the regions */
	int user_max_event;
	int rx_chan_max;
	int tx_chan_max;

	/* Interrupt management */
	int irq_cnt;		/* inter counter */
	int irq_line;		/* flag if irq allocated successfully */
	int msi_en;	/* flag if msi was enabled for the device */
	int msix_en;	/* flag if msi-x was enabled for the device */

	/* BDMA engine management */
	int eng_cnt;	/* Total engine count */
	u32 mask_irq_tx;
	u32 mask_irq_rx;
		
	unsigned long magic;		/* structure ID for sanity checks */	
	unsigned int flags;	
	unsigned int mask_irq_usr;

	/* SD_Accel specific */
	enum dev_caps caps;
	u64 feat_id;
	
	struct list_head list_head;
	struct list_head rcu_node;
	struct pci_dev *pdev;	/* pci device struct from probe() */


	const char *mod_name;		/* name of module owning the dev */

	spinlock_t lock;		/* protects concurrent access */

	/* PCIe BAR management */
	void __iomem *bar[BDMA_BAR_NUM];	/* addresses for mapped BARs */
	


	
#if KERNEL_VERSION(4, 12, 0) > LINUX_VERSION_CODE
	struct msix_entry entry[32];	/* msi-x vector/entry table */
#endif
	struct bdma_usr_irq usr_irq[16];	/* user IRQ management */

	
	struct bdma_engine eng_tx[BDMA_CHAN_NUM_MAX];
	struct bdma_engine eng_rx[BDMA_CHAN_NUM_MAX];


};

static inline int bdma_device_flag_check(struct bdma_dev *pddev, unsigned int f)
{
	unsigned long flags;

	spin_lock_irqsave(&pddev->lock, flags);
	if (pddev->flags & f) {
		spin_unlock_irqrestore(&pddev->lock, flags);
		return 1;
	}
	spin_unlock_irqrestore(&pddev->lock, flags);
	return 0;
}

static inline void bdma_device_flag_set(struct bdma_dev *pddev, unsigned int f)
{
	unsigned long flags;

	spin_lock_irqsave(&pddev->lock, flags);
	pddev->flags |= f;
	spin_unlock_irqrestore(&pddev->lock, flags);
}

static inline void bdma_device_flag_clear(struct bdma_dev *pddev, unsigned int f)
{
	unsigned long flags;

	spin_lock_irqsave(&pddev->lock, flags);
	pddev->flags &= ~f;
	spin_unlock_irqrestore(&pddev->lock, flags);
}

static inline int bdma_device_flag_test_n_set(struct bdma_dev *pddev,
					 unsigned int f)
{
	unsigned long flags;
	int rv = 0;

	spin_lock_irqsave(&pddev->lock, flags);
	if (pddev->flags & f) {
		spin_unlock_irqrestore(&pddev->lock, flags);
		rv = 1;
	} else
		pddev->flags |= f;
	spin_unlock_irqrestore(&pddev->lock, flags);
	return rv;
}

void write_register(u32 value, void *iomem);
u32 read_register(void *iomem);

struct bdma_dev *pdev_find_by_pdev(struct pci_dev *pdev);

void enable_perf(struct bdma_engine *engine);
void get_perf_stats(struct bdma_engine *engine);

void bdma_device_online(struct pci_dev *pdev, void *dev_handle);
void bdma_device_offline(struct pci_dev *pdev, void *dev_handle);

int bdma_performance_submit(struct bdma_dev *pddev, struct bdma_engine *engine);
ssize_t bdma_eng_aperture(struct bdma_engine *engine, bool write, u64 ep_addr,
			unsigned int aperture, struct sg_table *sgt,
			bool dma_mapped, int timeout_ms);

int eng_service_poll(struct bdma_engine *engine, u32 expected_desc_count);
int eng_mode_set(struct bdma_engine *engine, unsigned long arg);
struct bdma_transfer *eng_cyclic_stop(struct bdma_engine *engine);

#endif /* BDMA_LIB_H */
