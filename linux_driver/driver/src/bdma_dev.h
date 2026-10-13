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


#ifndef __BDMA_CHRDEV_H__
#define __BDMA_CHRDEV_H__

#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/uaccess.h>
#include <linux/errno.h>
#include "bdma_mod.h"

#define BDMA_NODE_NAME	"bdma"
#define BDMA_MINOR_BASE (0)
#define BDMA_MINOR_COUNT (255)

int bdma_cdev_init(void);
void bdma_cdev_cleanup(void);

void dev_ctrl_init(struct bdma_cdev *pcdev);
void dev_sgdma_init(struct bdma_cdev *pcdev);
void dev_event_init(struct bdma_cdev *pcdev);
void dev_bypass_init(struct bdma_cdev *pcdev);
void dev_pvc_init(struct bdma_cdev *pcdev);

int dev_open(struct inode *inode, struct file *file);
int dev_close(struct inode *inode, struct file *file);
long dev_ctrl_ioctl(struct file *filp, unsigned int cmd, unsigned long arg);
int pcdev_check(const char *fname, struct bdma_cdev *pcdev, bool check_engine);
void ppdev_destroy_interfaces(struct bdma_pci_dev *ppdev);
int ppdev_create_interfaces(struct bdma_pci_dev *ppdev);
int bridge_mmap(struct file *file, struct vm_area_struct *vma);

#endif /* __BDMA_CHRDEV_H__ */
