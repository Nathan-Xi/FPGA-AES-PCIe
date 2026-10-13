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


#define pr_fmt(fmt)     KBUILD_MODNAME ":%s: " fmt, __func__

#include <linux/ioctl.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/aer.h>
/* include early, to verify it depends only on the headers above */
#include "libbdma_api.h"
#include "libbdma.h"
#include "bdma_mod.h"
#include "bdma_dev.h"
#include "version.h"

#define DRV_MODULE_NAME		"bdma"
#define DRV_MODULE_DESC		"pango BDMA Reference Driver"

static char version[] =
	DRV_MODULE_DESC " " DRV_MODULE_NAME " v" DRV_MODULE_VERSION "\n";

MODULE_AUTHOR("pango, Inc.");
MODULE_DESCRIPTION(DRV_MODULE_DESC);
MODULE_VERSION(DRV_MODULE_VERSION);
MODULE_LICENSE("Dual BSD/GPL");

/* SECTION: Module global variables */
static int ppdev_cnt;

static const struct pci_device_id pci_ids[] = {
	{ PCI_DEVICE(0x0755, 0x0755), },
	{0,}
};
MODULE_DEVICE_TABLE(pci, pci_ids);


static struct bdma_pci_dev *ppdev_alloc(struct pci_dev *pdev)
{
	struct bdma_pci_dev *ppdev;

	ppdev = kmalloc(sizeof(*ppdev), GFP_KERNEL);

	if (!ppdev) {
		return NULL;
	}
	memset(ppdev, 0, sizeof(*ppdev));

	ppdev->magic = MAGIC_DEVICE;
	ppdev->pdev = pdev;
	ppdev->tx_chan_max = BDMA_CHAN_NUM_MAX;
	ppdev->rx_chan_max = BDMA_CHAN_NUM_MAX;
	ppdev->user_max_event = MAX_USER_IRQ;
	
	ppdev_cnt++;
	return ppdev;
}


static void ppdev_free(struct bdma_pci_dev *ppdev)
{
	struct bdma_dev *pddev;

	pddev = ppdev->pddev;

	pr_info("ppdev 0x%p, destroy_interfaces, pddev 0x%p.\n", ppdev, pddev);
	ppdev_destroy_interfaces(ppdev);
	pr_info("ppdev 0x%p, pddev 0x%p bdma_device_close.\n", ppdev, pddev);
	bdma_device_close(ppdev->pdev, pddev);
        ppdev->pdev = NULL;
	ppdev_cnt--;

	kfree(ppdev);
}

static int probe_one(struct pci_dev *pdev, const struct pci_device_id *id)
{
	int ret = 0;
	struct bdma_pci_dev *ppdev = NULL;
	struct bdma_dev *pddev;
	void *hw_dev;

	ppdev = ppdev_alloc(pdev);
	if (!ppdev)
		return -ENOMEM;

	hw_dev = bdma_device_open(DRV_MODULE_NAME, pdev, &ppdev->user_max_event,
			&ppdev->tx_chan_max, &ppdev->rx_chan_max);
	if (!hw_dev) {
		ret = -EINVAL;
		goto err_out;
	}

	if (ppdev->user_max_event > MAX_USER_IRQ) {
		pr_err("max users limit reached\n");
		ret = -EINVAL;
		goto err_out;
	}

	if (ppdev->tx_chan_max > BDMA_CHAN_NUM_MAX) {
		pr_err("max H2C channel limit reached\n");
		ret = -EINVAL;
		goto err_out;
	}

	if (ppdev->rx_chan_max > BDMA_CHAN_NUM_MAX) {
		pr_err("max C2H channel limit reached\n");
		ret = -EINVAL;
		goto err_out;
	}

	if (!ppdev->tx_chan_max && !ppdev->rx_chan_max) {
		pr_warn("no engine found!\n");
	}

	if (ppdev->user_max_event) {
		u32 mask = (1 << (ppdev->user_max_event + 1)) - 1;

		ret = bdma_user_isr_enable(hw_dev, mask);
		if (ret) {
			goto err_out;
		}
	}

	/* make sure no duplicate */
	pddev = pdev_find_by_pdev(pdev);
	if (!pddev) {
		pr_warn("NO pdev found!\n");
		ret =  -EINVAL;
		goto err_out;
	}

	if (hw_dev != pddev) {
		pr_err("pdev handle mismatch\n");
		ret =  -EINVAL;
		goto err_out;
	}

	pr_info("%s bdma%d, pdev 0x%p, pdev 0x%p, 0x%p, usr %d, ch %d,%d.\n",
		dev_name(&pdev->dev), pddev->idx, pdev, ppdev, pddev,
		ppdev->user_max_event, ppdev->tx_chan_max, ppdev->rx_chan_max);

	ppdev->pddev = hw_dev;

	ret = ppdev_create_interfaces(ppdev);
	if (ret) {
		goto err_out;
	}

	dev_set_drvdata(&pdev->dev, ppdev);

	return 0;

err_out:
	pr_err("pdev 0x%p, err %d.\n", pdev, ret);
	ppdev_free(ppdev);
	return ret;
}

static void remove_one(struct pci_dev *pdev)
{
	struct bdma_pci_dev *ppdev;

	if (!pdev) {
		return;
	}

	ppdev = dev_get_drvdata(&pdev->dev);
	if (!ppdev) {
		return;
	}

	pr_info("pdev 0x%p, pdev 0x%p, 0x%p.\n", pdev, ppdev, ppdev->pdev);
	ppdev_free(ppdev);

	dev_set_drvdata(&pdev->dev, NULL);
}

static pci_ers_result_t bdma_error_detected(struct pci_dev *pdev,
					pci_channel_state_t state)
{
	struct bdma_pci_dev *ppdev;

	ppdev = dev_get_drvdata(&pdev->dev);

	switch (state) {
	case pci_channel_io_normal:
		return PCI_ERS_RESULT_CAN_RECOVER;
	case pci_channel_io_frozen:
		pr_warn("dev 0x%p,0x%p, frozen state error, reset controller\n", pdev, ppdev);
		bdma_device_offline(pdev, ppdev->pdev);
		pci_disable_device(pdev);
		return PCI_ERS_RESULT_NEED_RESET;
	case pci_channel_io_perm_failure:
		pr_warn("dev 0x%p,0x%p, failure state error, req. disconnect\n", pdev, ppdev);
		return PCI_ERS_RESULT_DISCONNECT;
	}
	return PCI_ERS_RESULT_NEED_RESET;
}

static pci_ers_result_t bdma_slot_reset(struct pci_dev *pdev)
{
	struct bdma_pci_dev *ppdev;

    ppdev = dev_get_drvdata(&pdev->dev);
	
	pr_info("0x%p restart after slot reset\n", ppdev);
	if (pci_enable_device_mem(pdev)) {
		pr_info("0x%p failed to renable after slot reset\n", ppdev);
		return PCI_ERS_RESULT_DISCONNECT;
	}

	pci_set_master(pdev);
	pci_restore_state(pdev);
	pci_save_state(pdev);
	
	bdma_device_online(pdev, ppdev->pdev);

	return PCI_ERS_RESULT_RECOVERED;
}

static void bdma_error_resume(struct pci_dev *pdev)
{
	struct bdma_pci_dev *ppdev;

	ppdev = dev_get_drvdata(&pdev->dev);

	pr_info("dev 0x%p,0x%p.\n", pdev, ppdev);
#if PCI_AER_NAMECHANGE
	pci_aer_clear_nonfatal_status(pdev);
#else
	pci_cleanup_aer_uncorrect_error_status(pdev);
#endif

}

#if KERNEL_VERSION(4, 13, 0) <= LINUX_VERSION_CODE
static void bdma_reset_prepare(struct pci_dev *pdev)
{
	struct bdma_pci_dev *ppdev;

	ppdev = dev_get_drvdata(&pdev->dev);

	pr_info("dev 0x%p,0x%p.\n", pdev, ppdev);
	bdma_device_offline(pdev, ppdev->pdev);
}

static void bdma_reset_done(struct pci_dev *pdev)
{
	struct bdma_pci_dev *ppdev;

	ppdev = dev_get_drvdata(&pdev->dev);

	pr_info("dev 0x%p,0x%p.\n", pdev, ppdev);
	bdma_device_online(pdev, ppdev->pdev);
}

#elif KERNEL_VERSION(3, 16, 0) <= LINUX_VERSION_CODE
static void bdma_reset_notify(struct pci_dev *pdev, bool prepare)
{
	struct bdma_pci_dev *ppdev;

	ppdev = dev_get_drvdata(&pdev->dev);

	pr_info("dev 0x%p,0x%p, prepare %d.\n", pdev, ppdev, prepare);

	if (prepare) {
		bdma_device_offline(pdev, ppdev->pdev);
	} else {
		bdma_device_online(pdev, ppdev->pdev);
	}
}
#endif

static const struct pci_error_handlers bdma_err_handler = {
	.error_detected	= bdma_error_detected,
	.slot_reset	= bdma_slot_reset,
	.resume		= bdma_error_resume,
#if KERNEL_VERSION(4, 13, 0) <= LINUX_VERSION_CODE
	.reset_prepare	= bdma_reset_prepare,
	.reset_done	= bdma_reset_done,
#elif KERNEL_VERSION(3, 16, 0) <= LINUX_VERSION_CODE
	.reset_notify	= bdma_reset_notify,
#endif
};

static struct pci_driver pci_driver = {
	.name = DRV_MODULE_NAME,
	.id_table = pci_ids,
	.probe = probe_one,
	.remove = remove_one,
	.err_handler = &bdma_err_handler,
};

static int bdma_mod_init(void)
{
	int ret;

	pr_info("%s", version);

	if (desc_burst_max > BDMA_DESC_BLEN_MAX) {
		desc_burst_max = BDMA_DESC_BLEN_MAX;
	}
	pr_info("desc_blen_max: 0x%x/%u, timeout: h2c %u c2h %u sec.\n",
		desc_burst_max, desc_burst_max, tx_timeout, rx_timeout);

	ret = bdma_cdev_init();
	if (ret < 0) {
		return ret;
	}

	return pci_register_driver(&pci_driver);
}

static void bdma_mod_exit(void)
{
	/* unregister this driver from the PCI bus driver */
	dbg_init("pci_unregister_driver.\n");
	pci_unregister_driver(&pci_driver);
	bdma_cdev_cleanup();
}

module_init(bdma_mod_init);
module_exit(bdma_mod_exit);
