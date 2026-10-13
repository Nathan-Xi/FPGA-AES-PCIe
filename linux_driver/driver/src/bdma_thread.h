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


#ifndef __BDMA_KTHREAD_H__
#define __BDMA_KTHREAD_H__
/**
 * @file
 * @brief This file contains the declarations for bdma kernel threads
 *
 */
#include <linux/version.h>
#include <linux/spinlock.h>
#include <linux/kthread.h>
#include <linux/cpuset.h>
#include <linux/signal.h>

#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/uaccess.h>
#include <linux/errno.h>
#include "libbdma.h"

#ifdef DEBUG_THREADS
#define lock_thread(thp)	\
	do { \
		pr_debug("locking thp %s ...\n", (thp)->name); \
		spin_lock(&(thp)->lock); \
	} while (0)

#define unlock_thread(thp)	\
	do { \
		pr_debug("unlock thp %s ...\n", (thp)->name); \
		spin_unlock(&(thp)->lock); \
	} while (0)

#define bdma_kthread_wakeup(thp)	\
	do { \
		pr_info("signaling thp %s ...\n", (thp)->name); \
		wake_up_process((thp)->task); \
	} while (0)

#define pr_debug_thread(fmt, ...) pr_info(fmt, __VA_ARGS__)

#else
/** lock thread macro */
#define lock_thread(thp)		spin_lock(&(thp)->lock)
/** un lock thread macro */
#define unlock_thread(thp)		spin_unlock(&(thp)->lock)
#define bdma_kthread_wakeup(thp) \
	do { \
		thp->schedule = 1; \
		wake_up_interruptible(&thp->waitq); \
	} while (0)
/** pr_debug_thread */
#define pr_debug_thread(fmt, ...)
#endif

/**
 * @struct - bdma_kthread
 * @brief	bdma thread book keeping parameters
 */
struct bdma_kthread {
	/**  thread lock*/
	spinlock_t lock;
	/**  thread wait queue */
	wait_queue_head_t waitq;
	
	/**  name of the thread */
	char name[16];
	/**  cpu number for which the thread associated with */
	unsigned short cpu;
	/**  thread id */
	unsigned short id;
	/**  thread sleep timeout value */
	unsigned int timeout;
	/* flag to indicate scheduling of thread */
	unsigned int schedule;	
	/**  thread work list count */
	unsigned int work_cnt;
	/**  flags for thread */
	unsigned long flag;
	
	/**  kernel task structure associated with thread*/
	struct task_struct *task;
	/**  thread work list count */
	struct list_head work_list;
	
	/**  thread initialization handler */
	int (*finit)(struct bdma_kthread *);
	/**  thread pending handler */
	int (*fpending)(struct list_head *);
	/**  thread peocessing handler */
	int (*fproc)(struct list_head *);
	/**  thread done handler */
	int (*fdone)(struct bdma_kthread *);
};


/*****************************************************************************/
/**
 * bdma_threads_create() - create bdma threads
*********/
int bdma_threads_create(unsigned int num_threads);

/*****************************************************************************/
/**
 * bdma_threads_destroy() - destroy all the bdma threads created
 *                          during system initialization
 *
 * @return	none
 *****************************************************************************/
void bdma_threads_destroy(void);

/*****************************************************************************/
/**
 * bdma_thread_remove_work() - handler to remove the attached work thread
 *
 * @param[in]	engine:	pointer to bdma_engine
 *
 * @return	none
 *****************************************************************************/
void bdma_thread_remove_work(struct bdma_engine *engine);

/*****************************************************************************/
/**
 * bdma_thread_add_work() - handler to add a work thread
 *
 * @param[in]	engine:	pointer to bdma_engine
 *
 * @return	none
 *****************************************************************************/
void bdma_thread_add_work(struct bdma_engine *engine);

#endif /* #ifndef __BDMA_KTHREAD_H__ */
