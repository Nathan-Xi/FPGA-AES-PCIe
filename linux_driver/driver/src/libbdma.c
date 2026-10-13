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


#define pr_fmt(fmt) KBUILD_MODNAME ":%s: " fmt, __func__

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/string.h>
#include <linux/errno.h>
#include <linux/sched.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>

#include "dev_sgdma.h"
#include "bdma_thread.h"
#include "libbdma.h"
#include "libbdma_api.h"



/* define Module Parameters */
unsigned int desc_burst_max = BDMA_DESC_BLEN_MAX;

static unsigned int inter_mode;
module_param(inter_mode, uint, 0644);
MODULE_PARM_DESC(inter_mode, "0 - Auto , 1 - MSI, 2 - Legacy, 3 - MSI-x");

static unsigned int poll_mode;
module_param(poll_mode, uint, 0644);
MODULE_PARM_DESC(poll_mode, "Set 1 for hw polling, default is 0 (interrupts)");

static unsigned int en_st_rx_credit = 0;
module_param(en_st_rx_credit, uint, 0644);
MODULE_PARM_DESC(en_st_rx_credit,
	"Set 1 to enable ST RX engine credit feature, default is 0 ( credit ctrl disabled)");

module_param(desc_burst_max, uint, 0644);
MODULE_PARM_DESC(desc_burst_max,
		 "per descriptor max. buffer length, default is (1 << 28) - 1");

/*perf test num desc*/
#define BDMA_PERF_NUM_DESC 128

/* Kernel version adaptative */
#if HAS_SWAKE_UP_ONE
/* since 4.18, using simple wait queues is not recommended
 * except for realtime constraint (see swait.h comments)
 * and will likely be removed in future kernel versions
 */
#define pg_wake_up	swake_up_one
#define pg_wait_event_interruptible_timeout \
			swait_event_interruptible_timeout_exclusive
#define pg_wait_event_interruptible \
			swait_event_interruptible_exclusive
#elif HAS_SWAKE_UP
#define pg_wake_up	swake_up
#define pg_wait_event_interruptible_timeout \
			swait_event_interruptible_timeout
#define pg_wait_event_interruptible \
			swait_event_interruptible
#else
#define pg_wake_up	wake_up_interruptible
/* wait_event_interible_timeout() could return prematurely (-ERESTARTSYS)
 * if it is intered by a signal */
#define pg_wait_event_interruptible_timeout(wq, condition, timeout) \
({\
	int __ret = 0;  \
	unsigned long expire = timeout + jiffies; \
	do { \
		__ret = wait_event_interruptible_timeout(wq, condition, \
							timeout); \
	} while ((__ret < 0) && (jiffies < expire)); \
       __ret; \
})
#define pg_wait_event_interruptible \
			wait_event_interruptible
#endif


/*
 * bdma device management
 * maintains a list of the bdma devices
 */
 
static DEFINE_MUTEX(pdev_mutex);
static LIST_HEAD(pdev_list);

static DEFINE_SPINLOCK(pdev_rcu_lock);
static LIST_HEAD(pdev_rcu_list);

#ifndef list_last_entry
#define list_last_entry(ptr, type, member) list_entry((ptr)->prev, type, member)
#endif

struct bdma_dev *pdev_find_by_pdev(struct pci_dev *pdev)
{
	struct bdma_dev *pddev, *tmp;

	mutex_lock(&pdev_mutex);
	
	list_for_each_entry_safe(pddev, tmp, &pdev_list, list_head) {
		if (pddev->pdev == pdev) {
			mutex_unlock(&pdev_mutex);
			return pddev;
		}
	}
	
	mutex_unlock(&pdev_mutex);
	return NULL;
}

static inline int pdev_list_add(struct bdma_dev *pddev)
{
    int ret;
	struct bdma_dev *last;
	
	mutex_lock(&pdev_mutex);
	
	if (list_empty(&pdev_list)) {
		pddev->idx = 0;
		if (poll_mode) {
			ret = bdma_threads_create(pddev->tx_chan_max + pddev->rx_chan_max);
			if (ret < 0) {
				mutex_unlock(&pdev_mutex);
				return ret;
			}
		}
	} else {
		last = list_last_entry(&pdev_list, struct bdma_dev, list_head);
		pddev->idx = last->idx + 1;
	}
	
	list_add_tail(&pddev->list_head, &pdev_list);
	mutex_unlock(&pdev_mutex);

	dbg_init("dev %s, pddev 0x%p, bdma idx %d.\n",dev_name(&pddev->pdev->dev), pddev, pddev->idx);

	spin_lock(&pdev_rcu_lock);
	list_add_tail_rcu(&pddev->rcu_node, &pdev_rcu_list);
	spin_unlock(&pdev_rcu_lock);

	return 0;
}

#undef list_last_entry

static inline void pdev_list_move(struct bdma_dev *pddev)
{
	mutex_lock(&pdev_mutex);	
	
	list_del(&pddev->list_head);
	
	if (poll_mode && list_empty(&pdev_list)) {
		bdma_threads_destroy();
	}	
	
	mutex_unlock(&pdev_mutex);

	spin_lock(&pdev_rcu_lock);
	list_del_rcu(&pddev->rcu_node);
	spin_unlock(&pdev_rcu_lock);
	
	synchronize_rcu();
}

static inline int debug_check_dev_hw(const char *fname, struct pci_dev *pdev,
				       void *hw_dev)
{
	struct bdma_dev *pddev;

	if (!pdev)
		return -EINVAL;

	pddev = pdev_find_by_pdev(pdev);
	if (!pddev) {
		pr_info("%s pddev 0x%p, hndl 0x%p, NO match found!\n", fname, pdev, hw_dev);
		return -EINVAL;
	}
	if (pddev != hw_dev) {
		pr_err("%s pddev 0x%p, hndl 0x%p != 0x%p!\n", fname, pdev, hw_dev, pddev);
		return -EINVAL;
	}

	return 0;
}

#ifdef __LIBBDMA_DEBUG__
/* SECTION: Function definitions */
inline void __write_reg(const char *fn, u32 value, void *iomem,
			     unsigned long off)
{
	pr_err("%s: tmp reg 0x%lx(0x%p), 0x%x.\n", fn, off, iomem, value);
	iowrite32(value, iomem);
}
#define write_reg(v, mem, off) __write_reg(__func__, v, mem, off)
#else
#define write_reg(v, mem, off) iowrite32(v, mem)
#endif

inline u32 read_reg(void *iomem)
{
	return ioread32(iomem);
}

static inline u32 build_u32(u32 hi, u32 lo)
{
	return ((hi & 0xFFFFUL) << 16) | (lo & 0xFFFFUL);
}

static inline u64 build_u64(u64 hi, u64 lo)
{
	return ((hi & 0xFFFFFFFULL) << 32) | (lo & 0xFFFFFFFFULL);
}

static void check_intr_status(struct bdma_dev *pddev)
{
	struct intr_regs *reg;	
	u32 tmp;
	
	reg = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);
	
	tmp = read_reg(&reg->chan_int_en);
	if (tmp)
		pr_info("%s bdma%d chan_int_en = 0x%08x\n",
			dev_name(&pddev->pdev->dev), pddev->idx, tmp);

	tmp = read_reg(&reg->usr_int_en);
	if (tmp)
		pr_info("%s bdma%d usr_int_en = 0x%08x\n",
			dev_name(&pddev->pdev->dev), pddev->idx, tmp);


	tmp = read_reg(&reg->chan_int_req);
	if (tmp)
		pr_info("%s bdma%d chan_int_req = 0x%08x\n",
			dev_name(&pddev->pdev->dev), pddev->idx, tmp);

	tmp = read_reg(&reg->usr_int_req);
	if (tmp)
		pr_info("%s bdma%d usr_int_req = 0x%08x\n",
			dev_name(&pddev->pdev->dev), pddev->idx, tmp);

	tmp = read_reg(&reg->chan_int_pend);
	if (tmp)
		pr_info("%s bdma%d chan_int_pend = 0x%08x\n",
			dev_name(&pddev->pdev->dev), pddev->idx, tmp);

	tmp = read_reg(&reg->usr_int_pend);
	if (tmp)
		pr_info("%s bdma%d usr_int_pend = 0x%08x\n",
			dev_name(&pddev->pdev->dev), pddev->idx, tmp);
}

/* channel_inters_enable -- Enable inters we are interested in */
static void chan_intr_enable(struct bdma_dev *pddev, u32 mask)
{
	struct intr_regs *reg;
	reg =(struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);
	write_reg(mask, &reg->chan_int_en_wts, BDMA_OFS_INT_CTRL);
}

/* channel_inters_disable -- Disable inters we not interested in */
static void chan_intr_disable(struct bdma_dev *pddev, u32 mask)
{
	struct intr_regs *reg;	
	reg = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);
	write_reg(mask, &reg->chan_int_en_wtc, BDMA_OFS_INT_CTRL);
}

/* user_inters_enable -- Enable inters we are interested in */
static void usr_intr_enable(struct bdma_dev *pddev, u32 mask)
{
	struct intr_regs *reg;		
	reg = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);
	write_reg(mask, &reg->usr_int_en_wts, BDMA_OFS_INT_CTRL);
}

/* user_inters_disable -- Disable inters we not interested in */
static void usr_intr_disable(struct bdma_dev *pddev, u32 mask)
{
	struct intr_regs *reg;	
	reg = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);
	write_reg(mask, &reg->usr_int_en_wtc, BDMA_OFS_INT_CTRL);
}

/* read_inters -- Print the inter ctrller status */
static u32 read_interrupts(struct bdma_dev *pddev)
{
	struct intr_regs *reg;
	u32 lo;
	u32 hi;
	
	reg = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);

	/* extra debugging; inspect complete engine set of registers */
	hi = read_reg(&reg->usr_int_req);
	dbg_io("ioread32(0x%p) returned 0x%08x (usr_int_req).\n",
	       &reg->usr_int_req, hi);
	lo = read_reg(&reg->chan_int_req);
	dbg_io("ioread32(0x%p) returned 0x%08x (chan_int_req)\n",
	       &reg->chan_int_req, lo);

	/* return inters: user in upper 16-bits, channel in lower 16-bits */
	return build_u32(hi, lo);
}

void enable_perf(struct bdma_engine *engine)
{
	u32 tmp;
	
	tmp = BDMA_PERF_CLEAR;
	write_reg(tmp, &engine->regs->perf_ctrl,
		       (unsigned long)(&engine->regs->perf_ctrl) -
			       (unsigned long)(&engine->regs));
	read_reg(&engine->regs->eng_id);
	tmp = BDMA_PERF_AUTO | BDMA_PERF_RUN;
	write_reg(tmp, &engine->regs->perf_ctrl,
		       (unsigned long)(&engine->regs->perf_ctrl) -
			       (unsigned long)(&engine->regs));
	read_reg(&engine->regs->eng_id);

	dbg_perf("IOCTL_BDMA_PERF_START\n");
}

void get_perf_stats(struct bdma_engine *engine)
{
	u32 hi;
	u32 lo;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return;
	}

	if (!engine->bdma_perf) {
		pr_info("%s perf struct not set up.\n", engine->name);
		return;
	}

	hi = 0;
	lo = read_reg(&engine->regs->comp_desc_cnt);
	engine->bdma_perf->iterations = build_u64(hi, lo);

	hi = read_reg(&engine->regs->perf_cyc_hi);
	lo = read_reg(&engine->regs->perf_cyc_lo);

	engine->bdma_perf->clock_cycle_count = build_u64(hi, lo);

	hi = read_reg(&engine->regs->perf_dat_hi);
	lo = read_reg(&engine->regs->perf_dat_lo);
	engine->bdma_perf->data_cycle_count = build_u64(hi, lo);

	hi = read_reg(&engine->regs->perf_pnd_hi);
	lo = read_reg(&engine->regs->perf_pnd_lo);
	engine->bdma_perf->pending_count = build_u64(hi, lo);
}

static irqreturn_t usr_irq_service(int irq, struct bdma_usr_irq *usr_irq)
{
	unsigned long flags;

	if (!usr_irq) {
		pr_err("Invalid usr_irq\n");
		return IRQ_NONE;
	}

	if (usr_irq->handler)
		return usr_irq->handler(usr_irq->user_idx, usr_irq->dev);

	spin_lock_irqsave(&(usr_irq->events_lock), flags);
	if (!usr_irq->events_irq) {
		usr_irq->events_irq = 1;
		wake_up_interruptible(&(usr_irq->events_wq));
	}
	spin_unlock_irqrestore(&(usr_irq->events_lock), flags);

	return IRQ_HANDLED;
}


static int is_config_bar(struct bdma_dev *pddev, int idx)
{	
	int flag = 0;
	u32 irq_id = 0;
	u32 cfg_id = 0;
	/* Compare only BDMA ID's not Version number */
	u32 mask = 0xffff0000; 
	
	struct intr_regs *irq_regs =
		(struct intr_regs *)(pddev->bar[idx] + BDMA_OFS_INT_CTRL);
	struct config_regs *cfg_regs =
		(struct config_regs *)(pddev->bar[idx] + BDMA_OFS_CONFIG);

	irq_id = read_reg(&irq_regs->eng_id);
	cfg_id = read_reg(&cfg_regs->eng_id);

        pr_info("irq_id 0x%x cfg_id 0x%x\n",irq_id,cfg_id);

	if (((irq_id & mask) == IRQ_BLOCK_ID) &&
	    ((cfg_id & mask) == CONFIG_BLOCK_ID)) {
		dbg_init("BAR %d is a BDMA config BAR\n", idx);
		pr_info("BAR %d is a BDMA config BAR\n", idx);
		flag = 1;
	} else {
		dbg_init("BAR %d is not a BDMA config BAR: 0x%x, 0x%x.\n",
			 idx, irq_id, cfg_id);
		pr_info("BAR %d is not a BDMA config BAR: 0x%x, 0x%x.\n",
			 idx, irq_id, cfg_id);
		flag = 0;
	}

	return flag;
}

static int map_single_bar(struct bdma_dev *pddev, struct pci_dev *pdev, int idx)
{
	resource_size_t bar_start;
	resource_size_t bar_len;
	resource_size_t map_len;

	bar_start = pci_resource_start(pdev, idx);
	bar_len = pci_resource_len(pdev, idx);
	map_len = bar_len;

	pddev->bar[idx] = NULL;

	/* no map BARs with length 0. Note that start MAY be 0! */
	if (!bar_len) {
		//pr_info("BAR #%d is not present - skipping\n", idx);
		return 0;
	}

	/* BAR size exceeds maximum desired mapping? */
	if (bar_len > INT_MAX) {
		pr_info("Limit BAR %d mapping from %llu to %d bytes\n", idx,
			(u64)bar_len, INT_MAX);
		map_len = (resource_size_t)INT_MAX;
	}
	/*
	 * map the full device memory or IO region into kernel virtual
	 * address space
	 */
	dbg_init("BAR%d: %llu bytes to be mapped.\n", idx, (u64)map_len);
	pddev->bar[idx] = pci_iomap(pdev, idx, map_len);

	if (!pddev->bar[idx]) {
		pr_info("Could not map BAR %d.\n", idx);
		return -1;
	}

	pr_info("BAR%d at 0x%llx mapped at 0x%p, length=%llu(/%llu)\n", idx,
		(u64)bar_start, pddev->bar[idx], (u64)map_len, (u64)bar_len);

	return (int)map_len;
}


/*
 * Unmap the BAR regions that had been mapped earlier using map_bars()
 */
static void unmap_bars(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	int i;

	for (i = 0; i < BDMA_BAR_NUM; i++) {
		/* is this BAR mapped? */
		if (pddev->bar[i]) {
			/* unmap BAR */
			pci_iounmap(pdev, pddev->bar[i]);
			/* mark as unmapped */
			pddev->bar[i] = NULL;
		}
	}
}

#ifndef BDMA_CONFIG_BAR_NUM
/*
 * The following logic identifies which BARs contain what functionality
 * based on the position of the BDMA config BAR and the number of BARs
 * detected. 
 */
static int identify_bars(struct bdma_dev *pddev, int *bar_id_list, int num_bars,
			 int config_bar_pos)
{
	if (!pddev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	if (!bar_id_list) {
		pr_err("Invalid bar id list.\n");
		return -EINVAL;
	}

	dbg_init("pddev 0x%p, bars %d, config at %d.\n", pddev, num_bars, config_bar_pos);

	switch (num_bars) {
	case 1:
		/* Only one BAR present - no extra work necessary */
		break;

	case 2:
		if (config_bar_pos == 0) {
			pddev->byp_bar_idx = bar_id_list[1];
		} else if (config_bar_pos == 1) {
			pddev->usr_bar_idx = bar_id_list[0];
		} else {
			pr_info("2, BDMA config BAR unexpected %d.\n",
				config_bar_pos);
		}
		break;

	case 3:
	case 4:
		if ((config_bar_pos == 1) || (config_bar_pos == 2)) {
			/* user bar at bar 0 */
			pddev->usr_bar_idx = bar_id_list[0];
			/* bypass bar at the last bar */
			pddev->byp_bar_idx = bar_id_list[num_bars - 1];
		} else {
			pr_info("3/4, BDMA config BAR unexpected %d.\n",
				config_bar_pos);
		}
		break;

	default:
		/* Should not occur */
		pr_info("Unexpected # BARs (%d), BDMA config BAR only.\n",
			num_bars);
		break;
	}
	pr_info("%d BARs: config %d, user %d, bypass %d.\n", num_bars,
		config_bar_pos, pddev->usr_bar_idx, pddev->byp_bar_idx);
	return 0;
}
#endif

/* map_bars() -- map device regions into kernel virtual address space
 *
 * Map the device memory regions into kernel virtual address space after
 * verifying their sizes respect the minimum sizes needed
 */
static int map_bars(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	int ret;

#ifdef BDMA_CONFIG_BAR_NUM
	ret = map_single_bar(pddev, pdev, BDMA_CONFIG_BAR_NUM);
	if (ret <= 0) {
		pr_info("%s, map config bar %d failed, %d.\n",
			dev_name(&pdev->dev), BDMA_CONFIG_BAR_NUM, ret);
		return -EINVAL;
	}

	if (is_config_bar(pddev, BDMA_CONFIG_BAR_NUM) == 0) {
		pr_info("%s, unable to identify config bar %d.\n",
			dev_name(&pdev->dev), BDMA_CONFIG_BAR_NUM);
		return -EINVAL;
	}
	pddev->cfg_bar_idx = BDMA_CONFIG_BAR_NUM;

	return 0;
#else
	int i;
	int bar_id_list[BDMA_BAR_NUM];
	int bar_id_idx = 0;
	int config_bar_pos = 0;

	/* iterate through all the BARs */
	for (i = 0; i < BDMA_BAR_NUM; i++) {
		int bar_len;

		bar_len = map_single_bar(pddev, pdev, i);
		if (bar_len == 0) {
			continue;
		} else if (bar_len < 0) {
			ret = -EINVAL;
			goto fail;
		}

                pr_info("func %s line %d\n",__FUNCTION__,__LINE__);

		/* Try to identify BAR as BDMA ctrl BAR */
		if ((bar_len >= BDMA_BAR_SIZE) && (pddev->cfg_bar_idx < 0)) {
                        pr_info("func %s line %d\n",__FUNCTION__,__LINE__);
			if (is_config_bar(pddev, i)) {
				pddev->cfg_bar_idx = i;
				config_bar_pos = bar_id_idx;
				pr_info("config bar %d, pos %d.\n",
					pddev->cfg_bar_idx, config_bar_pos);
			}
		}

		bar_id_list[bar_id_idx] = i;
		bar_id_idx++;
	}

	/* The BDMA config BAR must always be present */
	if (pddev->cfg_bar_idx < 0) {
		pr_info("Failed to detect BDMA config BAR\n");
		ret = -EINVAL;
		goto fail;
	}

	ret = identify_bars(pddev, bar_id_list, bar_id_idx, config_bar_pos);
	if (ret < 0) {
		pr_err("Failed to identify bars\n");
		return ret;
	}

	/* successfully mapped all required BAR regions */
	return 0;

fail:
	/* unwind; unmap any BARs that we did map */
	unmap_bars(pddev, pdev);
	return ret;
#endif
}



/*
 * bdma_isr() - interrupt handler
 *
 * @dev_id pointer to bdma_dev
 */
static irqreturn_t bdma_isr(int irq, void *dev_id)
{	
	u32 mask;
	u32 ch_irq;
	u32 usr_irq;
	struct bdma_dev *pddev;
	struct intr_regs *irq_regs;

	dbg_irq("(irq=%d, dev 0x%p) <<<< ISR.\n", irq, dev_id);
	if (!dev_id) {
		pr_err("Invalid dev_id on irq line %d\n", irq);
		return -IRQ_NONE;
	}
	
	pddev = (struct bdma_dev *)dev_id;

	if (!pddev) {
		WARN_ON(!pddev);
		dbg_irq("%s(irq=%d) pddev=%p ??\n", __func__, irq, pddev);
		return IRQ_NONE;
	}

	irq_regs = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] +
					     BDMA_OFS_INT_CTRL);

	/* read channel inter requests */
	ch_irq = read_reg(&irq_regs->chan_int_req);
	dbg_irq("ch_irq = 0x%08x\n", ch_irq);

	/*
	 * disable all intr that fired; these are re-enabled individually
	 * after the causing module has been fully serviced.
	 */
	if (ch_irq)
		chan_intr_disable(pddev, ch_irq);

	/* read user intrs - this read also flushes the above write */
	usr_irq = read_reg(&irq_regs->usr_int_req);
	dbg_irq("usr_irq = 0x%08x\n", usr_irq);

	if (usr_irq) {
		int user = 0;
		u32 mask = 1;
		int max = pddev->user_max_event;

		for (; user < max && usr_irq; user++, mask <<= 1) {
			if (usr_irq & mask) {
				usr_irq &= ~mask;
				usr_irq_service(irq, &pddev->usr_irq[user]);
			}
		}
	}

	mask = ch_irq & pddev->mask_irq_tx;
	if (mask) {
		int channel = 0;
		int max = pddev->tx_chan_max;

		/* iterate over tx (PCIe read) */
		for (channel = 0; channel < max && mask; channel++) {
			struct bdma_engine *engine = &pddev->eng_tx[channel];

			/* engine present and its inter fired? */
			if ((engine->irq_bitmask & mask) &&
			    (engine->magic == MAGIC_ENGINE)) {
				mask &= ~engine->irq_bitmask;
				dbg_tfr("schedule_work, %s.\n", engine->name);
				schedule_work(&engine->work);
			}
		}
	}

	mask = ch_irq & pddev->mask_irq_rx;
	if (mask) {
		int channel = 0;
		int max = pddev->rx_chan_max;

		/* iterate over rx (PCIe write) */
		for (channel = 0; channel < max && mask; channel++) {
			struct bdma_engine *engine = &pddev->eng_rx[channel];

			/* engine present and its inter fired? */
			if ((engine->irq_bitmask & mask) &&
			    (engine->magic == MAGIC_ENGINE)) {
				mask &= ~engine->irq_bitmask;
				dbg_tfr("schedule_work, %s.\n", engine->name);
				schedule_work(&engine->work);
			}
		}
	}

	pddev->irq_cnt++;
	return IRQ_HANDLED;
}



/*
 * bdma_usr_irq() - Interrupt handler for user inters in MSI-X mode
 *
 * @dev_id pointer to bdma_dev
 */
static irqreturn_t bdma_usr_irq(int irq, void *dev_id)
{
	struct bdma_usr_irq *usr_irq;

	dbg_irq("(irq=%d) <<<< interrupt service routine\n", irq);

	if (!dev_id) {
		pr_err("Invalid dev_id on irq line %d\n", irq);
		return IRQ_NONE;
	}
	usr_irq = (struct bdma_usr_irq *)dev_id;

	return usr_irq_service(irq, usr_irq);
}


/**
 * bdma_eng_stop() - stop an SG DMA engine
 *
 */
static int bdma_eng_stop(struct bdma_engine *engine)
{
	u32 tmp;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}
	dbg_tfr("%s(engine=%p)\n", __func__, engine);

	if (en_st_rx_credit && engine->streaming &&
	    engine->dir == DMA_FROM_DEVICE)
		write_reg(0, &engine->sgdma_regs->credits, 0);

	tmp = 0;
	tmp |= (u32)BDMA_CTRL_IE_DESC_ALIGN_MISMATCH;
	tmp |= (u32)BDMA_CTRL_IE_MAGIC_STOPPED;
	tmp|= (u32)BDMA_CTRL_IE_READ_ERROR;
	tmp |= (u32)BDMA_CTRL_IE_DESC_ERROR;

	if (poll_mode) {
		tmp |= (u32)BDMA_CTRL_POLL_MODE_WB;
	} else {
		tmp |= (u32)BDMA_CTRL_IE_DESC_STOPPED;
		tmp |= (u32)BDMA_CTRL_IE_DESC_COMPLETED;
	}

	dbg_tfr("Stopping SG DMA %s engine; writing 0x%08x to 0x%p.\n",
		engine->name, tmp, (u32 *)&engine->regs->ctrl);
	write_reg(tmp, &engine->regs->ctrl,
			(unsigned long)(&engine->regs->ctrl) -
				(unsigned long)(&engine->regs));
	/* dummy read of status register to flush all previous writes */
	dbg_tfr("%s(%s) done\n", __func__, engine->name);
	engine->running = 0;
	return 0;
}


/**
 * bdma_get_next_adj()
 *
 * Get the number for adjacent descriptors to set in a descriptor, based on the
 * remaining number of descriptors and the lower bits of the address of the
 * next descriptor.
 */
static u32 bdma_get_next_adj(unsigned int remaining, u32 next_lo)
{
	unsigned int next_index;

	dbg_desc("%s: remaining_desc %u, next_lo 0x%x\n",__func__, remaining,
			next_lo);

	if (remaining <= 1)
		return 0;

	/* shift right 5 times corresponds to a division by
	 * sizeof(bdma_desc) = 32
	 */
	next_index = ((next_lo & (BDMA_PAGE_SIZE - 1)) >> 5) %
		BDMA_MAX_ADJ_BLOCK_SIZE;
	return min(BDMA_MAX_ADJ_BLOCK_SIZE - next_index - 1, remaining - 1);
}



/*
 * bdma_channel_irq() - Interrupt handler for channel inters in MSI-X mode
 *
 * @dev_id pointer to bdma_dev
 */
static irqreturn_t bdma_channel_irq(int irq, void *dev_id)
{
	struct bdma_dev *pddev;
	struct bdma_engine *engine;
	struct intr_regs *irq_regs;

	dbg_irq("(irq=%d) <<<< interrupt service routine\n", irq);
	if (!dev_id) {
		pr_err("Invalid dev_id on irq line %d\n", irq);
		return IRQ_NONE;
	}

	engine = (struct bdma_engine *)dev_id;
	pddev = engine->pddev;

	if (!pddev) {
		WARN_ON(!pddev);
		dbg_irq("%s(irq=%d) pddev=%p ??\n", __func__, irq, pddev);
		return IRQ_NONE;
	}

	irq_regs = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] + BDMA_OFS_INT_CTRL);

	/* disable the inter for this engine */
	write_reg(
		engine->intr_en_mask_value,
		&engine->regs->intr_en_mask_hi_wtc,
		(unsigned long)(&engine->regs->intr_en_mask_hi_wtc) - (unsigned long)(&engine->regs));
	/* dummy read to flush the above write */
	read_reg(&irq_regs->chan_int_pend);
	/* schedule the bottom half */
	schedule_work(&engine->work);

	/* need to protect access here if multiple MSI-X are used for user inters */
	pddev->irq_cnt++;
	return IRQ_HANDLED;
}

static int eng_reg_dump(struct bdma_engine *engine)
{
	u32 tmp;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	tmp = read_reg(&engine->regs->eng_id);
	pr_info("%s: ioread32(0x%p) = 0x%08x (id).\n", engine->name,
		&engine->regs->eng_id, tmp);
	tmp &= BLOCK_ID_MASK;
	if (tmp != BLOCK_ID_HEAD) {
		pr_err("%s: engine id missing, 0x%08x exp. & 0x%x = 0x%x\n",
		       engine->name, tmp, BLOCK_ID_MASK, BLOCK_ID_HEAD);
		return -EINVAL;
	}
	/* extra debugging; inspect complete engine set of registers */
	tmp = read_reg(&engine->regs->status);
	pr_info("%s: ioread32(0x%p) = 0x%08x (status).\n", engine->name,
		&engine->regs->status, tmp);
	tmp = read_reg(&engine->regs->ctrl);
	pr_info("%s: ioread32(0x%p) = 0x%08x (ctrl)\n", engine->name,
		&engine->regs->ctrl, tmp);
	tmp = read_reg(&engine->sgdma_regs->first_desc_lo);
	pr_info("%s: ioread32(0x%p) = 0x%08x (first_desc_lo)\n", engine->name,
		&engine->sgdma_regs->first_desc_lo, tmp);
	tmp = read_reg(&engine->sgdma_regs->first_desc_hi);
	pr_info("%s: ioread32(0x%p) = 0x%08x (first_desc_hi)\n", engine->name,
		&engine->sgdma_regs->first_desc_hi, tmp);
	tmp = read_reg(&engine->sgdma_regs->first_desc_adj);
	pr_info("%s: ioread32(0x%p) = 0x%08x (first_desc_adj).\n",
		engine->name, &engine->sgdma_regs->first_desc_adj, tmp);
	tmp = read_reg(&engine->regs->comp_desc_cnt);
	pr_info("%s: ioread32(0x%p) = 0x%08x (comp_desc_cnt).\n",
		engine->name, &engine->regs->comp_desc_cnt, tmp);
	tmp = read_reg(&engine->regs->intr_en_mask_hi);
	pr_info("%s: ioread32(0x%p) = 0x%08x (intr_en_mask_hi)\n",
		engine->name, &engine->regs->intr_en_mask_hi, tmp);

	return 0;
}

static void eng_status_dump(struct bdma_engine *engine)
{
	u32 tmp = engine->status;
	char buffer[256];
	char *buf = buffer;
	int len = 0;

	len = sprintf(buf, "SG engine %s status: 0x%08x: ", engine->name, tmp);

	if ((tmp & BDMA_STAT_BUSY))
		len += sprintf(buf + len, "BUSY,");
	if ((tmp & BDMA_STAT_DESC_STOPPED))
		len += sprintf(buf + len, "DESC_STOPPED,");
	if ((tmp & BDMA_STAT_DESC_COMPLETED))
		len += sprintf(buf + len, "DESC_COMPL,");

	/* common tx & rx */
	if ((tmp & BDMA_STAT_COMMON_ERR_MASK)) {
		if ((tmp & BDMA_STAT_ALIGN_MISMATCH))
			len += sprintf(buf + len, "ALIGN_MISMATCH ");
		if ((tmp & BDMA_STAT_MAGIC_STOPPED))
			len += sprintf(buf + len, "MAGIC_STOPPED ");
		if ((tmp & BDMA_STAT_INVALID_LEN))
			len += sprintf(buf + len, "INVLIAD_LEN ");
		if ((tmp & BDMA_STAT_IDLE_STOPPED))
			len += sprintf(buf + len, "IDLE_STOPPED ");
		buf[len - 1] = ',';
	}

	/* common tx*/
	if (engine->dir == DMA_TO_DEVICE) {
		/* TX only */
		if ((tmp & BDMA_STAT_TX_R_ERR_MASK)) {
			len += sprintf(buf + len, "R:");
			if ((tmp & BDMA_STAT_TX_R_UNSUPP_REQ))
				len += sprintf(buf + len, "UNSUPP_REQ ");
			if ((tmp & BDMA_STAT_TX_R_COMPL_ABORT))
				len += sprintf(buf + len, "COMPL_ABORT ");
			if ((tmp & BDMA_STAT_TX_R_PARITY_ERR))
				len += sprintf(buf + len, "PARITY ");
			if ((tmp & BDMA_STAT_TX_R_HEADER_EP))
				len += sprintf(buf + len, "HEADER_EP ");
			if ((tmp & BDMA_STAT_TX_R_UNEXP_COMPL))
				len += sprintf(buf + len, "UNEXP_COMPL ");
			buf[len - 1] = ',';
		}

		if ((tmp & BDMA_STAT_TX_W_ERR_MASK)) {
			len += sprintf(buf + len, "W:");
			if ((tmp & BDMA_STAT_TX_W_DECODE_ERR))
				len += sprintf(buf + len, "DECODE_ERR ");
			if ((tmp & BDMA_STAT_TX_W_SLAVE_ERR))
				len += sprintf(buf + len, "SLAVE_ERR ");
			buf[len - 1] = ',';
		}

	} else {
		/* common rx*/
		if ((tmp & BDMA_STAT_RX_R_ERR_MASK)) {
			len += sprintf(buf + len, "R:");
			if ((tmp & BDMA_STAT_RX_R_DECODE_ERR))
				len += sprintf(buf + len, "DECODE_ERR ");
			if ((tmp & BDMA_STAT_RX_R_SLAVE_ERR))
				len += sprintf(buf + len, "SLAVE_ERR ");
			buf[len - 1] = ',';
		}
	}

	/* common TX & RX */
	if ((tmp & BDMA_STAT_DESC_ERR_MASK)) {
		len += sprintf(buf + len, "DESC_ERR:");
		if ((tmp & BDMA_STAT_DESC_UNSUPP_REQ))
			len += sprintf(buf + len, "UNSUPP_REQ ");
		if ((tmp & BDMA_STAT_DESC_COMPL_ABORT))
			len += sprintf(buf + len, "COMPL_ABORT ");
		if ((tmp & BDMA_STAT_DESC_PARITY_ERR))
			len += sprintf(buf + len, "PARITY ");
		if ((tmp & BDMA_STAT_DESC_HEADER_EP))
			len += sprintf(buf + len, "HEADER_EP ");
		if ((tmp & BDMA_STAT_DESC_UNEXP_COMPL))
			len += sprintf(buf + len, "UNEXP_COMPL ");
		buf[len - 1] = ',';
	}

	buf[len - 1] = '\0';
	pr_info("%s\n", buffer);
}

/**
 * eng_status_read() - read status of SG DMA engine (optionally reset)
 *
 * Stores status in engine->status.
 *
 * @return error value on failure, 0 otherwise
 */
static int eng_status_read(struct bdma_engine *engine, bool clear, bool dump)
{
	int ret = 0;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	if (dump) {
		ret = eng_reg_dump(engine);
		if (ret < 0) {
			pr_err("Failed to dump register\n");
			return ret;
		}
	}

	/* read status register */
	if (clear)
		engine->status = read_reg(&engine->regs->status_rc);
	else
		engine->status = read_reg(&engine->regs->status);

	if (dump)
		eng_status_dump(engine);

	return ret;
}


static int eng_start_mode_config(struct bdma_engine *engine)
{
	u32 tmp;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	/* If a perf test is running, enable the engine inters */
	if (engine->bdma_perf) {
		tmp |= BDMA_CTRL_IE_MAGIC_STOPPED;
		tmp |= BDMA_CTRL_IE_IDLE_STOPPED;
		tmp = BDMA_CTRL_IE_DESC_STOPPED;
		tmp |= BDMA_CTRL_IE_DESC_COMPLETED;
		tmp |= BDMA_CTRL_IE_DESC_ALIGN_MISMATCH;
		tmp |= BDMA_CTRL_IE_READ_ERROR;
		tmp |= BDMA_CTRL_IE_DESC_ERROR;

		write_reg(
			tmp, &engine->regs->intr_en_mask_hi,
			(unsigned long)(&engine->regs->intr_en_mask_hi) -
				(unsigned long)(&engine->regs));
	}

	/* write ctrl register of SG DMA engine */
	tmp = (u32)BDMA_CTRL_RUN_STOP;
	tmp |= (u32)BDMA_CTRL_IE_DESC_ALIGN_MISMATCH;
	tmp |= (u32)BDMA_CTRL_IE_MAGIC_STOPPED;
	tmp |= (u32)BDMA_CTRL_IE_READ_ERROR;
	tmp |= (u32)BDMA_CTRL_IE_DESC_ERROR;

	if (poll_mode) {
		tmp |= (u32)BDMA_CTRL_POLL_MODE_WB;
	} else {
		tmp |= (u32)BDMA_CTRL_IE_DESC_STOPPED;
		tmp |= (u32)BDMA_CTRL_IE_DESC_COMPLETED;
	}

	/* set non-incremental addressing mode */
	if (engine->no_inc_addr)
		tmp |= (u32)BDMA_CTRL_NON_INCR_ADDR;

	dbg_tfr("iowrite32(0x%08x to 0x%p) (ctrl)\n", tmp,
		(void *)&engine->regs->ctrl);

	/* start the engine */
	write_reg(tmp, &engine->regs->ctrl,
		       (unsigned long)(&engine->regs->ctrl) - (unsigned long)(&engine->regs));

	/* dummy read of status register to flush all previous writes */
	tmp = read_reg(&engine->regs->status);
	dbg_tfr("ioread32(0x%p) = 0x%08x (dummy read flushes writes).\n",
		&engine->regs->status, tmp);
	return 0;
}

/**
 * eng_start() - start an idle engine with its first trans on queue
 *
 * The engine will run and process all transs that are queued using
 * trans_queue() and thus have their descriptor lists chained.
 *
 * The engine must be idle and at least one trans must be queued.
 * This function does not take locks; the engine spinlock must already be
 * taken.
 *
 */
static struct bdma_transfer *eng_start(struct bdma_engine *engine)
{
	struct bdma_transfer *trans;
	u32 tmp, next_adj;
	int ret;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return NULL;
	}

	/* engine must be idle */
	if (engine->running) {
		pr_info("%s engine is not in idle state to start\n",
			engine->name);
		return NULL;
	}

	/* engine trans queue must not be empty */
	if (list_empty(&engine->trans_list)) {
		pr_debug("%s engine trans queue must not be empty\n",
			 engine->name);
		return NULL;
	}
	/* inspect first trans queued on the engine */
	trans = list_entry(engine->trans_list.next, struct bdma_transfer,
			      entry);
	if (!trans) {
		pr_debug("%s queued trans must not be empty\n",
			 engine->name);
		return NULL;
	}

	/* engine is no longer shutdown */
	engine->shutdown = ENGINE_SHUTDOWN_NONE;

	dbg_tfr("%s(%s): trans=0x%p.\n", __func__, engine->name, trans);

	/* Add credits for Streaming mode RX */
	if (en_st_rx_credit && engine->streaming &&
	    engine->dir == DMA_FROM_DEVICE)
		write_reg(engine->desc_used, &engine->sgdma_regs->credits, 0);

	/* initialize number of descriptors of dequeued transs */
	engine->desc_dequeued = 0;

	/* write upper 32-bit of bus address of trans first descriptor */
	tmp = cpu_to_le32(PCI_DMA_H(trans->desc_bus));
	dbg_tfr("iowrite32(0x%08x to 0x%p) (first_desc_hi)\n", tmp,
		(void *)&engine->sgdma_regs->first_desc_hi);
	write_reg(tmp, &engine->sgdma_regs->first_desc_hi,
		       (unsigned long)(&engine->sgdma_regs->first_desc_hi) -
			       (unsigned long)(&engine->sgdma_regs));

	/* write lower 32-bit of bus address of trans first descriptor */
	tmp = cpu_to_le32(PCI_DMA_L(trans->desc_bus));
	dbg_tfr("iowrite32(0x%08x to 0x%p) (first_desc_lo)\n", tmp,
		(void *)&engine->sgdma_regs->first_desc_lo);
	write_reg(tmp, &engine->sgdma_regs->first_desc_lo,
		       (unsigned long)(&engine->sgdma_regs->first_desc_lo) -
			       (unsigned long)(&engine->sgdma_regs));
	
    /* write next_adj of trans first descriptor */
	next_adj = bdma_get_next_adj(trans->desc_adj,
				     cpu_to_le32(PCI_DMA_L(trans->desc_bus)));

	dbg_tfr("iowrite32(0x%08x to 0x%p) (first_desc_adj)\n", next_adj,
		(void *)&engine->sgdma_regs->first_desc_adj);

	write_reg(
		next_adj, &engine->sgdma_regs->first_desc_adj,
		(unsigned long)(&engine->sgdma_regs->first_desc_adj) -
			(unsigned long)(&engine->sgdma_regs));

	dbg_tfr("ioread32(0x%p) (dummy read flushes writes).\n",
		&engine->regs->status);

#if HAS_MMIOWB
	mmiowb();
#endif

	ret = eng_start_mode_config(engine);
	if (ret < 0) {
		pr_err("fail to start engine mode config\n");
		return NULL;
	}

	ret = eng_status_read(engine, 0, 0);
	if (ret < 0) {
		pr_err("fail to read engine status\n");
		return NULL;
	}
	dbg_tfr("%s engine 0x%p now running\n", engine->name, engine);
	/* remember the engine is running */
	engine->running = 1;
	return trans;
}

static struct bdma_transfer *eng_trans_completion(
		struct bdma_engine *engine,
		struct bdma_transfer *trans)
{
	if (!engine) {
		pr_err("dma engine NULL\n");
		return NULL;
	}

	if (unlikely(!trans)) {
		pr_info("%s: eng empty.\n", engine->name);
		return NULL;
	}

	/* synchronous i/o? */
	/* awake task on trans's wait queue */
	pg_wake_up(&trans->wq);

	/* Send completion notification for Last trans */
	if (trans->cb && trans->last_in_req)
		trans->cb->io_done((unsigned long)trans->cb, 0);

	return trans;
}

static int eng_err_handle(struct bdma_engine *engine,
			     struct bdma_transfer *trans, u32 desc_completed)
{
	u32 value;
	int ret = 0;
	/*
	 * The busy bit is to be clear now but older HW has a race
	 * condition which could cause it to be still set.  if it's set, re-read
	 * and check again.  if it's still set, log the issue.
	 */
	if (engine->status & BDMA_STAT_BUSY) {
		value = read_reg(&engine->regs->status);
		if ((value & BDMA_STAT_BUSY))
			printk_ratelimited(KERN_INFO
					"%s has errors but is still BUSY\n",
					engine->name);
	}

	printk_ratelimited(KERN_INFO "%s, s 0x%x, aborted eng 0x%p, cmpl %d/%d\n",
			engine->name, engine->status, trans, desc_completed,
			trans->desc_num);

	/* mark trans as failed */
	trans->state = TRANS_STATE_FAILED;
	ret = bdma_eng_stop(engine);
	if (ret < 0)
		pr_err("Failed to stop engine\n");
	return ret;
}				 

static struct bdma_transfer *
eng_service_trans_list(struct bdma_engine *engine,
			  struct bdma_transfer *trans,
			  u32 *pdesc_completed)
{
 if (!engine) {
	 pr_err("dma engine NULL\n");
	 return NULL;
 }

 if (!pdesc_completed) {
	 pr_err("%s completed descriptors are null.\n", engine->name);
	 return NULL;
 }

 if (unlikely(!trans)) {
	 pr_info("%s eng empty, pdesc completed %u.\n", engine->name,
		 *pdesc_completed);
	 return NULL;
 }

 /* iterate over all the transs completed by the engine,except for the last (i.e. use > instead of >=). */
  
 while (trans && (!trans->cyclic) &&
		(*pdesc_completed > trans->desc_num)) {
	 /* remove this trans from pdesc_completed */
	 *pdesc_completed -= trans->desc_num;
	 dbg_tfr("%s engine completed non-cyclic eng 0x%p (%d desc)\n",
		 engine->name, trans, trans->desc_num);

	 /* remove completed trans from list */
	 list_del(engine->trans_list.next);
	 /* add to dequeued number of descriptors during this run */
	 engine->desc_dequeued += trans->desc_num;
	 /* mark trans as succesfully completed */
	 trans->state = TRANS_STATE_COMPLETED;

	 /*
	  * Complete trans - sets trans to NULL if an async trans has completed
	  */
	  
	 trans = eng_trans_completion(engine, trans);

	 /* if exists, get the next trans on the list */
	 if (!list_empty(&engine->trans_list)) {
		 trans = list_entry(engine->trans_list.next,
					   struct bdma_transfer, entry);
		 dbg_tfr("Non-completed trans %p\n", trans);
	 } else {
		 /* no further transfers? */
		 trans = NULL;
	 }
 }

 return trans;
}

/**
* eng_service() - service an SG DMA engine
*
* must be called with engine->lock already acquired
*
* @engine pointer to struct bdma_engine
*
*/
static int eng_service_shutdown(struct bdma_engine *engine)
{
  int ret;
  /* if the engine stopped with RUN still asserted, de-assert RUN now */
  dbg_tfr("engine just went idle, resetting RUN_STOP.\n");
  ret = bdma_eng_stop(engine);
  if (ret < 0) {
	  pr_err("Failed to stop engine\n");
	  return ret;
  }

  /* awake task on engine's shutdown wait queue */
  pg_wake_up(&engine->shutdown_wq);
  return 0;
}


static struct bdma_transfer *
eng_service_final_transfer(struct bdma_engine *engine,
			      struct bdma_transfer *trans,
			      u32 *pdesc_completed)
{
	int i;
	int max;
	struct bdma_result *result;
	
	if (!engine) {
		pr_err("dma engine NULL\n");
		return NULL;
	}

	if (!pdesc_completed) {
		pr_err("%s completed descriptors are null.\n", engine->name);
		return NULL;
	}

	/* inspect the current trans */
	if (unlikely(!trans)) {
		pr_info("%s eng empty, pdesc completed %u.\n", engine->name,
			*pdesc_completed);
		return NULL;
	}

	if (((engine->dir == DMA_FROM_DEVICE) &&
	     (engine->status & BDMA_STAT_RX_ERR_MASK)) ||
	    ((engine->dir == DMA_TO_DEVICE) &&
	     (engine->status & BDMA_STAT_TX_ERR_MASK))) {
		pr_info("engine %s, status error 0x%x.\n", engine->name,
			engine->status);
		eng_status_dump(engine);
		eng_err_handle(engine, trans, *pdesc_completed);
		goto transfer_del;
	}

	if (engine->status & BDMA_STAT_BUSY)
		pr_debug("engine %s is unexpectedly busy - ignoring\n",
			 engine->name);

	/* the engine stopped on current trans? */
	if (*pdesc_completed < trans->desc_num) {
		if (engine->eop_flush) {
			/* check if eop received */
			result = trans->res_virt;			
			max = *pdesc_completed;

			for (i = 0; i < max; i++) {
				if ((result[i].status & RX_STATUS_EOP) != 0) {
					trans->flags |=
						TRAN_FLAG_ST_RX_EOP_RCVED;
					break;
				}
			}

			trans->desc_comp += *pdesc_completed;
			if (!(trans->flags & TRAN_FLAG_ST_RX_EOP_RCVED)) {
				return NULL;
			}

			/* mark trans as successfully completed */
			eng_service_shutdown(engine);

			trans->state = TRANS_STATE_COMPLETED;

			engine->desc_dequeued += trans->desc_comp;

		} else {
			trans->state = TRANS_STATE_FAILED;
			pr_info("%s, eng 0x%p, stopped half-way, %d/%d.\n",
				engine->name, trans, *pdesc_completed,
				trans->desc_num);

			/* add dequeued number of descriptors during this run */
			engine->desc_dequeued += trans->desc_num;
			trans->desc_comp = *pdesc_completed;
		}
	} else {
		dbg_tfr("engine %s completed trans\n", engine->name);
		dbg_tfr("Completed trans ID = 0x%p\n", trans);
		dbg_tfr("*pdesc_completed=%d, trans->desc_num=%d",
			*pdesc_completed, trans->desc_num);

		if (!trans->cyclic) {
			/*
			 * if the engine stopped on this trans,
			 * it should be the last
			 */
			WARN_ON(*pdesc_completed > trans->desc_num);
		}
		/* mark trans as successfully completed */
		trans->state = TRANS_STATE_COMPLETED;
		trans->desc_comp = trans->desc_num;
		/* add dequeued number of descriptors during this run */
		engine->desc_dequeued += trans->desc_num;
	}

transfer_del:
	/* remove completed trans from list */
	list_del(engine->trans_list.next);

	/*
	 * Complete trans - sets trans to NULL if an asynchronous
	 * trans has completed
	 */
	trans = eng_trans_completion(engine, trans);

	return trans;
}



static int eng_service_perf(struct bdma_engine *engine, u32 desc_completed)
{
  if (!engine) {
	  pr_err("dma engine NULL\n");
	  return -EINVAL;
  }

  /* performance measurement is running? */
  if (engine->bdma_perf) {
	  /* a descriptor was completed? */
	  if (engine->status & BDMA_STAT_DESC_COMPLETED) {
		  engine->bdma_perf->iterations = desc_completed;
		  dbg_perf("trans->bdma_perf->iterations=%d\n",
			   engine->bdma_perf->iterations);
	  }

	  /* a descriptor stopped the engine? */
	  if (engine->status & BDMA_STAT_DESC_STOPPED) {
		  engine->bdma_perf->stopped = 1;
		  /*
		   * wake any BDMA_PERF_IOCTL_STOP waiting for
		   * the performance run to finish
		   */
		  pg_wake_up(&engine->bdma_perf_wq);
		  dbg_perf("trans->bdma_perf stopped\n");
	  }
  }
  return 0;
}

static int eng_service_resume(struct bdma_engine *engine)
{
	struct bdma_transfer *trans_started;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	/* engine stopped? */
	if (!engine->running) {
		/* in the case of shutdown, let it finish what's in the queue */
		if (!list_empty(&engine->trans_list)) {
			/* (re)start engine */
			trans_started = eng_start(engine);
			if (!trans_started) {
				pr_err("Failed to start dma engine\n");
				return -EINVAL;
			}
			dbg_tfr("re-started %s engine with pending eng 0x%p\n",
				engine->name, trans_started);
			/* engine was requested to be shutdown? */
		} else if (engine->shutdown & ENGINE_SHUTDOWN_REQUEST) {
			engine->shutdown |= ENGINE_SHUTDOWN_IDLE;
			/* awake task on engine's shutdown wait queue */
			pg_wake_up(&engine->shutdown_wq);
		} else {
			dbg_tfr("no pending transfers, %s engine stays idle.\n",
				engine->name);
		}
	} else if (list_empty(&engine->trans_list)) {
		eng_service_shutdown(engine);
	}
	return 0;
}


/**
 * eng_service() - service an SG DMA engine
 *
 * must be called with engine->lock already acquired
 *
 * @engine pointer to struct bdma_engine
 *
 */
static int eng_service(struct bdma_engine *engine, int desc_writeback)
{
	struct bdma_transfer *trans = NULL;
	u32 desc_count = desc_writeback & WB_COUNT_MASK;
	u32 err_flag = desc_writeback & WB_ERR_MASK;
	int ret = 0;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	/* Service the engine */
	if (!engine->running) {
		dbg_tfr("Engine was not running!!! Clearing status\n");
		ret = eng_status_read(engine, 1, 0);
		if (ret < 0) {
			pr_err("%s failed to read status\n", engine->name);
			return ret;
		}
		return 0;
	}

	/*
	 * If called by the isr or polling detected an error, read and clear
	 * engine status. in polled mode descriptor, this read is
	 * unnecessary and is skipped to reduce latency
	 */
	if ((desc_count == 0) || (err_flag != 0)) {
		ret = eng_status_read(engine, 1, 0);
		if (ret < 0) {
			pr_err("Failed to read engine status\n");
			return ret;
		}
	}

	/*
	 * engine was running but is no longer busy, or writeback occurred,shut down
	 */
	if ((engine->running && !(engine->status & BDMA_STAT_BUSY)) ||
	    (!engine->eop_flush && desc_count != 0)) {
		ret = eng_service_shutdown(engine);
		if (ret < 0) {
			pr_err("Failed to shutdown engine\n");
			return ret;
		}
	}

	/*
	 * If called from the isr, or if an error occurred, the descriptor
	 * count will be zero.  In polled mode descriptor completion, this read is
	 * unnecessary and is skipped to reduce latency
	 */
	if (!desc_count)
		desc_count = read_reg(&engine->regs->comp_desc_cnt);
	dbg_tfr("%s wb 0x%x, desc_count %u, err %u, dequeued %u.\n",
		engine->name, desc_writeback, desc_count, err_flag,
		engine->desc_dequeued);

	if (!desc_count)
		goto done;

	/* transfers on queue? */
	if (!list_empty(&engine->trans_list)) {
		/* pick first trans on queue (was submitted to the engine) */
		trans = list_entry(engine->trans_list.next,
				      struct bdma_transfer, entry);

		dbg_tfr("head of queue trans 0x%p has %d descriptors\n",
			trans, (int)trans->desc_num);

		dbg_tfr("Engine completed %d desc, %d not yet dequeued\n",
			(int)desc_count,
			(int)desc_count - engine->desc_dequeued);

		ret = eng_service_perf(engine, desc_count);
		if (ret < 0) {
			pr_err("Failed to service descriptors\n");
			return ret;
		}
	}

	/* account for already dequeued transfers during this engine run */
	desc_count -= engine->desc_dequeued;

	/* do all but the last trans */
	trans = eng_service_trans_list(engine, trans, &desc_count);

	/*
	 * do final trans - includes checks of number of descriptors to
	 * detect faulty completion
	 */
	trans = eng_service_final_transfer(engine, trans, &desc_count);

	/* restart the engine following the servicing */
	if (!engine->eop_flush) {
		ret = eng_service_resume(engine);
		if (ret < 0)
			pr_err("Failed to resume engine\n");
	}

done:
	/* If polling detected an error, signal to the caller */
	return err_flag ? -1 : 0;
}


/* eng_service_work */
static void eng_service_work(struct work_struct *work)
{
	struct bdma_engine *engine;
	unsigned long flags;
	int ret;

	engine = container_of(work, struct bdma_engine, work);
	if (engine->magic != MAGIC_ENGINE) {
		pr_err("%s has invalid magic number %lx\n", engine->name,
		       engine->magic);
		return;
	}

	/* lock the engine */
	spin_lock_irqsave(&engine->lock, flags);

	dbg_tfr("eng_service() for %s engine %p\n", engine->name, engine);
	ret = eng_service(engine, 0);
	if (ret < 0) {
		pr_err("Failed to service engine\n");
		goto unlock;
	}

	/* re-enable inters for this engine */
	if (engine->pddev->msix_en) {
		write_reg(
			engine->intr_en_mask_value,
			&engine->regs->intr_en_mask_hi_wts,
			(unsigned long)(&engine->regs
						 ->intr_en_mask_hi_wts) -
				(unsigned long)(&engine->regs));
	} else
		chan_intr_enable(engine->pddev, engine->irq_bitmask);

	/* unlock the engine */
unlock:
	spin_unlock_irqrestore(&engine->lock, flags);
}				   

static u32 eng_service_wb_monitor(struct bdma_engine *engine,
					u32 expected_wb)
{
   struct bdma_poll_wb *wb_data;
   u32 desc_wb = 0;
   u32 sched_limit = 0;
   unsigned long timeout;

   if (!engine) {
	   pr_err("dma engine NULL\n");
	   return -EINVAL;
   }
   wb_data = (struct bdma_poll_wb *)engine->poll_addr_virt;

   /*
	* poll the writeback location for the expected number of
	* descriptors,error events This loop is skipped for cyclic mode,
	* where the expected_desc_count passed in is zero, since it cannot be
	* determined before the function is called
	*/

   timeout = jiffies + (POLL_TIMEOUT_SECONDS * HZ);
   while (expected_wb != 0) {
	   desc_wb = wb_data->comp_desc_cnt;

	   if (desc_wb)
		   wb_data->comp_desc_cnt = 0;

	   if (desc_wb & WB_ERR_MASK)
		   break;
	   else if (desc_wb >= expected_wb)
		   break;

	   /* prevent system from hanging in polled mode */
	   if (time_after(jiffies, timeout)) {
		   dbg_tfr("polling timeout occurred");
		   dbg_tfr("desc_wb = 0x%08x, expected 0x%08x\n", desc_wb,
			   expected_wb);
		   if ((desc_wb & WB_COUNT_MASK) > expected_wb)
			   desc_wb = expected_wb | WB_ERR_MASK;

		   break;
	   }

	   /*
		* define NUM_POLLS_PER_SCHED to limit how much time is spent
		* in the scheduler
		*/

	   if (sched_limit != 0) {
		   if ((sched_limit % NUM_POLLS_PER_SCHED) == 0)
			   schedule();
	   }
	   sched_limit++;
   }

   return desc_wb;
}


int eng_service_poll(struct bdma_engine *engine,
			       u32 expected_desc_count)
{
	u32 desc_wb = 0;
	unsigned long flags;
	int ret = 0;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	if (engine->magic != MAGIC_ENGINE) {
		pr_err("%s has invalid magic number %lx\n", engine->name,
		       engine->magic);
		return -EINVAL;
	}

	/*
	 * Poll the writeback location for the expected number of
	 * descriptors,error events This loop is skipped for cyclic mode,
	 * where the expected_desc_count passed in is zero, since it cannot be
	 * determined before the function is called
	 */

	desc_wb = eng_service_wb_monitor(engine, expected_desc_count);
	if (!desc_wb)
		return 0;

	spin_lock_irqsave(&engine->lock, flags);
	dbg_tfr("%s service.\n", engine->name);
	ret = eng_service(engine, desc_wb);
	spin_unlock_irqrestore(&engine->lock, flags);

	return ret;
}
					
static void eng_align(struct bdma_engine *engine)
{
  u32 tmp;
  u32 align_bytes;
  u32 gran_bytes;
  u32 address_bits;

  tmp = read_reg(&engine->regs->align);
  dbg_init("engine %p name %s align=0x%08x\n", engine, engine->name,
	   (int)tmp);

  align_bytes = (tmp & 0x00ff0000U) >> 16;
  gran_bytes = (tmp & 0x0000ff00U) >> 8;
  address_bits = (tmp & 0x000000ffU);

  dbg_init("align_bytes = %d\n", align_bytes);
  dbg_init("granularity_bytes = %d\n", gran_bytes);
  dbg_init("address_bits = %d\n", address_bits);

  if (tmp) {
	  engine->addr_align = align_bytes;
	  engine->len_of_granu = gran_bytes;
	  engine->addr_bits = address_bits;
  } else {
	  /* Some default values if align are unspecified */
	  engine->addr_align = 1;
	  engine->len_of_granu = 1;
	  engine->addr_bits = 64;
  }
}

static int eng_writeback_setup(struct bdma_engine *engine)
{
	u32 tmp;
	struct bdma_dev *pddev;
	struct bdma_poll_wb *writeback;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	pddev = engine->pddev;
	if (!pddev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	/*
	 * better to allocate one page for the whole device during probe()
	 * and set per-engine offsets here
	 */
	writeback = (struct bdma_poll_wb *)engine->poll_addr_virt;
	writeback->comp_desc_cnt = 0;

	dbg_init("setting writeback location to 0x%llx for engine %p",
		 engine->poll_bus_addr, engine);
	tmp = cpu_to_le32(PCI_DMA_L(engine->poll_bus_addr));
	write_reg(tmp, &engine->regs->poll_wb_lo,
			   (unsigned long)(&engine->regs->poll_wb_lo) -
				   (unsigned long)(&engine->regs));
	tmp = cpu_to_le32(PCI_DMA_H(engine->poll_bus_addr));
	write_reg(tmp, &engine->regs->poll_wb_hi,
			   (unsigned long)(&engine->regs->poll_wb_hi) -
				   (unsigned long)(&engine->regs));

	return 0;
}

/* eng_create() - Create an SG DMA engine bookkeeping data structure
 *
 * An SG DMA engine consists of the resources for a single-direction trans
 * queue; the SG DMA hardware, the software queue and inter handling.
 *
 * @dev Pointer to pci_dev
 * @offset byte address offset in BAR[pddev->cfg_bar_idx] resource for the
 * SG DMA * ctrller registers.
 * @dir: DMA_TO/FROM_DEVICE
 * @streaming Whether the engine is attached to AXI ST (rather than MM)
 */


/**
 *eng_cyclic_stop() - stop a cyclic trans running on an SG DMA engine
 *
 *engine->lock must be taken
 */
struct bdma_transfer *eng_cyclic_stop(struct bdma_engine *engine)
{
	int ret;
	struct bdma_transfer *trans = 0;
	int size = engine->bdma_perf->transfer_size;

	/* transfers on queue? */
	if (!list_empty(&engine->trans_list)) {
		/* pick first trans on the queue (was submitted to engine) */
		trans = list_entry(engine->trans_list.next,
					  struct bdma_transfer, entry);
		if (!trans) {
			pr_err("(engine=%s) has void trans in queue.\n",
				   engine->name);
			return NULL;
		}
		ret = bdma_eng_stop(engine);
		if (ret < 0) {
			pr_err("fail to stop engine\n");
			return NULL;
		}

		if (trans->cyclic) {
			if (engine->bdma_perf)
				dbg_perf("stopping perf trans on %s\n",
					 engine->name);
			else
				dbg_perf("stopping cyclic trans on %s\n",
					 engine->name);
			/* free up the buffer allocated for perf run */
			if (engine->perf_buf_virt)
				dma_free_coherent(&engine->pddev->pdev->dev,
						size, engine->perf_buf_virt,
						engine->perf_buf_bus);
			engine->perf_buf_virt = NULL;
			list_del(&trans->entry);
		} else {
			dbg_sg("(engine=%p) running trans is not cyclic\n",
				   engine);
		}
	} else {
		dbg_sg("(engine=%p) found not running trans.\n", engine);
	}
	return trans;
}

static void eng_free_resource(struct bdma_engine *engine)
{
	struct bdma_dev *pddev = engine->pddev;

	/* Release memory use for descriptor writebacks */
	if (engine->poll_addr_virt) {
		dbg_sg("releasing memory for descriptor writeback\n");
		dma_free_coherent(&pddev->pdev->dev, sizeof(struct bdma_poll_wb),
				  engine->poll_addr_virt,
				  engine->poll_bus_addr);
		dbg_sg("released memory for descriptor writeback\n");
		engine->poll_addr_virt = NULL;
	}

	if (engine->desc) {
		dbg_init("device %s, engine %s pre-alloc desc 0x%p,0x%llx.\n",
			 dev_name(&pddev->pdev->dev), engine->name, engine->desc,
			 engine->desc_bus);
		dma_free_coherent(&pddev->pdev->dev,
				  engine->desc_max * sizeof(struct bdma_desc),
				  engine->desc, engine->desc_bus);
		engine->desc = NULL;
	}

	if (engine->cyc_res) {
		dma_free_coherent(
			&pddev->pdev->dev,
			engine->desc_max * sizeof(struct bdma_result),
			engine->cyc_res, engine->cyc_res_bus);
		engine->cyc_res = NULL;
	}
}


static int eng_alloc_resource(struct bdma_engine *engine)
{
	struct bdma_dev *pddev = engine->pddev;

	engine->desc = dma_alloc_coherent(&pddev->pdev->dev,
					  engine->desc_max *
						  sizeof(struct bdma_desc),
					  &engine->desc_bus, GFP_KERNEL);
	if (!engine->desc) {
		pr_warn("dev %s, %s pre-alloc desc OOM.\n",
			dev_name(&pddev->pdev->dev), engine->name);
		goto err_out;
	}

	if (poll_mode) {
		engine->poll_addr_virt =
			dma_alloc_coherent(&pddev->pdev->dev,
					   sizeof(struct bdma_poll_wb),
					   &engine->poll_bus_addr, GFP_KERNEL);
		if (!engine->poll_addr_virt) {
			pr_warn("%s, %s poll pre-alloc writeback OOM.\n",
				dev_name(&pddev->pdev->dev), engine->name);
			goto err_out;
		}
	}

	if (engine->streaming && engine->dir == DMA_FROM_DEVICE) {
		engine->cyc_res = dma_alloc_coherent(
			&pddev->pdev->dev,
			engine->desc_max * sizeof(struct bdma_result),
			&engine->cyc_res_bus, GFP_KERNEL);

		if (!engine->cyc_res) {
			pr_warn("%s, %s pre-alloc result OOM.\n",
				dev_name(&pddev->pdev->dev), engine->name);
			goto err_out;
		}
	}

	return 0;

err_out:
	eng_free_resource(engine);
	return -ENOMEM;
}

static int eng_init_regs(struct bdma_engine *engine)
{
	u32 reg_value;
	int ret = 0;

	write_reg(BDMA_CTRL_NON_INCR_ADDR, &engine->regs->ctrl_wtc,
			   (unsigned long)(&engine->regs->ctrl_wtc) -
				   (unsigned long)(&engine->regs));

	eng_align(engine);

	/* Configure error inters by default */
	reg_value = BDMA_CTRL_IE_DESC_ALIGN_MISMATCH;
	reg_value |= BDMA_CTRL_IE_MAGIC_STOPPED;
	reg_value |= BDMA_CTRL_IE_MAGIC_STOPPED;
	reg_value |= BDMA_CTRL_IE_READ_ERROR;
	reg_value |= BDMA_CTRL_IE_DESC_ERROR;

	/* if using polled mode, configure writeback address */
	if (poll_mode) {
		ret = eng_writeback_setup(engine);
		if (ret) {
			dbg_init("%s descr writeback setup failed.\n",
				 engine->name);
			goto fail_wb;
		}
	} else {
		/* enable the relevant completion inters */
		reg_value |= BDMA_CTRL_IE_DESC_STOPPED;
		reg_value |= BDMA_CTRL_IE_DESC_COMPLETED;
	}

	/* Apply engine configurations */
	write_reg(reg_value, &engine->regs->intr_en_mask_hi,
			   (unsigned long)(&engine->regs->intr_en_mask_hi) -
				   (unsigned long)(&engine->regs));

	engine->intr_en_mask_value = reg_value;

	/* only enable credit mode for AXI-ST RX */
	if (en_st_rx_credit && engine->streaming &&
		engine->dir == DMA_FROM_DEVICE) {
		struct bdma_dev *pddev = engine->pddev;
		u32 reg_value = (0x1 << engine->channel) << 16;
		struct sgdma_common_regs *reg =
			(struct sgdma_common_regs
				 *)(pddev->bar[pddev->cfg_bar_idx] +
					(0x6 * TARGET_SPACING));

		write_reg(reg_value, &reg->credit_mode_en_wts, 0);
	}

	return 0;

fail_wb:
	return ret;
}


static int eng_init(struct bdma_engine *engine, struct bdma_dev *pddev,
			 int offset, enum dma_data_direction dir, int channel)
{
  int ret;
  u32 val;

  dbg_init("channel %d, offset 0x%x, dir %d.\n", channel, offset, dir);

  /* set magic */
  engine->magic = MAGIC_ENGINE;

  engine->channel = channel;

  /* engine inter request bit */
  engine->irq_bitmask = (1 << BDMA_ENG_IRQ_NUM) - 1;
  engine->irq_bitmask <<= (pddev->eng_cnt * BDMA_ENG_IRQ_NUM);
  engine->byp_off = pddev->eng_cnt * BYPASS_MODE_SPACING;

  /* parent */
  engine->pddev = pddev;
  /* register address */
  engine->regs = (pddev->bar[pddev->cfg_bar_idx] + offset);
  engine->sgdma_regs = pddev->bar[pddev->cfg_bar_idx] + offset +
			   SGDMA_OFFSET_FROM_CHANNEL;
  val = read_reg(&engine->regs->eng_id);
  if (val & 0x8000U)
	  engine->streaming = 1;

  /* remember SG DMA direction */
  engine->dir = dir;
  snprintf(engine->name, sizeof(engine->name), "%d-%s%d-%s", pddev->idx,
	  (dir == DMA_TO_DEVICE) ? "TX" : "RX", channel,
	  engine->streaming ? "ST" : "MM");

  if (en_st_rx_credit && engine->streaming &&
	  engine->dir == DMA_FROM_DEVICE)
		  engine->desc_max = BDMA_ENGINE_CREDIT_TRAN_MAX_DESC;
  else
		  engine->desc_max = BDMA_ENGINE_TRAN_MAX_DESC;

  dbg_init("engine %p name %s irq_bitmask=0x%08x\n", engine, engine->name,
	   (int)engine->irq_bitmask);

  /* initialize the deferred work for trans completion */
  INIT_WORK(&engine->work, eng_service_work);

  if (dir == DMA_TO_DEVICE)
	  pddev->mask_irq_tx |= engine->irq_bitmask;
  else
	  pddev->mask_irq_rx |= engine->irq_bitmask;
  pddev->eng_cnt++;

  ret = eng_alloc_resource(engine);
  if (ret)
	  return ret;

  ret = eng_init_regs(engine);
  if (ret)
	  return ret;

  if (poll_mode)
	  bdma_thread_add_work(engine);

  return 0;
}



static int eng_destroy(struct bdma_dev *pddev, struct bdma_engine *engine)
{
if (!pddev) {
  pr_err("Invalid pddev\n");
  return -EINVAL;
}

if (!engine) {
  pr_err("dma engine NULL\n");
  return -EINVAL;
}

dbg_sg("Shutting down engine %s%d", engine->name, engine->channel);

/* Disable inters to stop processing new events during shutdown */
write_reg(0x0, &engine->regs->intr_en_mask_hi,
		 (unsigned long)(&engine->regs->intr_en_mask_hi) -
			 (unsigned long)(&engine->regs));

if (en_st_rx_credit && engine->streaming &&
  engine->dir == DMA_FROM_DEVICE) {
  u32 reg_value = (0x1 << engine->channel) << 16;
  struct sgdma_common_regs *reg =
	  (struct sgdma_common_regs
		   *)(pddev->bar[pddev->cfg_bar_idx] +
			  (0x6 * TARGET_SPACING));
  write_reg(reg_value, &reg->credit_mode_en_wtc, 0);
}

if (poll_mode)
  bdma_thread_remove_work(engine);

/* Release memory use for descriptor writebacks */
eng_free_resource(engine);

memset(engine, 0, sizeof(struct bdma_engine));
/* Decrement the number of engines available */
pddev->eng_cnt--;
return 0;
}

/*
 * MSI-X inter:
 *	<TX+RX channel_max> vectors, followed by <user_max_event> vectors
 */

/*
 * code to detect if MSI/MSI-X capability exists is derived
 * from linux/pci/msi.c - pci_msi_check_device
 */

#ifndef arch_msi_check_device
static int arch_msi_check_device(struct pci_dev *pdev, int nvec, int type)
{
	return 0;
}
#endif

/* type = PCI_CAP_ID_MSI or PCI_CAP_ID_MSIX */
static int msi_msix_capable(struct pci_dev *pdev, int type)
{
	struct pci_bus *bus;
	int ret;

	if (!pdev || pdev->no_msi)
		return 0;

	for (bus = pdev->bus; bus; bus = bus->parent)
		if (bus->bus_flags & PCI_BUS_FLAGS_NO_MSI)
			return 0;

	ret = arch_msi_check_device(pdev, 1, type);
	if (ret)
		return 0;

	if (!pci_find_capability(pdev, type))
		return 0;

	return 1;
}


static int enable_msi_msix(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	int ret = 0;

	if (!pddev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	if (!pdev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	if ((inter_mode == 3 || !inter_mode) && msi_msix_capable(pdev, PCI_CAP_ID_MSIX)) {
		int req_nvec = pddev->rx_chan_max + pddev->tx_chan_max +
			       pddev->user_max_event;

#if KERNEL_VERSION(4, 12, 0) <= LINUX_VERSION_CODE
		dbg_init("Enabling MSI-X\n");
		ret = pci_alloc_irq_vectors(pdev, req_nvec, req_nvec,
					   PCI_IRQ_MSIX);
#else
		int i;

		dbg_init("Enabling MSI-X\n");
		for (i = 0; i < req_nvec; i++)
			pddev->entry[i].entry = i;

		ret = pci_enable_msix(pdev, pddev->entry, req_nvec);
#endif
		if (ret < 0)
			dbg_init("Couldn't enable MSI-X mode: %d\n", ret);

		pddev->msix_en = 1;

	} else if ((inter_mode == 1 || !inter_mode) &&
		   msi_msix_capable(pdev, PCI_CAP_ID_MSI)) {
		/* enable message signalled inters */
		dbg_init("pci_enable_msi()\n");
		ret = pci_enable_msi(pdev);
		if (ret < 0)
			dbg_init("Couldn't enable MSI mode: %d\n", ret);
		pddev->msi_en = 1;

	} else {
		dbg_init("MSI/MSI-X not detected - using legacy interrupts\n");
	}

	return ret;
}


static void disable_msi_msix(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	if (pddev->msix_en) {
		pci_disable_msix(pdev);
		pddev->msix_en = 0;
	} else if (pddev->msi_en) {
		pci_disable_msi(pdev);
		pddev->msi_en = 0;
	}
}

static void pci_check_intr_pend(struct pci_dev *pdev)
{
	u16 tmp;

	pci_read_config_word(pdev, PCI_STATUS, &tmp);
	if (tmp & PCI_STATUS_INTERRUPT) {
		pr_info("%s PCI STATUS Interrupt pending 0x%x.\n",
			dev_name(&pdev->dev), tmp);
		pci_write_config_word(pdev, PCI_STATUS, PCI_STATUS_INTERRUPT);
	}
}

static void pci_keep_intx_enabled(struct pci_dev *pdev)
{
	/* workaround to a h/w bug:
	 * when msix/msi become unavaile, default to legacy.
	 * However the legacy enable was not checked.
	 * If the legacy was disabled, no ack then everything stuck
	 */
	u16 pcmd, pcmd_new;

	pci_read_config_word(pdev, PCI_COMMAND, &pcmd);
	pcmd_new = pcmd & ~PCI_COMMAND_INTX_DISABLE;
	if (pcmd_new != pcmd) {
		pr_info("%s: clear INTX_DISABLE, 0x%x -> 0x%x.\n",
			dev_name(&pdev->dev), pcmd, pcmd_new);
		pci_write_config_word(pdev, PCI_COMMAND, pcmd_new);
	}
}

#if KERNEL_VERSION(3, 5, 0) <= LINUX_VERSION_CODE
static void pci_enable_capability(struct pci_dev *pdev, int cap)
{
	pcie_capability_set_word(pdev, PCI_EXP_DEVCTL, cap);
}
#else
static void pci_enable_capability(struct pci_dev *pdev, int cap)
{
	u16 tmp;
	int pos;

	pos = pci_pcie_cap(pdev);
	if (pos > 0) {
		pci_read_config_word(pdev, pos + PCI_EXP_DEVCTL, &tmp);
		tmp |= cap;
		pci_write_config_word(pdev, pos + PCI_EXP_DEVCTL, tmp);
	}
}
#endif



static void prog_irq_msix_channel(struct bdma_dev *pddev, bool clear)
{
    u32 i;
	int j;	
	u32 max;
	struct intr_regs *int_regs;

	max = pddev->rx_chan_max + pddev->tx_chan_max;
	int_regs = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] +
					  BDMA_OFS_INT_CTRL);
	
	/* engine */
	for (i = 0, j = 0; i < max; j++) {
		u32 val = 0;
		int k;
		int shift = 0;

		if (clear)
			i += 4;
		else
			for (k = 0; k < 4 && i < max; i++, k++, shift += 8)
				val |= (i & 0x1f) << shift;

		write_reg(val, &int_regs->chan_msi_vec[j],
			       BDMA_OFS_INT_CTRL +
				       ((unsigned long)&int_regs
						->chan_msi_vec[j] -
					(unsigned long)int_regs));
		dbg_init("vector %d, 0x%x.\n", j, val);
	}
}


static void prog_irq_msix_user(struct bdma_dev *pddev, bool clear)
{
	u32 i;	
	int j;
	u32 max;	
	struct intr_regs *int_regs;
	
	int_regs = (struct intr_regs *)(pddev->bar[pddev->cfg_bar_idx] +
					  BDMA_OFS_INT_CTRL);
	i = pddev->rx_chan_max + pddev->tx_chan_max;
	max = i + pddev->user_max_event;

	for (j = 0; i < max; j++) {
		u32 val = 0;
		int k;
		int shift = 0;

		if (clear)
			i += 4;
		else
			for (k = 0; k < 4 && i < max; i++, k++, shift += 8)
				val |= (i & 0x1f) << shift;

		write_reg(
			val, &int_regs->usr_msi_vec[j],
			BDMA_OFS_INT_CTRL +
				((unsigned long)&int_regs->usr_msi_vec[j] -
				 (unsigned long)int_regs));

		dbg_init("vector %d, 0x%x.\n", j, val);
	}
}


static int irq_msix_user_setup(struct bdma_dev *pddev)
{
	int i;
	int j;
	int ret = 0;

	j = pddev->tx_chan_max + pddev->rx_chan_max;
	
	/* vectors set in probe_scan_for_msi() */
	for (i = 0; i < pddev->user_max_event; i++, j++) {
#if KERNEL_VERSION(4, 12, 0) <= LINUX_VERSION_CODE
		u32 vector = pci_irq_vector(pddev->pdev, j);
#else
		u32 vector = pddev->entry[j].vector;
#endif
		ret = request_irq(vector, bdma_usr_irq, 0, pddev->mod_name,
				 &pddev->usr_irq[i]);
		if (ret) {
			pr_info("user %d couldn't use IRQ#%d, %d\n", i, vector,
				ret);
			break;
		}
		pr_info("%d-USR-%d, IRQ#%d with 0x%p\n", pddev->idx, i, vector,
			&pddev->usr_irq[i]);
	}

	/* If any errors occur, free IRQs that were successfully requested */
	if (ret) {
		for (i--, j--; i >= 0; i--, j--) {
#if KERNEL_VERSION(4, 12, 0) <= LINUX_VERSION_CODE
			u32 vector = pci_irq_vector(pddev->pdev, j);
#else
			u32 vector = pddev->entry[j].vector;
#endif
			free_irq(vector, &pddev->usr_irq[i]);
		}
	}

	return ret;
}


static int irq_msix_channel_setup(struct bdma_dev *pddev)
{
	int i;
	int j;
	int ret = 0;
	u32 vector;
	struct bdma_engine *engine;

	if (!pddev) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	if (!pddev->msix_en)
		return 0;

	j = pddev->tx_chan_max;
	engine = pddev->eng_tx;
	for (i = 0; i < pddev->tx_chan_max; i++, engine++) {
#if KERNEL_VERSION(4, 12, 0) <= LINUX_VERSION_CODE
		vector = pci_irq_vector(pddev->pdev, i);
#else
		vector = pddev->entry[i].vector;
#endif
		ret = request_irq(vector, bdma_channel_irq, 0, pddev->mod_name,
				 engine);
		if (ret) {
			pr_info("requesti irq#%d failed %d, engine %s.\n",
				vector, ret, engine->name);
			return ret;
		}
		pr_info("engine %s, irq#%d.\n", engine->name, vector);
		engine->msix_irq_line = vector;
	}

	engine = pddev->eng_rx;
	for (i = 0; i < pddev->rx_chan_max; i++, j++, engine++) {
#if KERNEL_VERSION(4, 12, 0) <= LINUX_VERSION_CODE
		vector = pci_irq_vector(pddev->pdev, j);
#else
		vector = pddev->entry[j].vector;
#endif
		ret = request_irq(vector, bdma_channel_irq, 0, pddev->mod_name,
				 engine);
		if (ret) {
			pr_info("requesti irq#%d failed %d, engine %s.\n",
				vector, ret, engine->name);
			return ret;
		}
		pr_info("engine %s, irq#%d.\n", engine->name, vector);
		engine->msix_irq_line = vector;
	}

	return 0;
}


static void irq_msix_channel_teardown(struct bdma_dev *pddev)
{
    int j = 0;
	int i = 0;
	struct bdma_engine *engine;

	if (!pddev->msix_en)
		return;

	prog_irq_msix_channel(pddev, 1);

	engine = pddev->eng_tx;
	for (i = 0; i < pddev->tx_chan_max; i++, j++, engine++) {
		if (!engine->msix_irq_line)
			break;
		dbg_sg("Release IRQ#%d for engine %p\n", engine->msix_irq_line,
		       engine);
		free_irq(engine->msix_irq_line, engine);
	}

	engine = pddev->eng_rx;
	for (i = 0; i < pddev->rx_chan_max; i++, j++, engine++) {
		if (!engine->msix_irq_line)
			break;
		dbg_sg("Release IRQ#%d for engine %p\n", engine->msix_irq_line,
		       engine);
		free_irq(engine->msix_irq_line, engine);
	}
}


static void irq_msix_user_teardown(struct bdma_dev *pddev)
{
	int i;
	int j;

	if (!pddev) {
		pr_err("Invalid pddev\n");
		return;
	}

	if (!pddev->msix_en)
		return;

	j = pddev->tx_chan_max + pddev->rx_chan_max;

	prog_irq_msix_user(pddev, 1);

	for (i = 0; i < pddev->user_max_event; i++, j++) {
#if KERNEL_VERSION(4, 12, 0) <= LINUX_VERSION_CODE
		u32 vector = pci_irq_vector(pddev->pdev, j);
#else
		u32 vector = pddev->entry[j].vector;
#endif
		dbg_init("user %d, releasing IRQ#%d\n", i, vector);
		free_irq(vector, &pddev->usr_irq[i]);
	}
}


static int irq_legacy_setup(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	u32 tmp;
	u8 val;
	void *reg;
	int ret;

	pci_read_config_byte(pdev, PCI_INTERRUPT_PIN, &val);
	if (val == 0) {
		dbg_init("Legacy interrupt not supported\n");
		return -EINVAL;
	}

	dbg_init("Legacy Interrupt register value = %d\n", val);
	if (val > 1) {
		val--;
		tmp = (val << 24) | (val << 16) | (val << 8) | val;
		/* Program IRQ Block Channel vector and IRQ Block User vector
		 * with Legacy inter value
		 */
		reg = pddev->bar[pddev->cfg_bar_idx] + 0x2080; // IRQ user
		write_reg(tmp, reg, 0x2080);
		write_reg(tmp, reg + 0x4, 0x2084);
		write_reg(tmp, reg + 0x8, 0x2088);
		write_reg(tmp, reg + 0xC, 0x208C);
		reg = pddev->bar[pddev->cfg_bar_idx] + 0x20A0; // IRQ Block
		write_reg(tmp, reg, 0x20A0);
		write_reg(tmp, reg + 0x4, 0x20A4);
	}

	pddev->irq_line = (int)pdev->irq;
	ret = request_irq(pdev->irq, bdma_isr, IRQF_SHARED, pddev->mod_name,
			 pddev);
	if (ret)
		dbg_init("Couldn't use IRQ#%d, %d\n", pdev->irq, ret);
	else
		dbg_init("Using IRQ#%d with 0x%p\n", pdev->irq, pddev);

	return ret;
}


static int irq_msi_setup(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	int ret;

	pddev->irq_line = (int)pdev->irq;
	ret = request_irq(pdev->irq, bdma_isr, 0, pddev->mod_name, pddev);
	if (ret)
		dbg_init("Couldn't use IRQ#%d, %d\n", pdev->irq, ret);
	else
		dbg_init("Using IRQ#%d with 0x%p\n", pdev->irq, pddev);

	return ret;
}

static void irq_teardown(struct bdma_dev *pddev)
{
	if (pddev->msix_en) {
		irq_msix_channel_teardown(pddev);
		irq_msix_user_teardown(pddev);
	} else if (pddev->irq_line != -1) {
		dbg_init("Releasing IRQ#%d\n", pddev->irq_line);
		free_irq(pddev->irq_line, pddev);
	}
}

static int irq_setup(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	pci_keep_intx_enabled(pdev);

	if (pddev->msix_en) {
		int ret = irq_msix_channel_setup(pddev);

		if (ret)
			return ret;
		ret = irq_msix_user_setup(pddev);
		if (ret)
			return ret;
		prog_irq_msix_channel(pddev, 0);
		prog_irq_msix_user(pddev, 0);

		return 0;
	} else if (pddev->msi_en)
		return irq_msi_setup(pddev, pdev);

	return irq_legacy_setup(pddev, pdev);
}

#ifdef __LIBBDMA_DEBUG__
static void dump_desc(struct bdma_desc *desc_virt)
{
	int j;
	u32 *p;
	
	p = (u32 *)desc_virt;
	static char *const field_name[] = { "magic|extra_adjacent|ctrl",
					    "bytes",
					    "src_addr_lo",
					    "src_addr_hi",
					    "dst_addr_lo",
					    "dst_addr_hi",
					    "next_addr",
					    "next_addr_pad" };
	char *dummy;

	/* remove warning about unused variable when debug printing is off */
	dummy = field_name[0];

	for (j = 0; j < 8; j += 1) {
		pr_info("0x%08lx/0x%02lx: 0x%08x 0x%08x %s\n", (uintptr_t)p,
			(uintptr_t)p & 15, (int)*p, le32_to_cpu(*p),
			field_name[j]);
		p++;
	}
	pr_info("\n");
}

static void transfer_dump(struct bdma_transfer *trans)
{
	int i;
	struct bdma_desc *desc_virt;

	desc_virt = trans->desc_virt;

	pr_info("eng 0x%p, state 0x%x, f 0x%x, dir %d, len %u, last %d.\n",
		trans, trans->state, trans->flags, trans->dir,
		trans->len, trans->last_in_req);

	pr_info("trans 0x%p, desc %d, bus 0x%llx, adj %d.\n", trans,
		trans->desc_num, (u64)trans->desc_bus,
		trans->desc_adj);
	for (i = 0; i < trans->desc_num; i += 1)
		dump_desc(desc_virt + i);
}
#endif /* __LIBBDMA_DEBUG__ */

/* bdma_desc_link() - Link two descriptors *
 * Link the first descriptor to a second descriptor.
 *
 * @first first desc
 * @second second desc, or NULL if first descriptor must be set as last.
 * @second_bus bus address of second descriptor
 */
static void bdma_desc_link(struct bdma_desc *first, struct bdma_desc *second,
			   dma_addr_t second_bus)
{
	/*
	 * remember reserved ctrl in first descriptor, but zero extra_adjacent!
	 */
	u32 ctrl = le32_to_cpu(first->ctrl) & 0x00FFC0ffUL;
	/* second descriptor given? */
	if (second) {
		first->next_lo = cpu_to_le32(PCI_DMA_L(second_bus));
		first->next_hi = cpu_to_le32(PCI_DMA_H(second_bus));
		WARN_ON(first->next_hi);
		/* no second descriptor given */
	} else {
		/* first descriptor is the last */
		first->next_lo = 0;
		first->next_hi = 0;
	}
	/* merge magic, extra_adjacent and ctrl field */
	ctrl |= DESC_MAGIC;

	/* write bytes and next_num */
	first->ctrl = cpu_to_le32(ctrl);
}

/* bdma_desc_adj -- set how many descs are adjacent to this */
static void bdma_desc_adj(struct bdma_desc *desc, u32 next_adj)
{
	/* remember reserved and ctrl bits */
	u32 ctrl = le32_to_cpu(desc->ctrl) & 0x0000f0ffUL;
	/* merge adjacent and ctrl field */
	ctrl |= 0xCB2D0000UL | (next_adj << 8); //0xAD4B0000UL
	/* write ctrl and next_adjacent */
	desc->ctrl = cpu_to_le32(ctrl);
}


/* bdma_desc() - Fill a descriptor with the trans details *
 * @desc pointer 
 * @addr root complex address
 * @ep_addr end point address
 * @len number of bytes, must be a (non-negative) multiple of 4.
 * @dir, dma direction
 * is the end point address. If zero, vice versa. *
 * Does not modify the next pointer
 */
static void bdma_desc_set(struct bdma_desc *desc, dma_addr_t rc_bus_addr,
			  u64 ep_addr, int len, int dir)
{
	/* trans length */
	desc->bytes = cpu_to_le32(len);
	if (dir == DMA_TO_DEVICE) {
		/* read from root complex memory (source address) */
		desc->src_addr_hi = cpu_to_le32(PCI_DMA_H(rc_bus_addr));
		desc->src_addr_lo = cpu_to_le32(PCI_DMA_L(rc_bus_addr));		
		/* write to end point address (destination address) */
		desc->dst_addr_hi = cpu_to_le32(PCI_DMA_H(ep_addr));
		desc->dst_addr_lo = cpu_to_le32(PCI_DMA_L(ep_addr));		
	} else {
		/* read from end point address (source address) */
		desc->src_addr_hi = cpu_to_le32(PCI_DMA_H(ep_addr));
		desc->src_addr_lo = cpu_to_le32(PCI_DMA_L(ep_addr));		
		/* write to root complex memory (destination address) */
		desc->dst_addr_hi = cpu_to_le32(PCI_DMA_H(rc_bus_addr));
		desc->dst_addr_lo = cpu_to_le32(PCI_DMA_L(rc_bus_addr));		
	}
}


/* bdma_desc_ctrl -- Set complete ctrl field of a descriptor. */
static int bdma_desc_ctrl_set(struct bdma_desc *first, u32 ctrl_field)
{
	u32 ctrl;
		
	/* remember magic and adjacent number */
	ctrl = le32_to_cpu(first->ctrl) & ~(LS_BYTE_MASK);

	if (ctrl_field & ~(LS_BYTE_MASK)) {
		pr_err("Invalid ctrl field\n");
		return -EINVAL;
	}
	/* merge adjacent and ctrl field */
	ctrl |= ctrl_field;
	/* write ctrl and next_adjacent */
	first->ctrl = cpu_to_le32(ctrl);
	return 0;
}

/* bdma_desc_done - recycle cache-coherent linked list of descriptors. *
 * @desc_virt Pointer to (i.e. virtual address of) first descriptor in list
 */
static inline void bdma_desc_done(struct bdma_desc *desc_virt, int count)
{
	memset(desc_virt, 0, count * sizeof(struct bdma_desc));
}


/* transfer_desc_init() - Chains the descriptors as a singly-linked list
 *
 * Each descriptor's next * pointer specifies the bus address of the next descriptor.
 * Terminates the last descriptor to form a singly-linked list 
 * @trans Pointer to SG DMA transfers
 * @count Number of descriptors allocated in continuous PCI bus addressable memory *
 * @return 0 on success, EINVAL on failure
 */
static int trans_desc_init(struct bdma_transfer *trans, int count)
{
	struct bdma_desc *desc_virt = trans->desc_virt;
	dma_addr_t desc_bus = trans->desc_bus;
	int i;

	/* create singly-linked list for SG DMA ctrl */
	for (i = 0; i < count - 1; i++) {
		/* increment bus address to next in array */
		desc_bus += sizeof(struct bdma_desc);

		/* singly-linked list uses bus addresses */		
		desc_virt[i].ctrl = cpu_to_le32(DESC_MAGIC);
		desc_virt[i].next_hi = cpu_to_le32(PCI_DMA_H(desc_bus));
		desc_virt[i].next_lo = cpu_to_le32(PCI_DMA_L(desc_bus));
		desc_virt[i].bytes = cpu_to_le32(0);
		
	}
	/* { i = number - 1 } */
	/* zero the last descriptor next pointer */
	desc_virt[i].ctrl = cpu_to_le32(DESC_MAGIC);	
	desc_virt[i].next_hi = cpu_to_le32(0);
	desc_virt[i].next_lo = cpu_to_le32(0);
	desc_virt[i].bytes = cpu_to_le32(0);
	
	return 0;
}


/* transfer_queue() - queue a DMA trans to the engine
*
* @engine DMA engine doing the trans
* @trans DMA trans submitted to the engine
*
* Takes and releases the engine spinlock
*/
static int trans_queue(struct bdma_engine *engine,		struct bdma_transfer *trans)
{
  int ret = 0;  
  unsigned long flags;
  struct bdma_transfer *trans_started;
  struct bdma_dev *pddev;

  if (!engine) {
	  pr_err("dma engine NULL\n");
	  return -EINVAL;
  }

  if (!engine->pddev) {
	  pr_err("Invalid pddev\n");
	  return -EINVAL;
  }

  if (!trans) {
	  pr_err("%s Invalid DMA trans\n", engine->name);
	  return -EINVAL;
  }

  if (trans->desc_num == 0) {
	  pr_err("%s void descriptors in the trans list\n",
			 engine->name);
	  return -EINVAL;
  }
  dbg_tfr("%s (trans=0x%p).\n", __func__, trans);

  pddev = engine->pddev;
  if (bdma_device_flag_check(pddev, PDEV_FLAG_OFFLINE)) {
	  pr_info("dev 0x%p offline, trans 0x%p not queued.\n", pddev,
		  trans);
	  return -EBUSY;
  }

  /* lock the engine state */
  spin_lock_irqsave(&engine->lock, flags);

  engine->prev_cpu = get_cpu();
  put_cpu();

  /* engine is being shutdown; do not accept new transfers */
  if (engine->shutdown & ENGINE_SHUTDOWN_REQUEST) {
	  pr_info("engine %s offline, trans 0x%p not queued.\n",
		  engine->name, trans);
	  ret = -EBUSY;
	  goto shutdown;
  }

  /* mark the trans as submitted */
  trans->state = TRANS_STATE_SUBMITTED;
  /* add trans to the tail of the engine trans queue */
  list_add_tail(&trans->entry, &engine->trans_list);

  /* engine is idle? */
  if (!engine->running) {
	  /* start engine */
	  dbg_tfr("%s(): starting %s engine.\n", __func__, engine->name);
	  trans_started = eng_start(engine);
	  if (!trans_started) {
		  pr_err("Failed to start dma engine\n");
		  goto shutdown;
	  }
	  dbg_tfr("trans=0x%p started %s engine with trans 0x%p.\n",
		  trans, engine->name, trans_started);
  } else {
	  dbg_tfr("trans=0x%p queued, with %s engine running.\n", trans, engine->name);
  }

shutdown:
  /* unlock the engine state */
  dbg_tfr("engine->running = %d\n", engine->running);
  spin_unlock_irqrestore(&engine->lock, flags);
  return ret;
}


/*
 * should hold the engine->lock;
 */
static int trans_abort(struct bdma_engine *engine,
			  struct bdma_transfer *trans)
{
	struct bdma_transfer *head;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	if (!trans) {
		pr_err("Invalid DMA trans\n");
		return -EINVAL;
	}

	if (trans->desc_num == 0) {
		pr_err("%s void descriptors in the trans list\n",
		       engine->name);
		return -EINVAL;
	}

	pr_info("abort trans 0x%p, desc %d, engine desc queued %d.\n",
		trans, trans->desc_num, engine->desc_dequeued);

	head = list_entry(engine->trans_list.next, struct bdma_transfer, entry);
	if (head == trans)
		list_del(engine->trans_list.next);
	else
		pr_info("engine %s, trans 0x%p NOT found, 0x%p.\n",
			engine->name, trans, head);

	if (trans->state == TRANS_STATE_SUBMITTED)
		trans->state = TRANS_STATE_ABORTED;
	return 0;
}



static int trans_build(struct bdma_engine *engine,
		 struct bdma_request_cb *req, struct bdma_transfer *eng,
		 unsigned int desc_max)
{
 struct sw_desc *sdesc = &(req->sdesc[req->sw_desc_idx]);
 int i = 0;
 int j = 0;
 dma_addr_t bus = eng->res_bus;

 for (; i < desc_max; i++, j++, sdesc++) {
	 dbg_desc("sw desc %d/%u: 0x%llx, 0x%x, ep 0x%llx.\n",
		  i + req->sw_desc_idx, req->sw_desc_cnt, sdesc->addr,
		  sdesc->len, req->ep_addr);

	 /* fill in descriptor entry j with trans details */
	 bdma_desc_set(eng->desc_virt + j, sdesc->addr, req->ep_addr,
			   sdesc->len, eng->dir);
	 eng->len += sdesc->len;

	 /* for non-inc-add mode don't increment ep_addr */
	 if (!engine->no_inc_addr) {
		 req->ep_addr += sdesc->len;
	 }

	 if (engine->streaming && engine->dir == DMA_FROM_DEVICE) {
		 memset(eng->res_virt + j, 0,
			 sizeof(struct bdma_result));
		 
		 eng->desc_virt[j].src_addr_hi =
					 cpu_to_le32(PCI_DMA_H(bus));
		 eng->desc_virt[j].src_addr_lo =
					 cpu_to_le32(PCI_DMA_L(bus));
		 
		 bus += sizeof(struct bdma_result);
	 }

 }
 req->sw_desc_idx += desc_max;
 return 0;
}


static int trans_init(struct bdma_engine *engine,
		   struct bdma_request_cb *req, struct bdma_transfer *eng)
{   	
   int i = 0;
   int last = 0;
   u32 ctrl;
   u32 next_adj;
   unsigned long flags;
   unsigned int desc_max;

   desc_max = min_t(unsigned int,
			   req->sw_desc_cnt - req->sw_desc_idx,
			   engine->desc_max);

   memset(eng, 0, sizeof(*eng));

   /* lock the engine state */
   spin_lock_irqsave(&engine->lock, flags);
   /* initialize wait queue */
#if HAS_SWAKE_UP
   init_swait_queue_head(&eng->wq);
#else
   init_waitqueue_head(&eng->wq);
#endif

   /* remember direction of trans */
   eng->dir = engine->dir;
   eng->desc_index = engine->desc_idx;
   eng->desc_virt = engine->desc + engine->desc_idx;
   eng->res_virt = engine->cyc_res + engine->desc_idx;
   eng->desc_bus = engine->desc_bus +
		   (sizeof(struct bdma_desc) * engine->desc_idx);
   eng->res_bus = engine->cyc_res_bus +
		   (sizeof(struct bdma_result) * engine->desc_idx);
   

   /* Need to handle desc_used >= engine->desc_max */
   if ((engine->desc_idx + desc_max) >= engine->desc_max)
	   desc_max = engine->desc_max - engine->desc_idx;

   trans_desc_init(eng, desc_max);

   dbg_sg("eng= %p trans->desc_bus = 0x%llx.\n", eng, (u64)eng->desc_bus);
   trans_build(engine, req, eng, desc_max);

   eng->desc_adj = desc_max;

   /* terminate last descriptor */
   last = desc_max - 1;
   /* stop engine, EOP for AXI ST, req IRQ on last descriptor */
   ctrl = BDMA_DESC_STOPPED;
   ctrl |= BDMA_DESC_COMPLETED;
   ctrl |= BDMA_DESC_EOP;
  
   bdma_desc_ctrl_set(eng->desc_virt + last, ctrl);

   if (engine->eop_flush) {
	   for (i = 0; i < last; i++)
		   bdma_desc_ctrl_set(eng->desc_virt + i,
				   BDMA_DESC_COMPLETED);
	   eng->desc_comp_th = 1;
   } else
	   eng->desc_comp_th = desc_max;

   eng->desc_num = desc_max;
   engine->desc_idx = (engine->desc_idx + desc_max) % engine->desc_max;
   engine->desc_used += desc_max;

   /* fill in adjacent numbers */
   for (i = 0; i < eng->desc_num; i++) {
	   next_adj = bdma_get_next_adj(eng->desc_num - i - 1, (eng->desc_virt + i)->next_lo);
	   dbg_desc("set next adj at index %d to %u\n", i, next_adj);
	   bdma_desc_adj(eng->desc_virt + i, next_adj);
   }

   spin_unlock_irqrestore(&engine->lock, flags);
   return 0;
}



/* trans_destroy() - free trans */
static void trans_destroy(struct bdma_dev *pddev, struct bdma_transfer *eng)
{
    /* free descriptors */
	bdma_desc_done(eng->desc_virt, eng->desc_num);

	if (eng->last_in_req && (eng->flags & TRAN_FLAG_NEED_UNMAP)) {
		struct sg_table *sgt = eng->sgt;

		if (sgt->nents) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
			pci_unmap_sg(pddev->pdev, sgt->sgl, sgt->nents, eng->dir);
#else
			dma_unmap_sg(&pddev->pdev->dev, sgt->sgl, sgt->nents, eng->dir);
#endif
			sgt->nents = 0;
		}
	}
}





#ifdef __LIBBDMA_DEBUG__
static void sgt_dump(struct sg_table *sgt)
{
	int i;
	struct scatterlist *sg;

	sg = sgt->sgl;

	pr_info("sgt 0x%p, sgl 0x%p, nents %u/%u.\n", sgt, sgt->sgl, sgt->nents, sgt->orig_nents);

	for (i = 0; i < sgt->orig_nents; i++, sg = sg_next(sg))
		pr_info("%d, 0x%p, pg 0x%p,%u+%u, dma 0x%llx,%u.\n", i, sg,
			sg_page(sg), sg->offset, sg->length, sg_dma_address(sg),
			sg_dma_len(sg));
}

static void bdma_request_cb_dump(struct bdma_request_cb *req)
{
	int i;

	pr_info("request 0x%p, total %u, ep 0x%llx, sw_desc %u, sgt 0x%p.\n",
		req, req->total_len, req->ep_addr, req->sw_desc_cnt, req->sgt);
	sgt_dump(req->sgt);
	for (i = 0; i < req->sw_desc_cnt; i++)
		pr_info("%d/%u, 0x%llx, %u.\n", i, req->sw_desc_cnt,
			req->sdesc[i].addr, req->sdesc[i].len);
}
#endif



static int set_dma_mask(struct pci_dev *pdev)
{
	if (!pdev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	dbg_init("sizeof(dma_addr_t) == %ld\n", sizeof(dma_addr_t));
	/* 64-bit addressing capability for BDMA? */
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
	if (!pci_set_dma_mask(pdev, DMA_BIT_MASK(64))) 
#else
	if (!dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(64))) 
#endif
	{
		/* query for DMA trans */
		/* @see Documentation/DMA-mapping.txt */
		dbg_init("set_dma_mask(64)\n");
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		pci_set_consistent_dma_mask(pdev, DMA_BIT_MASK(64));
#endif
		/* use 64-bit DMA */
		dbg_init("Using a 64-bit DMA mask.\n");
	} else 
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
	if (!pci_set_dma_mask(pdev, DMA_BIT_MASK(32))) 
#else
	if (!dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(32))) 
#endif
	{
		dbg_init("Could not set 64-bit DMA mask.\n");
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		pci_set_consistent_dma_mask(pdev, DMA_BIT_MASK(32));
#endif
		/* use 32-bit DMA */
		dbg_init("Using a 32-bit DMA mask.\n");
	} else {
		dbg_init("No suitable DMA possible.\n");
		return -EINVAL;
	}

	return 0;
}



static int get_eng_id(struct engine_regs *regs)
{
	int value;

	if (!regs) {
		pr_err("Invalid engine registers\n");
		return -EINVAL;
	}

	value = read_reg(&regs->eng_id);
	return (value & 0xffff0000U) >> 16;
}


static int get_eng_channel_id(struct engine_regs *regs)
{
	int value;

	if (!regs) {
		pr_err("Invalid engine registers\n");
		return -EINVAL;
	}

	value = read_reg(&regs->eng_id);

	return (value & 0x00000f00U) >> 8;
}


static struct bdma_dev *alloc_dev_instance(struct pci_dev *pdev)
{
	int i;
	struct bdma_dev *pddev;
	struct bdma_engine *engine;

	if (!pdev) {
		pr_err("Invalid pddev\n");
		return NULL;
	}

	/* allocate zeroed device book keeping structure */
	pddev = kzalloc(sizeof(struct bdma_dev), GFP_KERNEL);
	if (!pddev) {
		pr_info("OOM, bdma_dev.\n");
		return NULL;
	}
	spin_lock_init(&pddev->lock);

	pddev->magic = MAGIC_DEVICE;
	pddev->cfg_bar_idx = -1;	
	pddev->byp_bar_idx = -1;
	pddev->usr_bar_idx = -1;
	pddev->irq_line = -1;

	/* create a driver to device reference */
	pddev->pdev = pdev;
	dbg_init("pddev = 0x%p\n", pddev);

	/* Set up data user IRQ data structures */
	for (i = 0; i < 16; i++) {
		pddev->usr_irq[i].pddev = pddev;
		spin_lock_init(&pddev->usr_irq[i].events_lock);
		init_waitqueue_head(&pddev->usr_irq[i].events_wq);		
		pddev->usr_irq[i].user_idx = i; /* 0 based */
		pddev->usr_irq[i].handler = NULL;
	}

	engine = pddev->eng_tx;
	for (i = 0; i < BDMA_CHAN_NUM_MAX; i++, engine++) {
		spin_lock_init(&engine->lock);
		mutex_init(&engine->desc_lock);
		INIT_LIST_HEAD(&engine->trans_list);
#if HAS_SWAKE_UP
		init_swait_queue_head(&engine->shutdown_wq);
		init_swait_queue_head(&engine->bdma_perf_wq);
#else
		init_waitqueue_head(&engine->shutdown_wq);
		init_waitqueue_head(&engine->bdma_perf_wq);
#endif
	}

	engine = pddev->eng_rx;
	for (i = 0; i < BDMA_CHAN_NUM_MAX; i++, engine++) {
		spin_lock_init(&engine->lock);
		mutex_init(&engine->desc_lock);
		INIT_LIST_HEAD(&engine->trans_list);
#if HAS_SWAKE_UP
		init_swait_queue_head(&engine->shutdown_wq);
		init_swait_queue_head(&engine->bdma_perf_wq);
#else
		init_waitqueue_head(&engine->shutdown_wq);
		init_waitqueue_head(&engine->bdma_perf_wq);
#endif
	}

	return pddev;
}

/*requst a regions*/
static int request_regions(struct bdma_dev *pddev, struct pci_dev *pdev)
{
	int ret;

	if (!pddev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	if (!pdev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	dbg_init("pci_request_regions()\n");
	ret = pci_request_regions(pdev, pddev->mod_name);
	/* could not request all regions? */
	if (ret) {
		dbg_init("pci_request_regions() = %d, device in use?\n", ret);
		/* assume device is in use so do not disable it later */
		pddev->dev_is_use = 1;
	} else {
		pddev->got_dev = 1;
	}

	return ret;
}

/*probe the engine*/
static int probe_for_engine(struct bdma_dev *pddev, enum dma_data_direction dir,
			    int channel)
{
	struct engine_regs *regs;
	int offset;
	u32 engine_id;
	u32 engine_id_expected;
	u32 channel_id;
	struct bdma_engine *engine;
	int ret;


	offset = channel * CHANNEL_SPACING;

	/* register offset for the engine */
	/* read channels at 0x0000, write channels at 0x1000,
	 * channels at 0x100 interval
	 */
	if (dir == DMA_TO_DEVICE) {
		engine_id_expected = BDMA_ID_TX;
		engine = &pddev->eng_tx[channel];
	} else {
		offset += TX_CHANNEL_OFFSET;
		engine_id_expected = BDMA_ID_RX;
		engine = &pddev->eng_rx[channel];
	}

	regs = pddev->bar[pddev->cfg_bar_idx] + offset;
	channel_id = get_eng_channel_id(regs);
	engine_id = get_eng_id(regs);	

	if ((engine_id != engine_id_expected) || (channel_id != channel)) {
		dbg_init(
			"%s %d engine, reg off 0x%x, id mismatch 0x%x,0x%x,exp 0x%x,0x%x, SKIP.\n",
			dir == DMA_TO_DEVICE ? "TX" : "RX", channel, offset,
			engine_id, channel_id, engine_id_expected,
			channel_id != channel);
		return -EINVAL;
	}

	dbg_init("found AXI %s %d engine, reg. off 0x%x, id 0x%x,0x%x.\n",
		 dir == DMA_TO_DEVICE ? "TX" : "RX", channel, offset, engine_id, channel_id);

	/* allocate and initialize engine */
	ret = eng_init(engine, pddev, offset, dir, channel);
	if (ret != 0) {
		pr_info("failed to create AXI %s %d engine.\n", dir == DMA_TO_DEVICE ? "TX" : "RX", channel);
		return ret;
	}

	return 0;
}

static int probe_engines(struct bdma_dev *pddev)
{
	int i;
	int ret;

	if (!pddev) {
		pr_err("Invalid pddev\n");
		return -EINVAL;
	}

	/* iterate over channels */
	for (i = 0; i < pddev->tx_chan_max; i++) {
		ret = probe_for_engine(pddev, DMA_TO_DEVICE, i);
		if (ret) {
			break;
		}
	}
	pddev->tx_chan_max = i;

	for (i = 0; i < pddev->rx_chan_max; i++) {
		ret = probe_for_engine(pddev, DMA_FROM_DEVICE, i);
		if (ret) {
			break;
		}
	}
	pddev->rx_chan_max = i;

	return 0;
}


static void remove_engines(struct bdma_dev *pddev)
{
	int i;
	int ret;	
	struct bdma_engine *engine;

	if (!pddev) {
		pr_err("Invalid pddev\n");
		return;
	}

	/* iterate over channels */
	for (i = 0; i < pddev->tx_chan_max; i++) {
		engine = &pddev->eng_tx[i];
		if (engine->magic == MAGIC_ENGINE) {
			dbg_sg("Remove %s, %d", engine->name, i);
			ret = eng_destroy(pddev, engine);
			if (ret < 0)
				pr_err("Failed to destroy TX engine %d\n", i);
			dbg_sg("%s, %d removed", engine->name, i);
		}
	}

	for (i = 0; i < pddev->rx_chan_max; i++) {
		engine = &pddev->eng_rx[i];
		if (engine->magic == MAGIC_ENGINE) {
			dbg_sg("Remove %s, %d", engine->name, i);
			ret = eng_destroy(pddev, engine);
			if (ret < 0)
				pr_err("Failed to destroy RX engine %d\n", i);
			dbg_sg("%s, %d removed", engine->name, i);
		}
	}
}



static struct bdma_request_cb *bdma_request_alloc(unsigned int sdesc_nr)
{
	struct bdma_request_cb *req;
	unsigned int size ;
		
	size = sizeof(struct bdma_request_cb) + sdesc_nr * sizeof(struct sw_desc);

	req = kzalloc(size, GFP_KERNEL);
	if (!req) {
		req = vmalloc(size);
		if (req) {
			memset(req, 0, size);
		}
	}
	if (!req) {
		pr_info("OOM, %u sw_desc, %u.\n", sdesc_nr, size);
		return NULL;
	}

	return req;
}


static void bdma_request_free(struct bdma_request_cb *req)
{
	if (((unsigned long)req) >= VMALLOC_START &&
	    ((unsigned long)req) < VMALLOC_END) {
		vfree(req);
	}
	else {
		kfree(req);
	}
}

static struct bdma_request_cb *bdma_init_request(struct sg_table *sgt,
						 u64 ep_addr)
{	
	int i, j = 0;
	int max;
	int extra = 0;
	struct bdma_request_cb *req;
	struct scatterlist *sg;

	max = sgt->nents;
	sg = sgt->sgl;

	for (i = 0; i < max; i++, sg = sg_next(sg)) {
		unsigned int len = sg_dma_len(sg);

		if (unlikely(len > desc_burst_max)) {
			extra += (len + desc_burst_max - 1) / desc_burst_max;
		}
	}

	dbg_tfr("ep 0x%llx, desc %u+%u.\n", ep_addr, max, extra);

	max += extra;
	req = bdma_request_alloc(max);
	if (!req) {
		return NULL;
	}

	req->sgt = sgt;
	req->ep_addr = ep_addr;

	for (i = 0, sg = sgt->sgl; i < sgt->nents; i++, sg = sg_next(sg)) {
		unsigned int tlen = sg_dma_len(sg);
		dma_addr_t addr = sg_dma_address(sg);

		req->total_len += tlen;
		while (tlen) {
			req->sdesc[j].addr = addr;
			if (tlen > desc_burst_max) {
				req->sdesc[j].len = desc_burst_max;
				addr += desc_burst_max;
				tlen -= desc_burst_max;
			} else {
				req->sdesc[j].len = tlen;
				tlen = 0;
			}
			j++;
		}
	}

	if (j > max) {
		pr_err("Cannot trans more than supported length %d\n", desc_burst_max);
		bdma_request_free(req);
		return NULL;
	}
	req->sw_desc_cnt = j;
#ifdef __LIBBDMA_DEBUG__
	bdma_request_cb_dump(req);
#endif
	return req;
}						 
						 
 ssize_t bdma_eng_submit(void *dev_hw, int channel, bool write, u64 ep_addr,
			  struct sg_table *sgt, bool dma_mapped, int timeout_ms)
 {
	 struct bdma_dev *pddev;
	 struct bdma_engine *engine;	 
	 int nents;
	 int ret = 0, tfer_idx = 0, i;
	 ssize_t done = 0;
	 struct scatterlist *sg;
	 enum dma_data_direction dir;
	 struct bdma_request_cb *req = NULL;


	 pddev = (struct bdma_dev *)dev_hw;
	 sg = sgt->sgl;
	 dir = write ? DMA_TO_DEVICE : DMA_FROM_DEVICE;
 
	 if (!dev_hw)
		 return -EINVAL;
 
	 if (debug_check_dev_hw(__func__, pddev->pdev, dev_hw) < 0)
		 return -EINVAL;
 
	 if (write == 0) {
		 if (channel >= pddev->rx_chan_max) {
			 pr_err("RX channel %d >= %d.\n", channel, pddev->rx_chan_max);
			 return -EINVAL;
		 }
		 engine = &pddev->eng_rx[channel];
	 } else if (write == 1) {
		 if (channel >= pddev->tx_chan_max) {
			 pr_err("TX channel %d >= %d.\n", channel, pddev->tx_chan_max);
			 return -EINVAL;
		 }
		 engine = &pddev->eng_tx[channel];
	 }
 
	 if (!engine) {
		 pr_err("dma engine NULL\n");
		 return -EINVAL;
	 }
 
	 if (engine->magic != MAGIC_ENGINE) {
		 pr_err("%s has invalid magic number %lx\n", engine->name, engine->magic);
		 return -EINVAL;
	 }
 
	 pddev = engine->pddev;
	 if (bdma_device_flag_check(pddev, PDEV_FLAG_OFFLINE)) {
		 pr_info("pddev 0x%p, offline.\n", pddev);
		 return -EBUSY;
	 }
 
	 /* check the direction */
	 if (engine->dir != dir) {
		 pr_info("0x%p, %s, %d, W %d, 0x%x/0x%x mismatch.\n", engine,
			 engine->name, channel, write, engine->dir, dir);
		 return -EINVAL;
	 }
 
	  if (dma_mapped) {
		  if (!sgt->nents) {
			  pr_err("sg table has invalid number of entries 0x%p.\n", sgt);
			  return -EIO;
		  }
	  } else {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		  nents = pci_map_sg(pddev->pdev, sg, sgt->orig_nents, dir);
#else
		  nents = dma_map_sg(&pddev->pdev->dev, sg, sgt->orig_nents, dir);
#endif
  
		  if (!nents) {
			  pr_info("map sgl failed, sgt 0x%p.\n", sgt);
			  return -EIO;
		  }
		  sgt->nents = nents;
	  }
 
	 req = bdma_init_request(sgt, ep_addr);
	 if (!req) {
		 ret = -ENOMEM;
		 goto unmap_sgl;
	 }
 
	 dbg_tfr("%s, len %u sg cnt %u.\n", engine->name, req->total_len, req->sw_desc_cnt);
 
	 sg = sgt->sgl;
	 nents = req->sw_desc_cnt;
	 mutex_lock(&engine->desc_lock);
 
	 while (nents) {
		 unsigned long flags;
		 struct bdma_transfer *eng;
 
		 /* build trans */
		 ret = trans_init(engine, req, &req->tfer[0]);
		 if (ret < 0) {
			 mutex_unlock(&engine->desc_lock);
			 goto unmap_sgl;
		 }
		 eng = &req->tfer[0];
 
		 if (!dma_mapped) {
			 eng->flags = TRAN_FLAG_NEED_UNMAP;
		 }
 
		 /* last trans for the given request? */
		 nents -= eng->desc_num;
		 if (!nents) {
			 eng->last_in_req = 1;
			 eng->sgt = sgt;
		 }
 
		 dbg_tfr("eng, %u, ep 0x%llx, done %lu, sg %u/%u.\n", eng->len,
			 req->ep_addr, done, req->sw_desc_idx, req->sw_desc_cnt);
 
#ifdef __LIBBDMA_DEBUG__
		 transfer_dump(eng);
#endif
 
		 ret = trans_queue(engine, eng);
		 if (ret < 0) {
			 mutex_unlock(&engine->desc_lock);
			 pr_info("unable to submit %s, %d.\n", engine->name, ret);
			 goto unmap_sgl;
		 }
 
		 if (engine->compthp) {
			 bdma_kthread_wakeup(engine->compthp);
		 }
 
		 if (timeout_ms > 0) {
			 pg_wait_event_interruptible_timeout(eng->wq,
				 (eng->state != TRANS_STATE_SUBMITTED),
				 msecs_to_jiffies(timeout_ms));
		 } else {
			 pg_wait_event_interruptible(eng->wq,
				 (eng->state != TRANS_STATE_SUBMITTED));
		 }
 
		 spin_lock_irqsave(&engine->lock, flags);
 
		 switch (eng->state) {
		 case TRANS_STATE_COMPLETED:
			 spin_unlock_irqrestore(&engine->lock, flags);
 
			 ret = 0;
			 dbg_tfr("trans %p, %u, ep 0x%llx compl, +%lu.\n",
				 eng, eng->len, req->ep_addr - eng->len,
				 done);
 
			 /* For RX streaming use writeback results */
			 if (engine->streaming &&
				 engine->dir == DMA_FROM_DEVICE) {
				 struct bdma_result *result = eng->res_virt;
 
				 for (i = 0; i < eng->desc_comp; i++)
					 done += result[i].length;
 
				 /* finish the whole request */
				 if (engine->eop_flush)
					 nents = 0;
			 } else {
				 done += eng->len;
			 }
 
			 break;
		 case TRANS_STATE_FAILED:
			 pr_info("eng 0x%p,%u, failed, ep 0x%llx.\n", eng,
				 eng->len, req->ep_addr - eng->len);
			 spin_unlock_irqrestore(&engine->lock, flags);
 
#ifdef __LIBBDMA_DEBUG__
			 transfer_dump(eng);
			 sgt_dump(sgt);
#endif
			 ret = -EIO;
			 break;
		 default:
			 /* trans can still be in-flight */
			 pr_info("eng 0x%p,%u, s 0x%x timed out, ep 0x%llx.\n",
				 eng, eng->len, eng->state, req->ep_addr);
			 ret = eng_status_read(engine, 0, 1);
			 if (ret < 0) {
				 pr_err("Failed to read engine status\n");
			 } else if (ret == 0) {
				 //eng_status_dump(engine);
				 ret = trans_abort(engine, eng);
				 if (ret < 0) {
					 pr_err("Failed to stop engine\n");
				 } else if (ret == 0) {
					 ret = bdma_eng_stop(engine);
					 if (ret < 0)
						 pr_err("Failed to stop engine\n");
				 }
			 }
			 spin_unlock_irqrestore(&engine->lock, flags);
 
#ifdef __LIBBDMA_DEBUG__
			 transfer_dump(eng);
			 sgt_dump(sgt);
#endif
			 ret = -ERESTARTSYS;
			 break;
		 }
 
		 engine->desc_used -= eng->desc_num;
		 trans_destroy(pddev, eng);
 
		 /* use multiple trans per request if we can't fit
		  * all data within single descriptor chain.
		  */
		 tfer_idx++;
 
		 if (ret < 0) {
			 mutex_unlock(&engine->desc_lock);
			 goto unmap_sgl;
		 }
	 } /* while (sg) */
	 mutex_unlock(&engine->desc_lock);
 
 unmap_sgl:
	 if (!dma_mapped && sgt->nents) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		 pci_unmap_sg(pddev->pdev, sgt->sgl, sgt->orig_nents, dir);
#else
		 dma_unmap_sg(&pddev->pdev->dev, sgt->sgl, sgt->orig_nents, dir);
#endif
		 sgt->nents = 0;
	 }
 
	 if (req)
		 bdma_request_free(req);
 
	 /* as long as some data is processed, return the cnt */
	 return done ? done : ret;
 }
		  

ssize_t bdma_eng_submit_nowait(void *cb_hndl, void *dev_hw, int channel,
			  bool write, u64 ep_addr, struct sg_table *sgt,
			  bool dma_mapped, int timeout_ms)
{
  struct bdma_dev *pddev;
  struct bdma_engine *engine;
  struct bdma_io_cb *cb;
  int ret = 0, tfer_idx = 0;
  struct scatterlist *sg;
  int nents;
  enum dma_data_direction dir;  
  struct bdma_transfer *eng;
  struct bdma_request_cb *req = NULL;

  pddev = (struct bdma_dev *)dev_hw;
  cb = (struct bdma_io_cb *)cb_hndl;
  sg = sgt->sgl;
  dir = write ? DMA_TO_DEVICE : DMA_FROM_DEVICE;

  if (!dev_hw) {
	  return -EINVAL;
  }

  if (debug_check_dev_hw(__func__, pddev->pdev, dev_hw) < 0) {
	  return -EINVAL;
  }

  if (write == 1) {
	  if (channel >= pddev->tx_chan_max) {
		  pr_warn("TX channel %d >= %d.\n", channel, pddev->tx_chan_max);
		  return -EINVAL;
	  }
	  engine = &pddev->eng_tx[channel];
  } else if (write == 0) {
	  if (channel >= pddev->rx_chan_max) {
		  pr_warn("RX channel %d >= %d.\n", channel, pddev->rx_chan_max);
		  return -EINVAL;
	  }
	  engine = &pddev->eng_rx[channel];
  } else {
	  pr_warn("write %d, exp. 0|1.\n", write);
	  return -EINVAL;
  }

  if (!engine) {
	  pr_err("dma engine NULL\n");
	  return -EINVAL;
  }

  if (engine->magic != MAGIC_ENGINE) {
	  pr_err("%s has invalid magic number %lx\n", engine->name, engine->magic);
	  return -EINVAL;
  }

  pddev = engine->pddev;
  if (bdma_device_flag_check(pddev, PDEV_FLAG_OFFLINE)) {
	  pr_info("pddev 0x%p, offline.\n", pddev);
	  return -EBUSY;
  }

  /* check the direction */
  if (engine->dir != dir) {
	  pr_info("0x%p, %s, %d, W %d, 0x%x/0x%x mismatch.\n",
		  engine, engine->name, channel, write, engine->dir, dir);
	  return -EINVAL;
  }

  if (dma_mapped) {
	  if (!sgt->nents) {
		  pr_err("sg table has invalid number of entries 0x%p.\n", sgt);
		  return -EIO;
	  }
  } else {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
	  nents = pci_map_sg(pddev->pdev, sg, sgt->orig_nents, dir);
#else
	  nents = dma_map_sg(&pddev->pdev->dev, sg, sgt->orig_nents, dir);
#endif
	  if (!nents) {
		  pr_info("map sgl failed, sgt 0x%p.\n", sgt);
		  return -EIO;
	  }
	  sgt->nents = nents;
  }  

  req = bdma_init_request(sgt, ep_addr);
  if (!req) {
	  ret = -ENOMEM;
	  goto unmap_sgl;
  }

  //used when doing completion.
  req->cb = cb;
  cb->req = req;
  dbg_tfr("%s, len %u sg cnt %u.\n", engine->name, req->total_len, req->sw_desc_cnt);

  sg = sgt->sgl;
  nents = req->sw_desc_cnt;
  while (nents) {
	  /* one trans at a time */
	  eng = &req->tfer[tfer_idx];
	  /* build trans */
	  ret = trans_init(engine, req, eng);
	  if (ret < 0) {
		  pr_info("trans_init failed\n");

		  if (!dma_mapped && sgt->nents) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
			  pci_unmap_sg(pddev->pdev, sgt->sgl,
					  sgt->orig_nents, dir);
#else
			  dma_unmap_sg(&pddev->pdev->dev, sgt->sgl,
					  sgt->orig_nents, dir);
#endif
			  sgt->nents = 0;
		  }

		  /* trans failed return BUSY */
		  if (cb->io_done) {
			  cb->io_done((unsigned long)cb, -EBUSY);
		  }

		  goto rel_req;
	  }

	  eng->cb = cb;

	  if (!dma_mapped) {
		  eng->flags = TRAN_FLAG_NEED_UNMAP;
	  }

	  /* last trans for the given request? */
	  nents -= eng->desc_num;
	  if (!nents) {
		  eng->last_in_req = 1;
		  eng->sgt = sgt;
	  }

	  dbg_tfr("eng %p, len %u, ep 0x%llx, sg %u/%u. nents = %d\n",
		  eng, eng->len, req->ep_addr, req->sw_desc_idx, req->sw_desc_cnt, nents);

#ifdef __LIBBDMA_DEBUG__
	  transfer_dump(eng);
#endif

	  ret = trans_queue(engine, eng);
	  if (ret < 0) {
		  pr_info("unable to submit %s, %d.\n", engine->name, ret);
		  goto unmap_sgl;
	  }

	  /* use multiple transfers per request if we could not fit all
	   * data within single descriptor chain.
	   */
	  tfer_idx++;
  }

  return -EIOCBQUEUED;

unmap_sgl:
  if (!dma_mapped && sgt->nents) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
	  pci_unmap_sg(pddev->pdev, sgt->sgl, sgt->orig_nents, dir);
#else
	  dma_unmap_sg(&pddev->pdev->dev, sgt->sgl, sgt->orig_nents, dir);
#endif
	  sgt->nents = 0;
  }

rel_req:
  if (req)
	  bdma_request_free(req);

  return ret;
}

		  

int bdma_performance_submit(struct bdma_dev *pddev, struct bdma_engine *engine)
{
  u32 max_cons_size; /* 4MB */
  struct bdma_transfer *trans;
  u64 ep_addr = 0;
  int num_desc_in_a_loop;
  int size_in_desc;
  int size;
  int i;
  int ret = -ENOMEM;
  unsigned char free_desc = 0;

  max_cons_size = BDMA_PERF_NUM_DESC * 32 * 1024;
  num_desc_in_a_loop = BDMA_PERF_NUM_DESC;
  size_in_desc = engine->bdma_perf->transfer_size;
  size = size_in_desc * num_desc_in_a_loop;

  if (size_in_desc > max_cons_size) {
	  pr_err("%s max consistent size %d is more than supported %d\n",
			 engine->name, size_in_desc, max_cons_size);
	  return -EINVAL;
  }

  if (size > max_cons_size) {
	  size = max_cons_size;
	  num_desc_in_a_loop = size / size_in_desc;
  }

  engine->perf_buf_virt = dma_alloc_coherent(&pddev->pdev->dev,
					  size_in_desc,
					  &engine->perf_buf_bus,
					  GFP_KERNEL);
  if (!engine->perf_buf_virt) {
	  pr_err("dev %s, %s DMA allocation OOM.\n",
			 dev_name(&pddev->pdev->dev), engine->name);
	  return ret;
  }

  /* allocate trans data structure */
  trans = kzalloc(sizeof(struct bdma_transfer), GFP_KERNEL);
  if (!trans) {
	  pr_err("dev %s, %s trans request OOM.\n",
			 dev_name(&pddev->pdev->dev), engine->name);
	  goto err_engine_transfer;
  }
  /* 0 = write engine (to_dev=0) , 1 = read engine (to_dev=1) */
  trans->dir = engine->dir;
  /* set number of descriptors */
  trans->desc_num = num_desc_in_a_loop;

  /* allocate descriptor list */
  if (!engine->desc) {
	  engine->desc = dma_alloc_coherent(
		  &pddev->pdev->dev,
		  num_desc_in_a_loop * sizeof(struct bdma_desc),
		  &engine->desc_bus, GFP_KERNEL);
	  if (!engine->desc) {
		  pr_err("%s DMA memory allocation for descriptors failed\n",
				 engine->name);
		  goto err_engine_desc;
	  }
	  dbg_init("device %s, engine %s pre-alloc desc 0x%p,0x%llx.\n",
		   dev_name(&pddev->pdev->dev), engine->name, engine->desc,
		   engine->desc_bus);
	  free_desc = 1;
  }
  trans->desc_virt = engine->desc;
  trans->desc_bus = engine->desc_bus;

  ret = trans_desc_init(trans, trans->desc_num);
  if (ret < 0) {
	  pr_err("Failed to initialize descriptors\n");
	  goto err_dma_desc;
  }

  dbg_sg("trans->desc_bus = 0x%llx.\n", (u64)trans->desc_bus);

  for (i = 0; i < trans->desc_num; i++) {
	  struct bdma_desc *desc = trans->desc_virt + i;
	  dma_addr_t rc_bus_addr = engine->perf_buf_bus;

	  /* fill in descriptor entry with trans details */
	  bdma_desc_set(desc, rc_bus_addr, ep_addr, size_in_desc,
				engine->dir);
  }

  /* stop engine and request inter on last descriptor */
  ret = bdma_desc_ctrl_set(trans->desc_virt, 0);
  if (ret < 0) {
	  pr_err("Failed to set desc ctrl\n");
	  goto err_dma_desc;
  }
  /* create a linked loop */
  bdma_desc_link(trans->desc_virt + trans->desc_num - 1,
			 trans->desc_virt, trans->desc_bus);

  trans->cyclic = 1;

  /* initialize wait queue */
#if HAS_SWAKE_UP
  init_swait_queue_head(&trans->wq);
#else
  init_waitqueue_head(&trans->wq);
#endif

  //printk("=== Descriptor print for PERF\n");
  //transfer_dump(trans);

  dbg_perf("Queueing BDMA I/O %s request for performance measurement.\n",
	   engine->dir ? "write (to dev)" : "read (from dev)");
  ret = trans_queue(engine, trans);
  if (ret < 0) {
	  pr_err("Failed to queue trans\n");
	  goto err_dma_desc;
  }
  return 0;

err_dma_desc:
  if (free_desc && engine->desc)
	  dma_free_coherent(&pddev->pdev->dev,
			  num_desc_in_a_loop * sizeof(struct bdma_desc),
			  engine->desc, engine->desc_bus);
  engine->desc = NULL;
err_engine_desc:
  if (trans)
	  list_del(&trans->entry);
  kfree(trans);
  trans = NULL;
err_engine_transfer:
  if (engine->perf_buf_virt) {
	  dma_free_coherent(&pddev->pdev->dev, size_in_desc,
			  engine->perf_buf_virt, engine->perf_buf_bus);
  }
  engine->perf_buf_virt = NULL;
  return ret;
}

ssize_t bdma_eng_aperture(struct bdma_engine *engine, bool write, u64 ep_addr,
			unsigned int aperture, struct sg_table *sgt,
			bool dma_mapped, int timeout_ms)
{
	struct bdma_dev *pddev;
	struct bdma_request_cb *req = NULL;
	struct scatterlist *sg;
	enum dma_data_direction dir;
	unsigned int maxlen;
	unsigned int sg_max;
	unsigned int tlen = 0;
	u64 ep_addr_max;
	ssize_t done = 0;
	int i, ret = 0;

	dir = write ? DMA_TO_DEVICE : DMA_FROM_DEVICE;
	maxlen = min_t(unsigned int, aperture, desc_burst_max);
	ep_addr_max = ep_addr + aperture - 1;

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	if (engine->magic != MAGIC_ENGINE) {
		pr_err("%s has invalid magic number %lx\n", engine->name,
		       engine->magic);
		return -EINVAL;
	}

	pddev = engine->pddev;
	if (bdma_device_flag_check(pddev, PDEV_FLAG_OFFLINE)) {
		pr_info("pddev 0x%p, offline.\n", pddev);
		return -EBUSY;
	}

	/* check the direction */
	if (engine->dir != dir) {
		pr_info("0x%p, %s, W %d, 0x%x/0x%x mismatch.\n", engine,
			engine->name, write, engine->dir, dir);
		return -EINVAL;
	}

	if (engine->streaming) {
		pr_info("%s aperture not supported in ST.\n", engine->name);
		return -EINVAL;
	}

	if (!dma_mapped) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		sgt->nents = pci_map_sg(pddev->pdev, sgt->sgl, sgt->orig_nents, dir);
#else
		sgt->nents = dma_map_sg(&pddev->pdev->dev, sgt->sgl,
					sgt->orig_nents, dir);
#endif
		if (!sgt->nents) {
			pr_info("map sgl failed, sgt 0x%p.\n", sgt);
			return -EIO;
		}
	} else if (!sgt->nents) {
		pr_err("sg table has invalid number of entries 0x%p.\n", sgt);
		return -EIO;
	}
	sg_max = sgt->nents;

	req = kzalloc(sizeof(struct bdma_request_cb), GFP_KERNEL);
	if (!req) {
		ret = -ENOMEM;
		goto unmap_sgl;
	}
	memset(req, 0, sizeof(struct bdma_request_cb));
	req->sgt = sgt;
	req->sg = sgt->sgl;
	req->ep_addr = ep_addr;
	req->aperture = aperture;	

	for (i = 0, sg = sgt->sgl; i < sgt->nents; i++, sg = sg_next(sg)) {
		tlen += sg_dma_len(sg);
	}
	
	req->total_len = tlen;

	dbg_tfr("%s, aperture: sg cnt %u.\n", engine->name, sgt->nents);

	mutex_lock(&engine->desc_lock);

	while (req->offset < req->total_len) {
		dma_addr_t desc_bus;
		unsigned long flags;
		unsigned int sg_off = req->sg_off;
		unsigned int desc_idx, desc_max, desc_cnt = 0;
		struct bdma_transfer *eng = &req->tfer[0];		
		struct bdma_desc *desc_virt;

		/* initialize trans */
		memset(eng, 0, sizeof(struct bdma_transfer));
#if HAS_SWAKE_UP
		init_swait_queue_head(&eng->wq);
#else
		init_waitqueue_head(&eng->wq);
#endif
		eng->dir = engine->dir;
		if (!dma_mapped)
			eng->flags = TRAN_FLAG_NEED_UNMAP;

		spin_lock_irqsave(&engine->lock, flags);

		desc_idx = engine->desc_idx;
		desc_max = engine->desc_max;
		
		eng->desc_index = desc_idx;
		eng->desc_virt = desc_virt = engine->desc + desc_idx;
		eng->res_virt = engine->cyc_res + desc_idx;
		eng->desc_bus = desc_bus = engine->desc_bus + (sizeof(struct bdma_desc) * desc_idx);
		eng->res_bus = engine->cyc_res_bus + (sizeof(struct bdma_result) * desc_idx);

		/* build trans */
		sg = req->sg;
		ep_addr = req->ep_addr + (req->offset & (aperture - 1));
		i = req->sg_idx;
		
		for (sg = req->sg; i < sg_max && desc_idx < desc_max;
			i++, sg = sg_next(sg)) {
			dma_addr_t addr = sg_dma_address(sg);

			tlen = sg_dma_len(sg);
			if (sg_off) {
				tlen -= sg_off;
				addr += sg_off;
			}

			while (tlen) {
				unsigned int len = min_t(unsigned int, tlen, maxlen);

				if (ep_addr > ep_addr_max) {
					ep_addr = req->ep_addr;
				}

				if ((ep_addr + len) > ep_addr_max) {
					len = ep_addr_max - ep_addr + 1;
				}

				bdma_desc_set(engine->desc + desc_idx, addr, ep_addr, len, dir);

	            dbg_desc("sg %d -> desc %u: ep 0x%llx, 0x%llx + %u \n", i, desc_idx, ep_addr, addr, len);

				eng->len += len;
				ep_addr += len;
				sg_off += len;
				req->offset += len;				
				addr += len;
				tlen -= len;
				
				desc_idx++;
				desc_cnt++;
				if (desc_idx == desc_max) {
					break;
				}
			}

			if (!tlen) {
				sg_off = 0;
			} else {
				break;
			}
		}
		
		req->sg_off = sg_off;
		req->sg_idx = i;

		eng->desc_num = desc_cnt;
		eng->desc_adj = desc_cnt;		
		engine->desc_used += desc_cnt;

		/* create the desc linked list */
		for (i = 0; i < (desc_cnt - 1); i++, desc_virt++) {
			desc_bus += sizeof(struct bdma_desc);
			/* singly-linked list uses bus addresses */
			desc_virt->next_hi = cpu_to_le32(PCI_DMA_H(desc_bus));
			desc_virt->next_lo = cpu_to_le32(PCI_DMA_L(desc_bus));
            desc_virt->ctrl = cpu_to_le32(DESC_MAGIC);
		}
		
		/* terminate the last descriptor next pointer */
		desc_virt->next_hi = cpu_to_le32(0);
		desc_virt->next_lo = cpu_to_le32(0);
		desc_virt->ctrl = cpu_to_le32(DESC_MAGIC |
					BDMA_DESC_STOPPED | BDMA_DESC_EOP |
					BDMA_DESC_COMPLETED);

		eng->desc_comp_th = desc_cnt;

		/* fill in adjacent numbers */
		for (i = 0; i < desc_cnt; i++) {
			u32 next_adj = bdma_get_next_adj(desc_cnt - i - 1,
					(eng->desc_virt + i)->next_lo);
            dbg_desc("set next adj at idx %d to %u\n", i, next_adj);
	        bdma_desc_adj(eng->desc_virt + i, next_adj);
        	}

		engine->desc_idx = (engine->desc_idx + desc_cnt) % desc_max;
		spin_unlock_irqrestore(&engine->lock, flags);

		/* last trans for the given request? */
		if (req->offset == req->total_len) {
			eng->last_in_req = 1;
			eng->sgt = sgt;
		}

		dbg_tfr("eng %u,%u/%u, ep 0x%llx/0x%x, done %ld, sg %u/%u, desc %u.\n",
			eng->len, req->offset, req->total_len, req->ep_addr,
			req->aperture, done, req->sg_idx, sg_max, desc_cnt);

		ret = trans_queue(engine, eng);
		if (ret < 0) {
			mutex_unlock(&engine->desc_lock);
			pr_info("unable to submit %s, %d.\n", engine->name, ret);
			goto unmap_sgl;
		}

		if (engine->compthp) {
			bdma_kthread_wakeup(engine->compthp);
		}

		if (timeout_ms > 0) {
			pg_wait_event_interruptible_timeout(eng->wq,
				(eng->state != TRANS_STATE_SUBMITTED),
				msecs_to_jiffies(timeout_ms));
		} else {
			pg_wait_event_interruptible(eng->wq,
				(eng->state != TRANS_STATE_SUBMITTED));
		}

		spin_lock_irqsave(&engine->lock, flags);

		switch (eng->state) {
		case TRANS_STATE_COMPLETED:
			spin_unlock_irqrestore(&engine->lock, flags);

			ret = 0;
			dbg_tfr("trans %p, %u, ep 0x%llx compl, +%lu.\n",
				eng, eng->len, req->ep_addr - eng->len,
				done);

			done += eng->len;

			break;
		case TRANS_STATE_FAILED:
			pr_info("eng 0x%p,%u, failed, ep 0x%llx.\n", eng,
				eng->len, req->ep_addr - eng->len);
			spin_unlock_irqrestore(&engine->lock, flags);

#ifdef __LIBBDMA_DEBUG__
			transfer_dump(eng);
			sgt_dump(sgt);
#endif
			ret = -EIO;
			break;
		default:
			/* trans can still be in-flight */
			pr_info("eng 0x%p,%u, s 0x%x timed out, ep 0x%llx.\n",
				eng, eng->len, eng->state, req->ep_addr);
			ret = eng_status_read(engine, 0, 1);
			if (ret < 0) {
				pr_err("failed to read engine status\n");
			} else if (ret == 0) {
				//eng_status_dump(engine);
				ret = trans_abort(engine, eng);
				if (ret < 0) {
					pr_err("Failed to stop engine\n");
				} else if (ret == 0) {
					ret = bdma_eng_stop(engine);
					if (ret < 0)
						pr_err("Failed to stop engine\n");
				}
			}
			spin_unlock_irqrestore(&engine->lock, flags);

#ifdef __LIBBDMA_DEBUG__
			transfer_dump(eng);
			sgt_dump(sgt);
#endif
			ret = -ERESTARTSYS;
			break;
		}

		engine->desc_used -= eng->desc_num;
		trans_destroy(pddev, eng);

		if (ret < 0) {
			mutex_unlock(&engine->desc_lock);
			goto unmap_sgl;
		}
	} /* while (sg) */
	mutex_unlock(&engine->desc_lock);

unmap_sgl:
	if (!dma_mapped && sgt->nents) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		pci_unmap_sg(pddev->pdev, sgt->sgl, sgt->orig_nents, dir);
#else
		dma_unmap_sg(&pddev->pdev->dev, sgt->sgl, sgt->orig_nents, dir);
#endif
		sgt->nents = 0;
	}

	if (req)
		bdma_request_free(req);

	/* as long as some data is processed, return the count */
	return done ? done : ret;
}

ssize_t bdma_eng_completion(void *cb_hndl, void *dev_hw, int channel,
			bool write, u64 ep_addr, struct sg_table *sgt,
			bool dma_mapped, int timeout_ms)
{    
	int ret = 0, tfer_idx = 0;	
	int nents;	
	int i;
	struct bdma_dev *pddev;
	struct bdma_io_cb *cb;
	struct bdma_engine *engine;
	ssize_t done = 0;
	enum dma_data_direction dir;
	struct bdma_request_cb *req = NULL;
	struct bdma_transfer *eng;
	struct bdma_result *result;

	pddev = (struct bdma_dev *)dev_hw;
	cb = (struct bdma_io_cb *)cb_hndl;
	dir = write ? DMA_TO_DEVICE : DMA_FROM_DEVICE;

	if (write == 0) {
		if (channel >= pddev->rx_chan_max) {
			pr_warn("RX channel %d >= %d.\n", channel, pddev->rx_chan_max);
			return -EINVAL;
		}
		engine = &pddev->eng_rx[channel];
	} else if (write == 1) {
		if (channel >= pddev->tx_chan_max) {
			pr_warn("TX channel %d >= %d.\n", channel, pddev->tx_chan_max);
			return -EINVAL;
		}
		engine = &pddev->eng_tx[channel];
	} else {
		pr_warn("write %d, exp. 0|1.\n", write);
		return -EINVAL;
	}	

	if (!engine) {
		pr_err("dma engine NULL\n");
		return -EINVAL;
	}

	if (engine->magic != MAGIC_ENGINE) {
		pr_err("%s has invalid magic number %lx\n", engine->name,
		       engine->magic);
		return -EINVAL;
	}

	pddev = engine->pddev;
	req = cb->req;

	nents = req->sw_desc_cnt;
	while (nents) {
		eng = &req->tfer[tfer_idx];
		nents -= eng->desc_num;
		switch (eng->state) {
		case TRANS_STATE_COMPLETED:
			dbg_tfr("trans %p, %u, ep 0x%llx compl, +%lu.\n",
				eng, eng->len, req->ep_addr - eng->len,
				done);

			result = eng->res_virt;
			/* For RX streaming use writeback results */
			if (engine->streaming && engine->dir == DMA_FROM_DEVICE) {
				for (i = 0; i < eng->desc_num; i++) {
					done += result[i].length;
				}
			} else {
				done += eng->len;
			}

			ret = 0;
			break;
		case TRANS_STATE_FAILED:
			pr_info("eng 0x%p,%u, failed, ep 0x%llx.\n", eng, eng->len, req->ep_addr - eng->len);

#ifdef __LIBBDMA_DEBUG__
			transfer_dump(eng);
			sgt_dump(sgt);
#endif
			ret = -EIO;
			break;
		default:
			/* trans can still be in-flight */
			pr_info("eng 0x%p,%u, s 0x%x timed out, ep 0x%llx.\n", eng, eng->len, eng->state, req->ep_addr);
			eng_status_read(engine, 0, 1);
			eng_status_dump(engine);
			trans_abort(engine, eng);
			bdma_eng_stop(engine);

#ifdef __LIBBDMA_DEBUG__
			transfer_dump(eng);
			sgt_dump(sgt);
#endif
			ret = -ERESTARTSYS;
			break;
		}

		trans_destroy(pddev, eng);
		engine->desc_used -= eng->desc_num;
		tfer_idx++;

		if (ret < 0) {
			goto unmap_sgl;
		}
	} /* while (sg) */

unmap_sgl:
	if (!dma_mapped && sgt->nents) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 16, 0)
		pci_unmap_sg(pddev->pdev, sgt->sgl, sgt->orig_nents, dir);
#else
		dma_unmap_sg(&pddev->pdev->dev, sgt->sgl, sgt->orig_nents, dir);
#endif
		sgt->nents = 0;
	}

	if (req) {
		bdma_request_free(req);
	}

	return done;

}




void *bdma_device_open(const char *mname, struct pci_dev *pdev, int *user_max_event,
		       int *tx_chan_max, int *rx_chan_max)
{
	struct bdma_dev *pddev = NULL;
	int ret = 0;

	pr_info("%s device %s, 0x%p.\n", mname, dev_name(&pdev->dev), pdev);

	/* allocate zeroed device book keeping structure */
	pddev = alloc_dev_instance(pdev);
	if (!pddev)
		return NULL;
	pddev->mod_name = mname;
	pddev->user_max_event = *user_max_event;
	pddev->tx_chan_max = *tx_chan_max;
	pddev->rx_chan_max = *rx_chan_max;

	bdma_device_flag_set(pddev, PDEV_FLAG_OFFLINE);

	if (pddev->user_max_event == 0 || pddev->user_max_event > MAX_USER_IRQ) {
		pddev->user_max_event = MAX_USER_IRQ;
	}
	
	if (pddev->tx_chan_max == 0 || pddev->tx_chan_max > BDMA_CHAN_NUM_MAX) {
		pddev->tx_chan_max = BDMA_CHAN_NUM_MAX;
	}
		
	if (pddev->rx_chan_max == 0 || pddev->rx_chan_max > BDMA_CHAN_NUM_MAX) {
		pddev->rx_chan_max = BDMA_CHAN_NUM_MAX;
	}

	ret = pdev_list_add(pddev);
	if (ret < 0) {
		goto free_pdev;
	}

	ret = pci_enable_device(pdev);
	if (ret) {
		dbg_init("pci_enable_device() failed, %d.\n", ret);
		goto err_enable;
	}

	/* keep INTx enabled */
	pci_check_intr_pend(pdev);

	/* enable relaxed ordering */
	pci_enable_capability(pdev, PCI_EXP_DEVCTL_RELAX_EN);

	/* enable extended tag */
	pci_enable_capability(pdev, PCI_EXP_DEVCTL_EXT_TAG);

	/* force MRRS to be 512 */
	ret = pcie_set_readrq(pdev, 512);
	if (ret) {
		pr_info("device %s, error set PCI_EXP_DEVCTL_READRQ: %d.\n",
			dev_name(&pdev->dev), ret);
	}

	/* enable bus master capability */
	pci_set_master(pdev);

	ret = request_regions(pddev, pdev);
	if (ret) {
		goto err_regions;
	}

	ret = map_bars(pddev, pdev);
	if (ret) {
		goto err_map;
	}

	ret = set_dma_mask(pdev);
	if (ret) {
		goto err_mask;
	}

	check_intr_status(pddev);
	/* explicitely zero all inter enable masks */
	chan_intr_disable(pddev, ~0);
	usr_intr_disable(pddev, ~0);
	read_interrupts(pddev);

	ret = probe_engines(pddev);
	if (ret) {
		goto err_mask;
	}

	ret = enable_msi_msix(pddev, pdev);
	if (ret < 0) {
		goto err_engines;
	}

	ret = irq_setup(pddev, pdev);
	if (ret < 0) {
		goto err_msix;
	}

	if (!poll_mode) {
		chan_intr_enable(pddev, ~0);
	}

	/* Flush writes */
	read_interrupts(pddev);

	*user_max_event = pddev->user_max_event;
	*tx_chan_max = pddev->tx_chan_max;
	*rx_chan_max = pddev->rx_chan_max;

	bdma_device_flag_clear(pddev, PDEV_FLAG_OFFLINE);
	return (void *)pddev;

err_msix:
	disable_msi_msix(pddev, pdev);
err_engines:
	remove_engines(pddev);
err_mask:
	unmap_bars(pddev, pdev);
err_map:
	if (pddev->got_dev)
		pci_release_regions(pdev);
err_regions:
	if (!pddev->dev_is_use)
		pci_disable_device(pdev);
err_enable:
	pdev_list_move(pddev);
free_pdev:
	kfree(pddev);
	return NULL;
}

void bdma_device_close(struct pci_dev *pdev, void *dev_hw)
{
	struct bdma_dev *pddev = (struct bdma_dev *)dev_hw;

	dbg_init("pddev 0x%p, pddev 0x%p.\n", pdev, dev_hw);

	if (!dev_hw) {
		return;
	}

	if (debug_check_dev_hw(__func__, pdev, dev_hw) < 0) {
		return;
	}

	dbg_sg("remove(dev = 0x%p) where pddev->dev.driver_data = 0x%p\n", pdev, pddev);
	if (pddev->pdev != pdev) {
		dbg_sg("pci_dev(0x%lx) != pddev(0x%lx)\n",
		       (unsigned long)pddev->pdev, (unsigned long)pdev);
	}

	chan_intr_disable(pddev, ~0);
	usr_intr_disable(pddev, ~0);
	read_interrupts(pddev);

	irq_teardown(pddev);
	disable_msi_msix(pddev, pdev);

	remove_engines(pddev);
	unmap_bars(pddev, pdev);

	if (pddev->got_dev) {
		dbg_init("pci_release_regions 0x%p.\n", pdev);
		pci_release_regions(pdev);
	}

	if (!pddev->dev_is_use) {
		dbg_init("pci_disable_device 0x%p.\n", pdev);
		pci_disable_device(pdev);
	}

	pdev_list_move(pddev);

	kfree(pddev);
}


void bdma_device_online(struct pci_dev *pdev, void *dev_hw)
{
	struct bdma_dev *pddev;
	struct bdma_engine *engine;
	unsigned long flags;
	int i;

	pddev = (struct bdma_dev *)dev_hw;

	if (!dev_hw) {
		return;
	}

	if (debug_check_dev_hw(__func__, pdev, dev_hw) < 0) {
		return;
	}

	pr_info("pddev 0x%p, pddev 0x%p.\n", pdev, pddev);

	for (i = 0; i < pddev->tx_chan_max; i++) {
		engine = &pddev->eng_tx[i];
		if (engine->magic == MAGIC_ENGINE) {
			eng_init_regs(engine);
			spin_lock_irqsave(&engine->lock, flags);
			engine->shutdown &= ~ENGINE_SHUTDOWN_REQUEST;
			spin_unlock_irqrestore(&engine->lock, flags);
		}
	}

	for (i = 0; i < pddev->rx_chan_max; i++) {
		engine = &pddev->eng_rx[i];
		if (engine->magic == MAGIC_ENGINE) {
			eng_init_regs(engine);
			spin_lock_irqsave(&engine->lock, flags);
			engine->shutdown &= ~ENGINE_SHUTDOWN_REQUEST;
			spin_unlock_irqrestore(&engine->lock, flags);
		}
	}

	/* re-write the inter table */
	if (!poll_mode) {
		irq_setup(pddev, pdev);

		chan_intr_enable(pddev, ~0);
		usr_intr_enable(pddev, pddev->mask_irq_usr);
		read_interrupts(pddev);
	}

	bdma_device_flag_clear(pddev, PDEV_FLAG_OFFLINE);
	pr_info("pddev 0x%p, done.\n", pddev);
}


void bdma_device_offline(struct pci_dev *pdev, void *dev_hw)
{
	struct bdma_dev *pddev;
	struct bdma_engine *engine;
	int i;
	int ret;	
	unsigned long flags;	

	pddev = (struct bdma_dev *)dev_hw;

	if (!dev_hw) {
		return;
	}

	if (debug_check_dev_hw(__func__, pdev, dev_hw) < 0) {
		return;
	}

	pr_info("pddev 0x%p, pddev 0x%p.\n", pdev, pddev);
	bdma_device_flag_set(pddev, PDEV_FLAG_OFFLINE);

	/* wait for all engines to be idle */
	for (i = 0; i < pddev->tx_chan_max; i++) {
		engine = &pddev->eng_tx[i];

		if (engine->magic == MAGIC_ENGINE) {
			spin_lock_irqsave(&engine->lock, flags);
			engine->shutdown |= ENGINE_SHUTDOWN_REQUEST;

			ret = bdma_eng_stop(engine);
			if (ret < 0) {
				pr_err("Failed to stop engine\n");
			}
			spin_unlock_irqrestore(&engine->lock, flags);
		}
	}

	for (i = 0; i < pddev->rx_chan_max; i++) {
		engine = &pddev->eng_rx[i];
		if (engine->magic == MAGIC_ENGINE) {
			spin_lock_irqsave(&engine->lock, flags);
			engine->shutdown |= ENGINE_SHUTDOWN_REQUEST;

			ret = bdma_eng_stop(engine);
			if (ret < 0) {
				pr_err("Failed to stop engine\n");
			}
			spin_unlock_irqrestore(&engine->lock, flags);
		}
	}

	/* turn off inters */
	chan_intr_disable(pddev, ~0);
	usr_intr_disable(pddev, ~0);
	read_interrupts(pddev);
	irq_teardown(pddev);

	pr_info("pddev 0x%p, done.\n", pddev);
}

int bdma_device_restart(struct pci_dev *pdev, void *dev_hw)
{
	struct bdma_dev *pddev = (struct bdma_dev *)dev_hw;

	if (!dev_hw) {
		return -EINVAL;
	}

	if (debug_check_dev_hw(__func__, pdev, dev_hw) < 0) {
		return -EINVAL;
	}

	pr_info("NOT implemented, 0x%p.\n", pddev);
	return -EINVAL;
}

int bdma_user_isr_enable(void *dev_hw, unsigned int mask)
{
	struct bdma_dev *pddev = (struct bdma_dev *)dev_hw;

	if (!dev_hw) {
		return -EINVAL;
	}

	if (debug_check_dev_hw(__func__, pddev->pdev, dev_hw) < 0) {
		return -EINVAL;
	}

	pddev->mask_irq_usr |= mask;
	/* enable user inters */
	usr_intr_enable(pddev, mask);
	read_interrupts(pddev);

	return 0;
}

int bdma_user_isr_disable(void *dev_hw, unsigned int mask)
{
	struct bdma_dev *pddev = (struct bdma_dev *)dev_hw;

	if (!dev_hw) {
		return -EINVAL;
	}

	if (debug_check_dev_hw(__func__, pddev->pdev, dev_hw) < 0) {
		return -EINVAL;
	}

	pddev->mask_irq_usr &= ~mask;
	usr_intr_disable(pddev, mask);
	read_interrupts(pddev);

	return 0;
}


int bdma_user_isr_register(void *dev_hw, unsigned int mask,
			   irq_handler_t handler, void *dev)
{
	struct bdma_dev *pddev = (struct bdma_dev *)dev_hw;
	int i;

	if (!dev_hw) {
		return -EINVAL;
	}

	if (debug_check_dev_hw(__func__, pddev->pdev, dev_hw) < 0) {
		return -EINVAL;
	}

	for (i = 0; i < pddev->user_max_event && mask; i++) {
		unsigned int bit = (1 << i);

		if ((bit & mask) == 0) {
			continue;
		}

		mask &= ~bit;
		pddev->usr_irq[i].handler = handler;
		pddev->usr_irq[i].dev = dev;
	}

	return 0;
}

int eng_mode_set(struct bdma_engine *engine, unsigned long arg)
{
	int ret;
	unsigned long dst;
	u32 tmp = BDMA_CTRL_NON_INCR_ADDR;

	dbg_perf("IOCTL_BDMA_ADDRMODE_SET\n");
	ret = get_user(dst, (int __user *)arg);

	if (ret == 0) {
		engine->no_inc_addr = !!dst;
		if (engine->no_inc_addr) {
			write_reg(
				tmp, &engine->regs->ctrl_wts,
				(unsigned long)(&engine->regs->ctrl_wts) -
					(unsigned long)(&engine->regs));
		} else {
			write_reg(
				tmp, &engine->regs->ctrl_wtc,
				(unsigned long)(&engine->regs->ctrl_wtc) -
					(unsigned long)(&engine->regs));
		}
	}
	eng_align(engine);

	return ret;
}
