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


#define IOCTL_BDMA_PERF_V1 (1)
#define BDMA_ADDRMODE_MEMORY (0)
#define BDMA_ADDRMODE_FIXED (1)

struct bdma_performance_ioctl {
	/* IOCTL_BDMA_IOCTL_Vx */
	uint32_t version;
	uint32_t stopped;
	uint32_t iterations;
	uint32_t transfer_size;
	uint64_t clock_cycle_count;
	uint64_t data_cycle_count;
	uint64_t pending_count;
};

struct bdma_aperture_ioctl {		
	int           error;
	unsigned int aperture;
	unsigned long buffer;
	unsigned long len;
	unsigned long done;
	uint64_t ep_addr;
};


/* IOCTL codes */

#define IOCTL_BDMA_PERF_START   _IOW('q', 1, struct bdma_performance_ioctl *)
#define IOCTL_BDMA_PERF_STOP    _IOW('q', 2, struct bdma_performance_ioctl *)
#define IOCTL_BDMA_PERF_GET     _IOR('q', 3, struct bdma_performance_ioctl *)
#define IOCTL_BDMA_ADDRMODE_SET _IOW('q', 4, int)
#define IOCTL_BDMA_ADDRMODE_GET _IOR('q', 5, int)
#define IOCTL_BDMA_ALIGN_GET    _IOR('q', 6, int)
#define IOCTL_BDMA_APERTURE_R   _IOW('q', 7, struct bdma_aperture_ioctl *)
#define IOCTL_BDMA_APERTURE_W   _IOW('q', 8, struct bdma_aperture_ioctl *)

#endif /* _BDMA_IOCALLS_POSIX_H_ */
