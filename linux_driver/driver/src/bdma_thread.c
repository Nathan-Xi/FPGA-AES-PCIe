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

#include "bdma_thread.h"

#include <linux/kernel.h>
#include <linux/slab.h>


/* ********************* global variables *********************************** */
static struct bdma_kthread *pk_threads;
static unsigned int thread_cnt;


/* ********************* static function definitions ************************ */
static int bdma_thread_cmpl_status_pend(struct list_head *work_item)
{
    int pend = 0;
	unsigned long flags;
	struct bdma_engine *engine;

	engine = list_entry(work_item, struct bdma_engine, compthp_list);

	spin_lock_irqsave(&engine->lock, flags);
	pend = !list_empty(&engine->trans_list);
	spin_unlock_irqrestore(&engine->lock, flags);

	return pend;
}

static int bdma_thread_cmpl_status_proc(struct list_head *work_item)
{
	struct bdma_engine *engine;
	struct bdma_transfer * trans;

	engine = list_entry(work_item, struct bdma_engine, compthp_list);
	trans = list_entry(engine->trans_list.next, struct bdma_transfer, entry);
	if (trans) {
		eng_service_poll(engine, trans->desc_comp_th);
	}
	return 0;
}


static inline void pgthread_reschedule(struct bdma_kthread *thp)
{
	if (thp->timeout) {
		pr_debug_thread("%s rescheduling for %u seconds", thp->name, thp->timeout);
		wait_event_interruptible_timeout(thp->waitq, thp->schedule, msecs_to_jiffies(thp->timeout));
	} else {
		pr_debug_thread("%s rescheduling", thp->name);
		wait_event_interruptible(thp->waitq, thp->schedule);
	}
}


static inline int pgthread_work_pending(struct bdma_kthread *thp)
{
	struct list_head *work_item, *next;

	/* any work items assigned to this thread? */
	if (list_empty(&thp->work_list)) {
		return 0;
	}

	/* any work item has pending work to do? */
	list_for_each_safe(work_item, next, &thp->work_list) {
		if (thp->fpending && thp->fpending(work_item)) {
			return 1;
		}
	}
	return 0;
}

static int pgthread_main(void *data)
{
	struct bdma_kthread *thp;
	struct list_head *work_item, *next;

	thp = (struct bdma_kthread *)data;

	pr_debug_thread("%s UP.\n", thp->name);

	disallow_signal(SIGPIPE);

	if (thp->finit) {
		thp->finit(thp);
	}

	while (!kthread_should_stop()) {		

		pr_debug_thread("%s interruptible\n", thp->name);

		/* any work to do? */
		lock_thread(thp);
		if (!pgthread_work_pending(thp)) {
			unlock_thread(thp);
			pgthread_reschedule(thp);
			lock_thread(thp);
		}
		
		thp->schedule = 0;

		if (thp->work_cnt) {
			pr_debug_thread("%s processing %u work items\n", thp->name, thp->work_cnt);
			/* do work */
			list_for_each_safe(work_item, next, &thp->work_list) {
				thp->fproc(work_item);
			}
		}
		unlock_thread(thp);
		schedule();
	}

	pr_debug_thread("%s, work done.\n", thp->name);

	if (thp->fdone) {
		thp->fdone(thp);
	}

	pr_debug_thread("%s, exit.\n", thp->name);
	return 0;
}


int bdma_kthread_start(struct bdma_kthread *thp, char *name, int id)
{
	int len;
	int node;

	if (thp->task) {
		pr_warn("kthread %s task already running?\n", thp->name);
		return -EINVAL;
	}

	len = snprintf(thp->name, sizeof(thp->name), "%s%d", name, id);
	if (len < 0) {
		pr_err("thread %d, error in snprintf name %s.\n", id, name);
		return -EINVAL;
	}

	thp->id = id;

	spin_lock_init(&thp->lock);
	INIT_LIST_HEAD(&thp->work_list);
	init_waitqueue_head(&thp->waitq);

	node = cpu_to_node(thp->cpu);
	pr_debug("node : %d\n", node);

	thp->task = kthread_create_on_node(pgthread_main, (void *)thp, node, "%s", thp->name);
	if (IS_ERR(thp->task)) {
		pr_err("kthread %s, create task failed: 0x%lx\n", thp->name, (unsigned long)IS_ERR(thp->task));
		thp->task = NULL;
		return -EFAULT;
	}

	kthread_bind(thp->task, thp->cpu);

	pr_debug_thread("kthread 0x%p, %s, cpu %u, task 0x%p.\n", thp, thp->name, thp->cpu, thp->task);

	wake_up_process(thp->task);
	return 0;
}

int bdma_kthread_stop(struct bdma_kthread *thp)
{
	int ret;

	if (!thp->task) {
		pr_debug_thread("kthread %s, already stopped.\n", thp->name);
		return 0;
	}

	thp->schedule = 1;
	ret = kthread_stop(thp->task);
	if (ret < 0) {
		pr_warn("kthread %s, stop err %d.\n", thp->name, ret);
		return ret;
	}

	pr_debug_thread("kthread %s, 0x%p, stopped.\n", thp->name, thp->task);
	thp->task = NULL;

	return 0;
}


void bdma_thread_add_work(struct bdma_engine *engine)
{
    unsigned int val = 0;
	int i, idx;
	unsigned long flags;
	struct bdma_kthread *thp;

	idx = thread_cnt;
	thp = pk_threads;

	/* Polled mode only */
	for (i = 0; i < thread_cnt; i++, thp++) {
		lock_thread(thp);
		if (idx == thread_cnt) {
			val = thp->work_cnt;
			idx = i;
		} else if (!thp->work_cnt) {
			idx = i;
			unlock_thread(thp);
			break;
		} else if (thp->work_cnt < val) {
			idx = i;
		}
		unlock_thread(thp);
	}

	thp = pk_threads + idx;
	lock_thread(thp);
	list_add_tail(&engine->compthp_list, &thp->work_list);
	engine->intr_work_cpu = idx;
	thp->work_cnt++;
	unlock_thread(thp);

	pr_info("%s 0x%p assigned to cmpl status thread %s,%u.\n", engine->name, engine, thp->name, thp->work_cnt);


	spin_lock_irqsave(&engine->lock, flags);
	engine->compthp = thp;
	spin_unlock_irqrestore(&engine->lock, flags);
}


void bdma_thread_remove_work(struct bdma_engine *engine)
{
	struct bdma_kthread *cmpl_thread;
	unsigned long flags;

	spin_lock_irqsave(&engine->lock, flags);
	cmpl_thread = engine->compthp;
	engine->compthp = NULL;

//	pr_debug("%s removing from thread %s, %u.\n",
//		descq->conf.name, cmpl_thread ? cmpl_thread->name : "?",
//		cpu_idx);

	spin_unlock_irqrestore(&engine->lock, flags);

	if (cmpl_thread) {
		lock_thread(cmpl_thread);
		list_del(&engine->compthp_list);
		cmpl_thread->work_cnt--;
		unlock_thread(cmpl_thread);
	}
}

int bdma_threads_create(unsigned int num_threads)
{
    int ret;
	int cpu;
	struct bdma_kthread *thp;

	if (thread_cnt) {
		pr_warn("threads already created!");
		return 0;
	}

	pk_threads = kzalloc(num_threads * sizeof(struct bdma_kthread),	GFP_KERNEL);
	if (!pk_threads) {
		pr_err("OOM, # threads %u.\n", num_threads);
		return -ENOMEM;
	}

	/* N dma writeback monitoring threads */
	thp = pk_threads;
	for_each_online_cpu(cpu) {
		pr_debug("index %d cpu %d online\n", thread_cnt, cpu);
		thp->cpu = cpu;
		thp->timeout = 0;
		thp->fproc = bdma_thread_cmpl_status_proc;
		thp->fpending = bdma_thread_cmpl_status_pend;
		ret = bdma_kthread_start(thp, "cmpl_status_th", thread_cnt);
		if (ret < 0) {
			goto cleanup_threads;
		}

		thread_cnt++;
		if (thread_cnt == num_threads) {
			break;
		}
		thp++;
	}

	return 0;

cleanup_threads:
	kfree(pk_threads);
	pk_threads = NULL;
	thread_cnt = 0;

	return ret;
}

void bdma_threads_destroy(void)
{
	int i;
	struct bdma_kthread *thp;

	if (!thread_cnt) {
		return;
	}

	/* N dma writeback monitoring threads */
	thp = pk_threads;
	for (i = 0; i < thread_cnt; i++, thp++) {
		if (thp->fproc) {
			bdma_kthread_stop(thp);
		}
	}

	kfree(pk_threads);
	pk_threads = NULL;
	thread_cnt = 0;
}
