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
#include "version.h"
#include "dev_ctrl.h"
#include "bdma_dev.h"

#if ACCESS_OK_2_ARGS
#define pg_access_ok(X, Y, Z) access_ok(Y, Z)
#else
#define pg_access_ok(X, Y, Z) access_ok(X, Y, Z)
#endif

/*
 * character device file operations for ctrl bus (through ctrl bridge)
 */
static ssize_t dev_ctrl_write(struct file *file, const char __user *buf,
			size_t count, loff_t *pos)
{
    u32 tmp;
	int ret;
	struct bdma_cdev *pcdev;
	struct bdma_dev *pddev;
	void __iomem *reg;

	pcdev = (struct bdma_cdev *)file->private_data;

	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0)
		return ret;
	pddev = pcdev->pddev;

	/* only 32-bit aligned and 32-bit multiples */
	if (*pos & 3)
		return -EPROTO;

	/* first address is BAR base plus file position offset */
	reg = pddev->bar[pcdev->bar] + *pos;
	ret = copy_from_user(&tmp, buf, 4);
	if (ret)
		pr_info("copy from user failed %d/4, but continuing.\n", ret);

	dbg_sg("%s(0x%08x @%p, count=%ld, pos=%d)\n",
			__func__, tmp, reg, (long)count, (int)*pos);
	//write_register(w, reg);
	iowrite32(tmp, reg);
	*pos += 4;
	return 4;
}

static ssize_t dev_ctrl_read(struct file *fp, char __user *buf, size_t count,
		loff_t *pos)
{
    u32 tmp;
	int ret;	
	void __iomem *reg;
	struct bdma_cdev *pcdev;
	struct bdma_dev *pddev;	

	pcdev = (struct bdma_cdev *)fp->private_data;

	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0) {
		return ret;
	}
	pddev = pcdev->pddev;

	/* only 32-bit aligned and 32-bit multiples */
	if (*pos & 3) {
		return -EPROTO;
	}
	/* first address is BAR base plus file position offset */
	reg = pddev->bar[pcdev->bar] + *pos;
	//w = read_register(reg);
	tmp = ioread32(reg);
	pr_err("%s(@%p, count=%ld, pos=%d) value = 0x%08x\n",
			__func__, reg, (long)count, (int)*pos, tmp);
	ret = copy_to_user(buf, &tmp, 4);
	if (ret) {
		dbg_sg("Copy to userspace failed but continuing\n");
	}

	*pos += 4;
	return 4;
}

static long version_ioctl(struct bdma_cdev *pcdev, void __user *arg)
{    
	int ret;
	struct bdma_ioc_info obj;
	struct bdma_dev *pddev;
    
	pddev = pcdev->pddev;
	ret = copy_from_user((void *)&obj, arg, sizeof(struct bdma_ioc_info));
	if (ret) {
		pr_info("copy from user failed %d/%ld.\n", ret, sizeof(struct bdma_ioc_info));
		return -EFAULT;
	}
	
	memset(&obj, 0, sizeof(obj));
	obj.bus = PCI_BUS_NUM(pddev->pdev->devfn);
	obj.dev = PCI_SLOT(pddev->pdev->devfn);
	obj.func = PCI_FUNC(pddev->pdev->devfn);
	obj.feat_id = pddev->feat_id;
	obj.driver_version = DRV_MOD_VERSION_NUMBER;
	obj.domain = 0;
	obj.vendor = pddev->pdev->vendor;
	obj.device = pddev->pdev->device;
	obj.subsys_vendor = pddev->pdev->subsystem_vendor;
	obj.subsys_device = pddev->pdev->subsystem_device;
	if (copy_to_user(arg, &obj, sizeof(struct bdma_ioc_info))) {
		return -EFAULT;
	}
	return 0;
}

long dev_ctrl_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    long result = 0;
	int ret;
	struct bdma_cdev *pcdev;
	struct bdma_dev *pddev;
	struct bdma_ioc_base ioctl_obj;

	pcdev = (struct bdma_cdev *)filp->private_data;

	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0) {
		return ret;
	}

	pddev = pcdev->pddev;
	if (!pddev) {
		pr_info("cmd %u, pddev NULL.\n", cmd);
		return -EINVAL;
	}
	
	pr_info("cmd 0x%x, pddev 0x%p, pddev 0x%p.\n", cmd, pddev, pddev->pdev);

	if (_IOC_TYPE(cmd) != BDMA_IOC_MAGIC) {
		pr_err("cmd %u, bad magic 0x%x/0x%x.\n", cmd, _IOC_TYPE(cmd), BDMA_IOC_MAGIC);
		return -ENOTTY;
	}

	if (_IOC_DIR(cmd) & _IOC_READ) {
		result = !pg_access_ok(VERIFY_WRITE, (void __user *)arg, _IOC_SIZE(cmd));
	} else if (_IOC_DIR(cmd) & _IOC_WRITE) {
		result =  !pg_access_ok(VERIFY_READ, (void __user *)arg, _IOC_SIZE(cmd));
	}

	if (result) {
		pr_err("bad access %ld.\n", result);
		return -EFAULT;
	}

	switch (cmd) {
	case BDMA_IOCINFO:
		if (copy_from_user((void *)&ioctl_obj, (void __user *) arg,
			 sizeof(struct bdma_ioc_base))) {
			pr_err("copy_from_user failed.\n");
			return -EFAULT;
		}

		if (ioctl_obj.magic != BDMA_XCL_MAGIC) {
			pr_err("magic 0x%x !=  BDMA_XCL_MAGIC (0x%x).\n", ioctl_obj.magic, BDMA_XCL_MAGIC);
			return -ENOTTY;
		}
		
		return version_ioctl(pcdev, (void __user *)arg);
	case BDMA_IOCOFFLINE:
		bdma_device_offline(pddev->pdev, pddev);
		break;
	case BDMA_IOCONLINE:
		bdma_device_online(pddev->pdev, pddev);
		break;
	default:
		pr_err("UNKNOWN ioctl cmd 0x%x.\n", cmd);
		return -ENOTTY;
	}
	return 0;
}

/* maps the PCIe BAR into user space for memory-like access using mmap() */
int bridge_mmap(struct file *file, struct vm_area_struct *vma)
{
    int ret;
	unsigned long off;
	unsigned long phys;
	unsigned long vsize;
	unsigned long psize;
	struct bdma_dev *pddev;
	struct bdma_cdev *pcdev;		

	pcdev = (struct bdma_cdev *)file->private_data;

	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0) {
		return ret;
	}
	
	pddev = pcdev->pddev;
	off = vma->vm_pgoff << PAGE_SHIFT;
	/* BAR physical address */
	phys = pci_resource_start(pddev->pdev, pcdev->bar) + off;
	vsize = vma->vm_end - vma->vm_start;
	
	/* complete resource */
	psize = pci_resource_end(pddev->pdev, pcdev->bar) -
		pci_resource_start(pddev->pdev, pcdev->bar) + 1 - off;
    
	dbg_sg("phys = 0x%lx\n", phys);
    dbg_sg("mmap(): pddev = 0x%p\n", pddev);
	dbg_sg("mmap(): pci_dev = 0x%08lx\n", (unsigned long)pddev->pdev);
	dbg_sg("mmap(): pcdev = 0x%08lx\n", (unsigned long)pcdev);
	dbg_sg("mmap(): cdev->bar = %d\n", pcdev->bar);
	dbg_sg("off = 0x%lx, vsize 0x%lu, psize 0x%lu.\n", off, vsize, psize);
	dbg_sg("start = 0x%llx\n", (unsigned long long)pci_resource_start(pddev->pdev, pcdev->bar));

	if (vsize > psize) {
		return -EINVAL;
	}
	
	/*
	 * pages must not be cached as this would result in cache line sized
	 * accesses to end point
	 */
	vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
	/*
	 * prevent touching the pages  for swap-in,
	 * and prevent the pages from being swapped out
	 */
	vma->vm_flags |= VMEM_FLAGS;
	/* make MMIO accessible to user space */
	ret = io_remap_pfn_range(vma, vma->vm_start, phys >> PAGE_SHIFT,
			vsize, vma->vm_page_prot);
	dbg_sg("vma=0x%p, vma->vm_start=0x%lx, phys=0x%lx, size=%lu = %d\n",
		vma, vma->vm_start, phys >> PAGE_SHIFT, vsize, ret);

	if (ret) {
		return -EAGAIN;
	}
	return 0;
}

/*
 * character device file operations for ctrl bus (through ctrl bridge)
 */
static const struct file_operations ctrl_fops = {
	.owner = THIS_MODULE,
	.open = dev_open,
	.release = dev_close,
	.read = dev_ctrl_read,
	.write = dev_ctrl_write,
	.mmap = bridge_mmap,
	.unlocked_ioctl = dev_ctrl_ioctl,
};

void dev_ctrl_init(struct bdma_cdev *pcdev)
{
	cdev_init(&pcdev->cdev, &ctrl_fops);
}
