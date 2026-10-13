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


#define pr_fmt(fmt)	KBUILD_MODNAME ":%s: " fmt, __func__

#include "libbdma_api.h"
#include "bdma_dev.h"

#define write_reg(val, mem, off) iowrite32(val, mem)

static int copy_desc_data(struct bdma_transfer *trans, char __user *buf,
		size_t *buf_off, size_t buf_size)
{
	int i;	
	int rc = 0;
	int copy_err;

	if (!trans) {
		pr_err("Invalid user trans\n");
		return -EINVAL;
	}

	if (!buf) {
		pr_err("Invalid user buf\n");
		return -EINVAL;
	}

	if (!buf_off) {
		pr_err("Invalid user buffer offset\n");
		return -EINVAL;
	}

	/* Fill user buffer with descriptor data */
	for (i = 0; i < trans->desc_num; i++) {
		if (*buf_off + sizeof(struct bdma_desc) <= buf_size) {
			copy_err = copy_to_user(&buf[*buf_off],
				trans->desc_virt + i,
				sizeof(struct bdma_desc));

			if (copy_err) {
				dbg_sg("copy to user buffer failed\n");
				*buf_off = buf_size;
				rc = -EINVAL;
			} else {
				*buf_off += sizeof(struct bdma_desc);
			}
		} else {
			rc = -ENOMEM;
		}
	}

	return rc;
}


static ssize_t bypass_write(struct file *file, const char __user *buf,
		size_t count, loff_t *pos)
{
    u32 desc_data;
	int rc = 0;
	int copy_err;
	size_t buf_off = 0;
	void __iomem *bypass_addr;
	struct bdma_dev *pddev;
	struct bdma_engine *engine;
	struct bdma_cdev *pcdev;	

	pcdev = (struct bdma_cdev *)file->private_data;

	rc = pcdev_check(__func__, pcdev, 1);
	if (rc < 0) {
		return rc;
	}
	
	engine = pcdev->engine;
	pddev = pcdev->pddev;

	if (!buf) {
		dbg_sg("caught null pointer\n");
		return -EINVAL;
	}

	if (count & 3) {
		dbg_sg("buffer size must be a multiple of 4 bytes\n");
		return -EINVAL;
	}	

	if (pddev->byp_bar_idx < 0) {
		dbg_sg("bypass BAR not present!\n");
		return -ENODEV;
	}

	dbg_sg("in %s()\n", __func__);

	spin_lock(&engine->lock);

	/* Write descriptor data to the bypass BAR */
	bypass_addr = pddev->bar[pddev->byp_bar_idx];
	bypass_addr = (void __iomem *)((u32 __iomem *)bypass_addr + engine->byp_off);
	
	while (buf_off < count) {
		copy_err = copy_from_user(&desc_data, &buf[buf_off], sizeof(u32));
		if (!copy_err) {
			write_reg(desc_data, bypass_addr, bypass_addr - engine->byp_off);
			buf_off += sizeof(u32);
			rc = buf_off;
		} else {
			dbg_sg("Error reading data from userspace buffer\n");
			rc = -EINVAL;
			break;
		}
	}

	spin_unlock(&engine->lock);
	
	return rc;
}


static ssize_t bypass_read(struct file *file, char __user *buf,
		size_t count, loff_t *pos)
{
    size_t buf_off = 0;
	int rc = 0;
	struct bdma_dev *pddev;
	struct bdma_engine *engine;
	struct bdma_cdev *pcdev;
	struct bdma_transfer *trans;
	struct list_head *idx;

	pcdev = (struct bdma_cdev *)file->private_data;

	rc = pcdev_check(__func__, pcdev, 1);
	if (rc < 0) {
		return rc;
	}
	pddev = pcdev->pddev;
	engine = pcdev->engine;

	dbg_sg("in %s()\n", __func__);
	
	if (!buf) {
		dbg_sg("Caught NULL pointer\n");
		return -EINVAL;
	}

	if (pddev->byp_bar_idx < 0) {
		dbg_sg("bypass BAR not present!\n");
		return -ENODEV;
	}

	if (count & 3) {
		dbg_sg("buffer size must be a multiple of 4 bytes\n");
		return -EINVAL;
	}

	spin_lock(&engine->lock);

	if (!list_empty(&engine->trans_list)) {
		list_for_each(idx, &engine->trans_list) {
			trans = list_entry(idx, struct bdma_transfer, entry);

			rc = copy_desc_data(trans, buf, &buf_off, count);
		}
	}

	spin_unlock(&engine->lock);

	if (rc < 0) {
		return rc;
	} else {
		return buf_off;
	}
}

/*
 * character device file operations for bypass operation
 */

static const struct file_operations bypass_fops = {
	.owner = THIS_MODULE,
	.open = dev_open,
	.release = dev_close,
	.read = bypass_read,
	.write = bypass_write,
	.mmap = bridge_mmap,
};
	
void dev_bypass_init(struct bdma_cdev *pcdev)
{
	cdev_init(&pcdev->cdev, &bypass_fops);
}
