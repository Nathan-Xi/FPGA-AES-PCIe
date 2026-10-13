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

/*
 * character device file operations for events
 */


static unsigned int dev_events_poll(struct file *file, poll_table *wait)
{
    int ret;
	unsigned long flags;
	unsigned int mask = 0;	
	struct bdma_usr_irq *usr_irq;
	struct bdma_cdev *pcdev;

	pcdev = (struct bdma_cdev *)file->private_data;
	
	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0) {
		return ret;
	}
	usr_irq = pcdev->usr_irq;
	if (!usr_irq) {
		pr_info("pcdev 0x%p, usr_irq NULL.\n", pcdev);
		return -EINVAL;
	}

	poll_wait(file, &usr_irq->events_wq,  wait);

	spin_lock_irqsave(&usr_irq->events_lock, flags);
	if (usr_irq->events_irq) {
		mask = POLLIN | POLLRDNORM;	/* readable */
	}

	spin_unlock_irqrestore(&usr_irq->events_lock, flags);
	
	return mask;
}

static ssize_t dev_events_read(struct file *file, char __user *buf,
		size_t count, loff_t *pos)
{
	int ret;
	u32 events_user;
	unsigned long flags;
	struct bdma_usr_irq *usr_irq;
	struct bdma_cdev *pcdev;

    pcdev = (struct bdma_cdev *)file->private_data;
	
	ret = pcdev_check(__func__, pcdev, 0);
	if (ret < 0) {
		return ret;
	}
	usr_irq = pcdev->usr_irq;
	if (!usr_irq) {
		pr_info("pcdev 0x%p, usr_irq NULL.\n", pcdev);
		return -EINVAL;
	}
	
	if (*pos & 3) {
			return -EPROTO;
	}

	if (count != 4) {
		return -EPROTO;
	}

	
	/*
	 * sleep until any inter events have occurred,or a signal arrived
	 */
	ret = wait_event_interruptible(usr_irq->events_wq, usr_irq->events_irq != 0);
	if (ret) {
		dbg_sg("wait_event_interruptible=%d\n", ret);
	}

	/* wait_event_interible() was intered by a signal */
	if (ret == -ERESTARTSYS) {
		return -ERESTARTSYS;
	}

	/* atomically decide which events are passed to the user */
	spin_lock_irqsave(&usr_irq->events_lock, flags);
	events_user = usr_irq->events_irq;
	usr_irq->events_irq = 0;
	spin_unlock_irqrestore(&usr_irq->events_lock, flags);

	ret = copy_to_user(buf, &events_user, 4);
	if (ret) {
		dbg_sg("Copy to user failed but continuing\n");
	}

	return 4;
}

/*
 * character device file operations for the irq events
 */
static const struct file_operations events_fops = {
	.owner = THIS_MODULE,
	.open = dev_open,
	.release = dev_close,
	.read = dev_events_read,
	.poll = dev_events_poll,
};

void dev_event_init(struct bdma_cdev *pcdev)
{
	pcdev->usr_irq = &(pcdev->pddev->usr_irq[pcdev->bar]);
	cdev_init(&pcdev->cdev, &events_fops);
}
