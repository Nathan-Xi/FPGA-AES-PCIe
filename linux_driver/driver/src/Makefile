SHELL = /bin/bash
#
# optional makefile parameters:
# - DEBUG=<0|1>,	enable verbose debug print-out in the driver
# - config_bar_num=,	bdma pci config bar number
# - pvc_bar_num=,	pvc pci bar #
# - pvc_bar_offset=,	pvc register base offset
# 
ifneq ($(pvc_bar_num),)
	PVC_FLAGS += -D__PVC_BAR_NUM__=$(pvc_bar_num)
endif

ifneq ($(pvc_bar_offset),)
	PVC_FLAGS += -D__PVC_BAR_OFFSET__=$(pvc_bar_offset)
endif

$(warning PVC_FLAGS: $(PVC_FLAGS).)

topdir := $(shell cd $(src)/.. && pwd)

TARGET_MODULE:=bdma

EXTRA_CFLAGS := -I$(topdir)/include $(PVC_FLAGS)
ifeq ($(DEBUG),1)
	EXTRA_CFLAGS += -D__LIBBDMA_DEBUG__
endif
ifneq ($(config_bar_num),)
	EXTRA_CFLAGS += -DBDMA_CONFIG_BAR_NUM=$(config_bar_num)
endif
#EXTRA_CFLAGS += -DINTERNAL_TESTING

ifneq ($(KERNELRELEASE),)
	$(TARGET_MODULE)-objs := libbdma.o bdma_dev.o dev_ctrl.o dev_events.o dev_sgdma.o dev_pvc.o dev_bypass.o bdma_mod.o bdma_thread.o
	obj-m := $(TARGET_MODULE).o
else
	BUILDSYSTEM_DIR:=/home/tronlong/work/rk3588/rk3588_buildroot/kernel
	PWD:=$(shell pwd)
all :
	$(MAKE) -C $(BUILDSYSTEM_DIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(BUILDSYSTEM_DIR) M=$(PWD) clean
	@/bin/rm -f *.ko modules.order *.mod.c *.o *.o.ur-safe .*.o.cmd

install: all
	@rm -f /lib/modules/5.15.0-67-generic/extra/bdma.ko
	@echo "installing kernel modules to /lib/modules/$(shell uname -r)/bdma ..."
	@mkdir -p -m 755 /lib/modules/$(shell uname -r)/bdma
	@install -v -m 644 *.ko /lib/modules/$(shell uname -r)/bdma
	@depmod -a || true

uninstall:
	@echo "Un-installing /lib/modules/$(shell uname -r)/bdma ..."
	@/bin/rm -rf /lib/modules/$(shell uname -r)/bdma
	@depmod -a




endif
