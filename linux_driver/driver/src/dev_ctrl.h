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

#ifndef _BDMA_IOCALLS_POSIX_H_
#define _BDMA_IOCALLS_POSIX_H_

#include <linux/ioctl.h>

/* Use 'p' as magic number */
#define BDMA_IOC_MAGIC	'p'
/* XL OpenCL X->58(ASCII), L->6C(ASCII), O->0 C->C L->6C(ASCII); */
#define BDMA_XCL_MAGIC 0X586C0C6C

enum BDMA_IOC_TYPES {
	BDMA_IOC_NOP,
	BDMA_IOC_ONLINE,
	BDMA_IOC_OFFLINE,
	BDMA_IOC_INFO,	
	BDMA_IOC_MAX
};

struct bdma_ioc_base {
	unsigned int magic;
	unsigned int command;
};

struct bdma_ioc_info {
	unsigned char		bus;
	unsigned char		dev;
	unsigned char		func;
	unsigned char		res0;
	unsigned short		domain;
	unsigned short		vendor;
	unsigned short		device;
	unsigned short		subsys_vendor;
	unsigned short		subsys_device;
	unsigned int		dma_version;
	unsigned int		driver_version;
	unsigned long long	feat_id;	
	struct bdma_ioc_base	base;
};

/* IOCTL codes */
#define BDMA_IOCONLINE		_IO(BDMA_IOC_MAGIC, BDMA_IOC_ONLINE)
#define BDMA_IOCOFFLINE		_IO(BDMA_IOC_MAGIC, BDMA_IOC_OFFLINE)
#define BDMA_IOCINFO		_IOWR(BDMA_IOC_MAGIC, BDMA_IOC_INFO, struct bdma_ioc_info)

#define IOCTL_BDMA_PERF_START   _IOW('q', 1, struct bdma_performance_ioctl *)
#define IOCTL_BDMA_PERF_STOP    _IOW('q', 2, struct bdma_performance_ioctl *)
#define IOCTL_BDMA_PERF_GET     _IOR('q', 3, struct bdma_performance_ioctl *)
#define IOCTL_BDMA_ADDRMODE_SET _IOW('q', 4, int)
#define IOCTL_BDMA_ADDRMODE_GET _IOR('q', 5, int)
#define IOCTL_BDMA_ALIGN_GET    _IOR('q', 6, int)
#define IOCTL_BDMA_APERTURE_R   _IOW('q', 7, struct bdma_aperture_ioctl *)
#define IOCTL_BDMA_APERTURE_W   _IOW('q', 8, struct bdma_aperture_ioctl *)


#endif /* _BDMA_IOCALLS_POSIX_H_ */
