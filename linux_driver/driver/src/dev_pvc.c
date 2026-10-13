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
#include "dev_pvc.h"

#define COMPLETION_LOOP_MAX	100

#define PVC_BAR_LENGTH_REG	0x0
#define PVC_BAR_TMS_REG		0x4
#define PVC_BAR_TDI_REG		0x8
#define PVC_BAR_TDO_REG		0xC
#define PVC_BAR_CTRL_REG	0x10

#ifdef __REG_DEBUG__
/* SECTION: Function definitions */

inline u32 __read_register(const char *fn, void __iomem *base, unsigned int off)
{
	u32 val = ioread32(base + off);
	pr_info("%s: 0x%p, R reg 0x%lx, 0x%x.\n", fn, base, off, val);
	return val;
}

inline void __write_register(const char *fn, u32 value, void __iomem *base,
				unsigned int off)
{
	pr_info("%s: 0x%p, W reg 0x%lx, 0x%x.\n", fn, base, off, value);
	iowrite32(value, base + off);
}

#define read_register(base, off) __read_register(__func__, base, off)
#define write_register(val, base, off) __write_register(__func__, val, base, off)
#else
#define read_register(base, off)		ioread32((base) + (off))
#define write_register(val, base, off)	iowrite32(val, (base) + (off))
#endif /* #ifdef __REG_DEBUG__ */


static int pvc_shift_bits(void __iomem *base, u32 tms_bits, u32 tdi_bits,
			u32 *tdo_bits)
{
	u32 ctrl;
	int count;

    /* set tdi bits and shift data out */
	write_register(tdi_bits, base, PVC_BAR_TDI_REG);
	/* set tms bit */
	write_register(tms_bits, base, PVC_BAR_TMS_REG);
	/* enable shift operation */
	write_register(0x1, base, PVC_BAR_CTRL_REG);

	/* poll for completion */
	count = COMPLETION_LOOP_MAX;
	while (count) {
		/* read ctrl reg to check shift operation completion */
		ctrl = read_register(base, PVC_BAR_CTRL_REG);
		if ((ctrl & 0x01) == 0) {
			break;
		}

		count--;
	}

	if (!count)	{
		pr_warn("PVC bar transaction timed out (0x%0X)\n", ctrl);
		return -ETIMEDOUT;
	}

	/* read tdo bits back out */
	*tdo_bits = read_register(base, PVC_BAR_TDO_REG);

	return 0;
}

static long pvc_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{	
	int ret;	
	u32 tms_store = 0;
	u32 tdi_store = 0;
	u32 tdo_store = 0;
	unsigned int bytes;
	unsigned int shift_bytes;	
	unsigned int opcode;	
	unsigned int total_bits;
	unsigned int total_bytes;
	unsigned int bits, bits_left;
	
	unsigned char *tdi_buf = NULL;	
	unsigned char *buffer = NULL;
	unsigned char *tdo_buf = NULL;
	unsigned char *tms_buf = NULL;

	void __iomem *iobase;
	struct bdma_cdev *pcdev;
	struct bdma_dev *pddev;
	struct pvc_ioc pvc_obj;

	pcdev = (struct bdma_cdev *)filp->private_data;

	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0) {
		return ret;
	}

	pddev = pcdev->pddev;

	if (cmd != BDMA_IOCPVC) {
		pr_info("ioctl 0x%x, UNKNOWN cmd.\n", cmd);
		return -ENOIOCTLCMD;
	}

	ret = copy_from_user((void *)&pvc_obj, (void __user *)arg, sizeof(struct pvc_ioc));
	/* anything not copied ? */
	if (ret) {
		pr_info("copy_from_user pvc_obj failed: %d.\n", ret);
		goto cleanup;
	}

	opcode = pvc_obj.opcode;

	/* Invalid operation type, no operation performed */
	if (opcode != 0x01 && opcode != 0x02) {
		pr_info("UNKNOWN opcode 0x%x.\n", opcode);
		return -EINVAL;
	}

	total_bits = pvc_obj.length;
	total_bytes = (total_bits + 7) >> 3;

	buffer = kmalloc(total_bytes * 3, GFP_KERNEL);
	if (!buffer) {
		pr_info("OOM %u, op 0x%x, len %u bits, %u bytes.\n",
			3 * total_bytes, opcode, total_bits, total_bytes);
		ret = -ENOMEM;
		goto cleanup;
	}
	tms_buf = buffer;
	tdi_buf = tms_buf + total_bytes;
	tdo_buf = tdi_buf + total_bytes;

	ret = copy_from_user((void *)tms_buf,
			(const char __user *)pvc_obj.tms_buf,
			total_bytes);
	if (ret) {
		pr_info("copy tmfs_buf failed: %d/%u.\n", ret, total_bytes);
		goto cleanup;
	}
	ret = copy_from_user((void *)tdi_buf,
			(const char __user *)pvc_obj.tdi_buf,
			total_bytes);
	if (ret) {
		pr_info("copy tdi_buf failed: %d/%u.\n", ret, total_bytes);
		goto cleanup;
	}

	/* exclusive access */
	spin_lock(&pcdev->lock);

	iobase = pddev->bar[pcdev->bar] + pcdev->base;
	/* set length register to 32 initially if more than one
	 * word-trans is to be done
	 */
	if (total_bits >= 32) {
		write_register(0x20, iobase, PVC_BAR_LENGTH_REG);
	}

	for (bits = 0, bits_left = total_bits; bits < total_bits; bits += 32,
		bits_left -= 32) {
		tms_store = 0;
		tdi_store = 0;
		tdo_store = 0;
		bytes = bits >> 3;
		shift_bytes = 4;	

		if (bits_left < 32) {
			/* set number of bits to shift out */
			write_register(bits_left, iobase, PVC_BAR_LENGTH_REG);
			shift_bytes = (bits_left + 7) >> 3;
		}

		memcpy(&tms_store, tms_buf + bytes, shift_bytes);
		memcpy(&tdi_store, tdi_buf + bytes, shift_bytes);

		/* Shift data out and copy to output buffer */
		ret = pvc_shift_bits(iobase, tms_store, tdi_store, &tdo_store);
		if (ret < 0)
			break;

		memcpy(tdo_buf + bytes, &tdo_store, shift_bytes);
	}

	if (ret < 0)
		goto unlock;

	/* if testing bar access swap tdi and tdo bufferes to "loopback" */
	if (opcode == 0x2) {
		unsigned char *tmp = tdo_buf;

		tdo_buf = tdi_buf;
		tdi_buf = tmp;
	}

	ret = copy_to_user(pvc_obj.tdo_buf, (const void *)tdo_buf, total_bytes);
	if (ret) {
		pr_info("copy back tdo_buf failed: %d/%u.\n", ret, total_bytes);
	}

unlock:
#if HAS_MMIOWB
	mmiowb();
#endif
	spin_unlock(&pcdev->lock);

cleanup:
	kfree(buffer);

	return ret;
}

/*
 * character device file operations for the PVC
 */
static const struct file_operations pvc_fops = {
	.owner = THIS_MODULE,
	.open = dev_open,
	.release = dev_close,
	.unlocked_ioctl = pvc_ioctl,
};

void dev_pvc_init(struct bdma_cdev *pcdev)
{
#ifdef __PVC_BAR_NUM__
	pcdev->bar = __PVC_BAR_NUM__;
#endif
#ifdef __PVC_BAR_OFFSET__
	pcdev->base = __PVC_BAR_OFFSET__;
#else
	pcdev->base = PVC_BAR_OFFSET_DFLT;
#endif
	pr_info("pcdev 0x%p, bar %u, offset 0x%lx.\n",
		pcdev, pcdev->bar, pcdev->base);
	cdev_init(&pcdev->cdev, &pvc_fops);
}
