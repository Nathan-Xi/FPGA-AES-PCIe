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


#ifndef __PVC_IOCTL_H__
#define __PVC_IOCTL_H__

#include <linux/ioctl.h>

/*
 * the bar offset can be changed at compile time
 */
#define PVC_BAR_OFFSET_DFLT	0x40000	/* DSA 4.0 */

/* Use 'v' as magic number */
#define PVC_MAGIC 'v'

struct pvc_ioc {
	const char __user *tms_buf;
	const char __user *tdi_buf;
	unsigned int opcode;
	unsigned int length;	
	void __user *tdo_buf;
};

#define BDMA_IOCPVC	_IOWR(PVC_MAGIC, 1, struct pvc_ioc)

#endif /* __PVC_IOCTL_H__ */
