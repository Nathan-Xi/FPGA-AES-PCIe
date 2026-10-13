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

#include "bdma_dev.h"

static struct class *g_bdma_class;

struct kmem_cache *cdev_cache;

enum cdev_type {
	DEV_USER,
	DEV_CTRL,
	DEV_BDMA_H2C,
	DEV_BDMA_C2H,
	DEV_BYPASS_H2C,
	DEV_BYPASS_C2H,
	DEV_BYPASS,
	DEV_PVC,
	DEV_EVENTS,
};

static const char * const devnode_names[] = {
	BDMA_NODE_NAME "%d_user",
	BDMA_NODE_NAME "%d_ctrl",	
	BDMA_NODE_NAME "%d_h2c_%d",
	BDMA_NODE_NAME "%d_c2h_%d",
	BDMA_NODE_NAME "%d_bypass_h2c_%d",
	BDMA_NODE_NAME "%d_bypass_c2h_%d",
	BDMA_NODE_NAME "%d_bypass",
    BDMA_NODE_NAME "%d_pvc",
    BDMA_NODE_NAME "%d_events_%d",
};

enum ppdev_flags_bits {
	PG_DEV_USER,
	PG_DEV_CTRL,
	PG_DEV_PVC,
	PG_DEV_EVENT,
	PG_DEV_SG,
	PG_DEV_BYPASS,
};


int pcdev_check(const char *fname, struct bdma_cdev *pcdev, bool check_engine)
{
	struct bdma_dev *pddev;

	if (!pcdev || pcdev->magic != MAGIC_CHAR) {
		pr_info("%s, pcdev 0x%p, magic 0x%lx.\n", fname, pcdev, pcdev ? pcdev->magic : 0xFFFFFFFF);
		return -EINVAL;
	}

	pddev = pcdev->pddev;
	if (!pddev || pddev->magic != MAGIC_DEVICE) {
		pr_info("%s, pddev 0x%p, magic 0x%lx.\n", fname, pddev, pddev ? pddev->magic : 0xFFFFFFFF);
		return -EINVAL;
	}

	if (check_engine) {
		struct bdma_engine *engine = pcdev->engine;

		if (!engine || engine->magic != MAGIC_ENGINE) {
			pr_info("%s, engine 0x%p, magic 0x%lx.\n", fname, engine, engine ? engine->magic : 0xFFFFFFFF);
			return -EINVAL;
		}
	}

	return 0;
}


static inline void ppdev_flag_set(struct bdma_pci_dev *ppdev,
				enum ppdev_flags_bits fbit)
{
	ppdev->flags |= 1 << fbit;
}

static inline void pcdev_flag_clear(struct bdma_pci_dev *ppdev,
				enum ppdev_flags_bits fbit)
{
	ppdev->flags &= ~(1 << fbit);
}

static inline int ppdev_flag_test(struct bdma_pci_dev *ppdev,
				enum ppdev_flags_bits fbit)
{
	return ppdev->flags & (1 << fbit);
}

#ifdef __BDMA_SYSFS__
ssize_t bdma_dev_instance_show(struct device *dev,
		struct device_attribute *attr,
		char *buf)
{
	struct bdma_pci_dev *ppdev = (struct bdma_pci_dev *)dev_get_drvdata(dev);

	return snprintf(buf, PAGE_SIZE, "%d\t%d\n",	ppdev->major, ppdev->pdev->idx);
}

static DEVICE_ATTR_RO(bdma_dev_instance);
#endif

static int config_kobject(struct bdma_cdev *pcdev, enum cdev_type type)
{
	int ret = -EINVAL;
	struct bdma_dev *pddev = pcdev->pddev;
	struct bdma_engine *engine = pcdev->engine;

	switch (type) {
	case DEV_BDMA_H2C:
	case DEV_BDMA_C2H:
	case DEV_BYPASS_H2C:
	case DEV_BYPASS_C2H:
		if (!engine) {
			pr_err("Invalid DMA engine\n");
			return ret;
		}
		ret = kobject_set_name(&pcdev->cdev.kobj, devnode_names[type], pddev->idx, engine->channel);
		break;
	case DEV_BYPASS:
	case DEV_USER:
	case DEV_CTRL:
	case DEV_PVC:
		ret = kobject_set_name(&pcdev->cdev.kobj, devnode_names[type], pddev->idx);
		break;
	case DEV_EVENTS:
		ret = kobject_set_name(&pcdev->cdev.kobj, devnode_names[type], pddev->idx, pcdev->bar);
		break;
	default:
		pr_warn("%s: UNKNOWN type 0x%x.\n", __func__, type);
		break;
	}

	if (ret) {
		pr_err("%s: type 0x%x, failed %d.\n", __func__, type, ret);
	}
	return ret;
}

int dev_open(struct inode *inode, struct file *file)
{
	struct bdma_cdev *pcdev;

	/* pointer to contain struct of the device inode */
	pcdev = container_of(inode->i_cdev, struct bdma_cdev, cdev);
	if (pcdev->magic != MAGIC_CHAR) {
		pr_err("pcdev 0x%p inode 0x%lx magic mismatch 0x%lx\n",	pcdev, inode->i_ino, pcdev->magic);
		return -EINVAL;
	}
	/* create a reference to our device in the open file */
	file->private_data = pcdev;

	return 0;
}

/*
 * Called when the device goes from used to unused.
 */
int dev_close(struct inode *inode, struct file *file)
{
	struct bdma_dev *pddev;
	struct bdma_cdev *pcdev;

	pcdev = (struct bdma_cdev *)file->private_data;

	if (!pcdev) {
		pr_err("char device with inode 0x%lx pcdev NULL\n",	inode->i_ino);
		return -EINVAL;
	}

	if (pcdev->magic != MAGIC_CHAR) {
		pr_err("pcdev 0x%p magic mismatch 0x%lx\n",	pcdev, pcdev->magic);
		return -EINVAL;
	}

	/* fetch device specific data stored earlier during open */
	pddev = pcdev->pddev;
	if (!pddev) {
		pr_err("char device with inode 0x%lx pddev NULL\n", inode->i_ino);
		return -EINVAL;
	}

	if (pddev->magic != MAGIC_DEVICE) {
		pr_err("pddev 0x%p magic mismatch 0x%lx\n", pddev, pddev->magic);
		return -EINVAL;
	}

	return 0;
}

/* create_pcdev() -- create a character device interface to data or ctrl bus
 *
 * If at least one SG DMA engine is specified, the character device interface
 * is coupled to the SG DMA file operations which operate on the data bus. If
 * no engines are specified, the interface is coupled with the ctrl bus.
 */

static int create_sys_device(struct bdma_cdev *pcdev, enum cdev_type type)
{   
	int last_param;
	struct bdma_dev *pddev;
	struct bdma_engine *engine;

	pddev = pcdev->pddev;
	engine = pcdev->engine;

	if (type == DEV_EVENTS) {
		last_param = pcdev->bar;
	} else {
		last_param = engine ? engine->channel : 0;
	}

	pcdev->sys_device = device_create(g_bdma_class, &pddev->pdev->dev,
		pcdev->cdevno, NULL, devnode_names[type], pddev->idx, last_param);

	if (!pcdev->sys_device) {
		pr_err("device_create(%s) failed\n", devnode_names[type]);
		return -1;
	}

	return 0;
}


static int create_pcdev(struct bdma_pci_dev *ppdev, struct bdma_cdev *pcdev,
			int bar, struct bdma_engine *engine,
			enum cdev_type type)
{
	int ret;
	int minor;	
	dev_t dev;
	struct bdma_dev *pddev;

	pddev = ppdev->pddev;

	spin_lock_init(&pcdev->lock);
	/* new instance? */
	if (!ppdev->major) {
		/* allocate a dynamically allocated device node */
		int ret = alloc_chrdev_region(&dev, BDMA_MINOR_BASE, BDMA_MINOR_COUNT, BDMA_NODE_NAME);

		if (ret) {
			pr_err("unable to allocate cdev region %d.\n", ret);
			return ret;
		}
		ppdev->major = MAJOR(dev);
	}

	/*
	 * do not register yet, create kobjects and name them,
	 */
	pcdev->magic = MAGIC_CHAR;
	pcdev->engine = engine;
	pcdev->bar = bar;
	pcdev->ppdev = ppdev;
	pcdev->pddev = pddev;	
	pcdev->cdev.owner = THIS_MODULE;

	ret = config_kobject(pcdev, type);
	if (ret < 0) {
		return ret;
	}

	switch (type) {
	case DEV_USER:
	case DEV_CTRL:
		/* minor number is type index for non-SGDMA interfaces */
		minor = type;
		dev_ctrl_init(pcdev);
		break;
	case DEV_PVC:
		/* minor number is type index for non-SGDMA interfaces */
		minor = type;
		dev_pvc_init(pcdev);
		break;
	case DEV_BDMA_H2C:
		minor = 32 + engine->channel;
		dev_sgdma_init(pcdev);
		break;
	case DEV_BDMA_C2H:
		minor = 36 + engine->channel;
		dev_sgdma_init(pcdev);
		break;
	case DEV_EVENTS:
		minor = 10 + bar;
		dev_event_init(pcdev);
		break;
	case DEV_BYPASS_H2C:
		minor = 64 + engine->channel;
		dev_bypass_init(pcdev);
		break;
	case DEV_BYPASS_C2H:
		minor = 68 + engine->channel;
		dev_bypass_init(pcdev);
		break;
	case DEV_BYPASS:
		minor = 100;
		dev_bypass_init(pcdev);
		break;
	default:
		pr_info("type 0x%x NOT supported.\n", type);
		return -EINVAL;
	}
	pcdev->cdevno = MKDEV(ppdev->major, minor);

	/* bring character device live */
	ret = cdev_add(&pcdev->cdev, pcdev->cdevno, 1);
	if (ret < 0) {
		pr_err("cdev_add failed %d, type 0x%x.\n", ret, type);
		goto unregister_region;
	}

	dbg_init("pcdev 0x%p, %u:%u, %s, type 0x%x.\n",	pcdev, ppdev->major, minor, pcdev->cdev.kobj.name, type);

	/* create device on our class */
	if (g_bdma_class) {
		ret = create_sys_device(pcdev, type);
		if (ret < 0) {
			goto del_cdev;
		}
	}

	return 0;

del_cdev:
	cdev_del(&pcdev->cdev);
unregister_region:
	unregister_chrdev_region(pcdev->cdevno, BDMA_MINOR_COUNT);
	return ret;
}


static int destroy_pcdev(struct bdma_cdev *cdev)
{
	if (!cdev) {
		pr_warn("cdev NULL.\n");
		return -EINVAL;
	}
	if (cdev->magic != MAGIC_CHAR) {
		pr_warn("cdev 0x%p magic mismatch 0x%lx\n", cdev, cdev->magic);
		return -EINVAL;
	}

	if (!cdev->pddev) {
		pr_err("pddev NULL\n");
		return -EINVAL;
	}

	if (!g_bdma_class) {
		pr_err("g_bdma_class NULL\n");
		return -EINVAL;
	}

	if (!cdev->sys_device) {
		pr_err("cdev sys_device NULL\n");
		return -EINVAL;
	}

	if (cdev->sys_device) {
		device_destroy(g_bdma_class, cdev->cdevno);
		}

	cdev_del(&cdev->cdev);

	return 0;
}


int ppdev_create_interfaces(struct bdma_pci_dev *ppdev)
{
	struct bdma_dev *pddev = ppdev->pddev;
	struct bdma_engine *engine;
	int i;
	int ret = 0;

        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

        pr_err("tx_chan_max %d rx_chan_max %d\n",ppdev->tx_chan_max,ppdev->rx_chan_max);
        pr_err("byp_bar_idx %d usr_bar_idx %d \n",pddev->byp_bar_idx,pddev->usr_bar_idx);
	/* initialize ctrl character device */
	ret = create_pcdev(ppdev, &ppdev->ctrl_cdev, pddev->cfg_bar_idx,	NULL, DEV_CTRL);
	if (ret < 0) {
		pr_err("create_char(ctrl_cdev) failed\n");
		goto fail;
	}
	ppdev_flag_set(ppdev, PG_DEV_CTRL);

        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

	/* initialize events character device */
	for (i = 0; i < ppdev->user_max_event; i++) {
		ret = create_pcdev(ppdev, &ppdev->events_cdev[i], i, NULL, DEV_EVENTS);
		if (ret < 0) {
			pr_err("create char event %d failed, %d.\n", i, ret);
			goto fail;
		}
	}
	ppdev_flag_set(ppdev, PG_DEV_EVENT);

        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

	/* iterate over channels */
	for (i = 0; i < ppdev->tx_chan_max; i++) {
		engine = &pddev->eng_tx[i];

		if (engine->magic != MAGIC_ENGINE) {
			continue;
		}

		ret = create_pcdev(ppdev, &ppdev->sgdma_h2c_cdev[i], i, engine, DEV_BDMA_H2C);
		if (ret < 0) {
			pr_err("create char h2c %d failed, %d.\n", i, ret);
			goto fail;
		}
	}

        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

	for (i = 0; i < ppdev->rx_chan_max; i++) {
		engine = &pddev->eng_rx[i];

		if (engine->magic != MAGIC_ENGINE) {
			continue;
		}

		ret = create_pcdev(ppdev, &ppdev->sgdma_c2h_cdev[i], i, engine, DEV_BDMA_C2H);
		if (ret < 0) {
			pr_err("create char c2h %d failed, %d.\n", i, ret);
			goto fail;
		}
	}
	ppdev_flag_set(ppdev, PG_DEV_SG);

        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

 
	/* Initialize Bypass Character Device */
	if (pddev->byp_bar_idx > 0) {
		for (i = 0; i < ppdev->tx_chan_max; i++) {
			engine = &pddev->eng_tx[i];

			if (engine->magic != MAGIC_ENGINE) {
				continue;
			}

			ret = create_pcdev(ppdev, &ppdev->bypass_h2c_cdev[i], i, engine, DEV_BYPASS_H2C);
			if (ret < 0) {
				pr_err("create h2c %d bypass I/F failed, %d.\n", i, ret);
				goto fail;
			}
		}

		for (i = 0; i < ppdev->rx_chan_max; i++) {
			engine = &pddev->eng_rx[i];

			if (engine->magic != MAGIC_ENGINE) {
				continue;
			}

			ret = create_pcdev(ppdev, &ppdev->bypass_c2h_cdev[i], i, engine, DEV_BYPASS_C2H);
			if (ret < 0) {
				pr_err("create c2h %d bypass I/F failed, %d.\n", i, ret);
				goto fail;
			}
		}

		ret = create_pcdev(ppdev, &ppdev->bypass_cdev_base,	pddev->byp_bar_idx, NULL, DEV_BYPASS);
		if (ret < 0) {
			pr_err("create bypass failed %d.\n", ret);
			goto fail;
		}
		ppdev_flag_set(ppdev, PG_DEV_BYPASS);
	}

        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

	/* initialize user character device */
	if (pddev->usr_bar_idx >= 0) {
		ret = create_pcdev(ppdev, &ppdev->user_cdev, pddev->usr_bar_idx,	NULL, DEV_USER);
		if (ret < 0) {
			pr_err("create_char(user_cdev) failed\n");
			goto fail;
		}
		ppdev_flag_set(ppdev, PG_DEV_USER);

		/* pvc */
		ret = create_pcdev(ppdev, &ppdev->pvc_cdev, pddev->usr_bar_idx, NULL, DEV_PVC);
		if (ret < 0) {
			pr_err("create pvc failed, %d.\n", ret);
			goto fail;
		}
		ppdev_flag_set(ppdev, PG_DEV_PVC);
	}
        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);

#ifdef __BDMA_SYSFS__
	/* sys file */
	ret = device_create_file(&ppdev->pdev->dev,	&dev_attr_bdma_dev_instance);
	if (ret) {
		pr_err("Failed to create device file\n");
		goto fail;
	}
#endif
        pr_err("in func %s line %d\n",__FUNCTION__,__LINE__);
	return 0;

fail:
	ret = -1;
	ppdev_destroy_interfaces(ppdev);
	return ret;
}


void ppdev_destroy_interfaces(struct bdma_pci_dev *ppdev)
{
	int i = 0;
	int ret;
#ifdef __BDMA_SYSFS__
	device_remove_file(&ppdev->pdev->dev, &dev_attr_bdma_dev_instance);
#endif

	if (ppdev_flag_test(ppdev, PG_DEV_SG)) {
		/* iterate over channels */
		for (i = 0; i < ppdev->tx_chan_max; i++) {
			/* remove SG DMA character device */
			ret = destroy_pcdev(&ppdev->sgdma_h2c_cdev[i]);
			if (ret < 0) {
				pr_err("Failed to destroy h2c pcdev %d error :0x%x\n", i, ret);
			}
		}
		for (i = 0; i < ppdev->rx_chan_max; i++) {
			ret = destroy_pcdev(&ppdev->sgdma_c2h_cdev[i]);
			if (ret < 0) {
				pr_err("Failed to destroy c2h pcdev %d error 0x%x\n", i, ret);
			}
		}
	}

	if (ppdev_flag_test(ppdev, PG_DEV_EVENT)) {
		for (i = 0; i < ppdev->user_max_event; i++) {
			ret = destroy_pcdev(&ppdev->events_cdev[i]);
			if (ret < 0) {
				pr_err("Failed to destroy cdev event %d error 0x%x\n", i, ret);
			}
		}
	}

	/* remove ctrl character device */
	if (ppdev_flag_test(ppdev, PG_DEV_CTRL)) {
		ret = destroy_pcdev(&ppdev->ctrl_cdev);
		if (ret < 0) {
			pr_err("Failed to destroy cdev ctrl event %d error 0x%x\n", i, ret);
		}
	}

	/* remove user character device */
	if (ppdev_flag_test(ppdev, PG_DEV_USER)) {
		ret = destroy_pcdev(&ppdev->user_cdev);
		if (ret < 0) {
			pr_err("Failed to destroy user cdev %d error 0x%x\n", i, ret);
		}
	}

	if (ppdev_flag_test(ppdev, PG_DEV_PVC)) {
		ret = destroy_pcdev(&ppdev->pvc_cdev);
		if (ret < 0) {
			pr_err("Failed to destroy pvc cdev %d error 0x%x\n", i, ret);
		}
	}

	if (ppdev_flag_test(ppdev, PG_DEV_BYPASS)) {
		/* iterate over channels */
		for (i = 0; i < ppdev->tx_chan_max; i++) {
			/* remove DMA Bypass character device */
			ret = destroy_pcdev(&ppdev->bypass_h2c_cdev[i]);
			if (ret < 0) {
				pr_err("Failed to destroy bypass h2c cdev %d error 0x%x\n",	i, ret);
			}
		}
		for (i = 0; i < ppdev->rx_chan_max; i++) {
			ret = destroy_pcdev(&ppdev->bypass_c2h_cdev[i]);
			if (ret < 0) {
				pr_err("Failed to destroy bypass c2h %d error 0x%x\n", i, ret);
			}
		}
		ret = destroy_pcdev(&ppdev->bypass_cdev_base);
		if (ret < 0) {
			pr_err("Failed to destroy base cdev\n");
		}
	}

	if (ppdev->major) {
		unregister_chrdev_region(MKDEV(ppdev->major, BDMA_MINOR_BASE), BDMA_MINOR_COUNT);
	}
}

int bdma_cdev_init(void)
{
	g_bdma_class = class_create(THIS_MODULE, BDMA_NODE_NAME);
	if (IS_ERR(g_bdma_class)) {
		dbg_init(BDMA_NODE_NAME ": failed to create class");
		return -EINVAL;
	}

	/* using kmem_cache_create to enable sequential cleanup */
	cdev_cache = kmem_cache_create("cdev_cache", sizeof(struct cdev_async_io), 0, SLAB_HWCACHE_ALIGN, NULL);

	if (!cdev_cache) {
		pr_info("memory allocation for cdev_cache failed. OOM\n");
		return -ENOMEM;
	}

	return 0;
}

void bdma_cdev_cleanup(void)
{
	if (cdev_cache)
		kmem_cache_destroy(cdev_cache);

	if (g_bdma_class)
		class_destroy(g_bdma_class);
}
