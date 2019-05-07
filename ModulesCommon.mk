#
# Copyright (C) 2018 GlobalLogic
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

PRODUCT_OUT                 := $(OUT_DIR)/target/product/$(TARGET_PRODUCT)
PRODUCT_OUT_ABS             := $(abspath $(PRODUCT_OUT))

TARGET_KERNEL_MODULES_OUT   := $(PRODUCT_OUT_ABS)/obj/KERNEL_MODULES
TARGET_KERNEL_SOURCE        := device/renesas/kernel
KERNEL_COMPILE_FLAGS        := HOSTCC=$(ANDROID_CLANG_TOOLCHAIN) CC=$(ANDROID_CLANG_TOOLCHAIN)

BOARD_VENDOR_KERNEL_MODULES += \
	$(TARGET_KERNEL_MODULES_OUT)/pvrsrvkm.ko \
	$(TARGET_KERNEL_MODULES_OUT)/vspm.ko \
	$(TARGET_KERNEL_MODULES_OUT)/vspm_if.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mmngr.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mmngrbuf.ko \
	$(TARGET_KERNEL_MODULES_OUT)/uvcs_drv.ko \
	$(TARGET_KERNEL_MODULES_OUT)/qos.ko

ifeq ($(ENABLE_ADSP),true)
	BOARD_VENDOR_KERNEL_MODULES += \
		$(TARGET_KERNEL_MODULES_OUT)/xtensa-hifi.ko
endif

BOARD_VENDOR_KERNEL_MODULES += \
	$(TARGET_KERNEL_MODULES_OUT)/extcon-usb-gpio.ko \
	$(TARGET_KERNEL_MODULES_OUT)/phy-rcar-gen3-usb2.ko \
	$(TARGET_KERNEL_MODULES_OUT)/usbcore.ko \
	$(TARGET_KERNEL_MODULES_OUT)/renesas_usbhs.ko \
	$(TARGET_KERNEL_MODULES_OUT)/ehci-hcd.ko \
	$(TARGET_KERNEL_MODULES_OUT)/ehci-platform.ko \
	$(TARGET_KERNEL_MODULES_OUT)/ohci-hcd.ko \
	$(TARGET_KERNEL_MODULES_OUT)/ohci-platform.ko \
	$(TARGET_KERNEL_MODULES_OUT)/xhci-hcd.ko \
	$(TARGET_KERNEL_MODULES_OUT)/xhci-plat-hcd.ko \
	$(TARGET_KERNEL_MODULES_OUT)/usbhid.ko \
	$(TARGET_KERNEL_MODULES_OUT)/usb-storage.ko

BOARD_VENDOR_KERNEL_MODULES += \
	$(TARGET_KERNEL_MODULES_OUT)/micrel.ko

BOARD_VENDOR_KERNEL_MODULES += \
	$(TARGET_KERNEL_MODULES_OUT)/ravb_proc.ko  \
	$(TARGET_KERNEL_MODULES_OUT)/ravb_streaming.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mch_core.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mse_core.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mse_adapter_alsa.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mse_adapter_v4l2.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mse_adapter_eavb.ko \
	$(TARGET_KERNEL_MODULES_OUT)/mse_adapter_mch.ko

#$(BOARD_VENDOR_KERNEL_MODULES) : $(PRODUCT_OUT)/kernel

VSPM_MODULE_PATH      := hardware/renesas/modules/vspm/vspm-module
VSPMIF_MODULE_PATH    := hardware/renesas/modules/vspmif/vspm_if-module
MMNGR_MODULE_PATH     := hardware/renesas/modules/mmngr/mmngr_drv/mmngr/mmngr-module/files/mmngr
MMNGRBUF_MODULE_PATH  := hardware/renesas/modules/mmngr/mmngr_drv/mmngrbuf/mmngrbuf-module/files/mmngrbuf
UVCS_MODULE_PATH      := hardware/renesas/modules/uvcs
QOS_MODULE_PATH       := hardware/renesas/modules/qos/qos-module/files/qos/drv
ETHAVB_STREAMING_PATH := hardware/renesas/modules/avb-streaming
ETHAVB_MCH_PATH       := hardware/renesas/modules/avb-mch
ETHAVB_MSE_PATH       := hardware/renesas/modules/avb-mse
ETHAVB_INCLUDES       := $(abspath $(ETHAVB_STREAMING_PATH)) $(abspath $(ETHAVB_MCH_PATH))
ADSP_MODULE_PATH      := hardware/renesas/modules/adsp-s492c

ROGUE_MODULE_OUT      := $(PRODUCT_OUT_ABS)/obj/ROGUE_KM_OBJ
VSPM_MODULE_OUT       := $(PRODUCT_OUT_ABS)/obj/VSPM_KM_OBJ
VSPMIF_MODULE_OUT     := $(PRODUCT_OUT_ABS)/obj/VSPMIF_KM_OBJ
MMNGR_MODULE_OUT      := $(PRODUCT_OUT_ABS)/obj/MMNGR_KM_OBJ
MMNGRBUF_MODULE_OUT   := $(PRODUCT_OUT_ABS)/obj/MMNGRBUF_KM_OBJ
UVCS_MODULE_OUT       := $(PRODUCT_OUT_ABS)/obj/UVCS_KM_OBJ
QOS_MODULE_OUT        := $(PRODUCT_OUT_ABS)/obj/QOS_KM_OBJ
ETHAVB_STREAMING_OUT  := $(PRODUCT_OUT_ABS)/obj/ETHAVB_STREAMING_KM_OBJ
ETHAVB_MCH_OUT        := $(PRODUCT_OUT_ABS)/obj/ETHAVB_MCH_KM_OBJ
ETHAVB_MSE_OUT        := $(PRODUCT_OUT_ABS)/obj/ETHAVB_MSE_KM_OBJ
ADSP_MODULE_OUT       := $(PRODUCT_OUT_ABS)/obj/ADSP_KM_OBJ

# rgx module
.PHONY: kernel-module-pvrsrvkm
kernel-module-pvrsrvkm:
	make -C hardware/renesas/modules/gfx/build/linux/$(TARGET_BOARD_PLATFORM)_android KERNELDIR=$(KERNEL_OUT) ANDROID_ROOT=$(abspath .) $(KERNEL_COMPILE_FLAGS) ARCH="arm64" OUT=$(ROGUE_MODULE_OUT) TARGET_DEVICE=$(TARGET_DEVICE)
	mv $(ROGUE_MODULE_OUT)/target_aarch64/kbuild/pvrsrvkm.ko $(TARGET_KERNEL_MODULES_OUT)/

# vspm module
.PHONY: kernel-module-vspm
kernel-module-vspm:
	mkdir -p $(VSPM_MODULE_OUT)
	cp -R $(VSPM_MODULE_PATH) $(VSPM_MODULE_OUT)
	make -C $(VSPM_MODULE_OUT)/vspm-module/files/vspm/drv/ $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) PWD=$(VSPM_MODULE_OUT)/vspm-module/files/vspm/drv/
	mv $(VSPM_MODULE_OUT)/vspm-module/files/vspm/drv/vspm.ko $(TARGET_KERNEL_MODULES_OUT)/

# vspm-if module
.PHONY: kernel-module-vspmif
kernel-module-vspmif:
	mkdir -p $(VSPMIF_MODULE_OUT)
	cp -R $(VSPMIF_MODULE_PATH) $(VSPMIF_MODULE_OUT)
	make -C $(VSPMIF_MODULE_OUT)/vspm_if-module/files/vspm_if/drv/ $(KERNEL_COMPILE_FLAGS) ARCH="arm64" CP=cp KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) PWD=$(VSPMIF_MODULE_OUT)/vspm_if-module/files/vspm_if/drv/
	mv $(VSPMIF_MODULE_OUT)/vspm_if-module/files/vspm_if/drv/vspm_if.ko $(TARGET_KERNEL_MODULES_OUT)/

# mmngr module
.PHONY: kernel-module-mmngr
kernel-module-mmngr:
	mkdir -p $(MMNGR_MODULE_OUT)
	cp -R $(MMNGR_MODULE_PATH) $(MMNGR_MODULE_OUT)
	make -C $(MMNGR_MODULE_OUT)/mmngr/drv $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) PWD=$(MMNGR_MODULE_OUT)/mmngr/drv MMNGR_CONFIG=MMNGR_SALVATORX MMNGR_SSP_CONFIG="MMNGR_SSP_DISABLE" MMNGR_IPMMU_MMU_CONFIG="IPMMU_MMU_DISABLE"
	mv $(MMNGR_MODULE_OUT)/mmngr/drv/mmngr.ko $(TARGET_KERNEL_MODULES_OUT)/

# mmngrbuf module
.PHONY: kernel-module-mmngrbuf
kernel-module-mmngrbuf:
	mkdir -p $(MMNGRBUF_MODULE_OUT)
	cp -R $(MMNGRBUF_MODULE_PATH) $(MMNGRBUF_MODULE_OUT)
	make -C $(MMNGRBUF_MODULE_OUT)/mmngrbuf/drv $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) PWD=$(MMNGRBUF_MODULE_OUT)/mmngrbuf/drv MMNGR_CONFIG=MMNGR_SALVATORX MMNGR_SSP_CONFIG="MMNGR_SSP_DISABLE" MMNGR_IPMMU_MMU_CONFIG="IPMMU_MMU_DISABLE"
	mv $(MMNGRBUF_MODULE_OUT)/mmngrbuf/drv/mmngrbuf.ko $(TARGET_KERNEL_MODULES_OUT)/

# UVCS module
.PHONY: kernel-module-uvcs
kernel-module-uvcs:
	mkdir -p $(UVCS_MODULE_OUT)
	cp -R $(UVCS_MODULE_PATH)/include $(UVCS_MODULE_OUT)/
	cp -R $(UVCS_MODULE_PATH)/src $(UVCS_MODULE_OUT)/
	TOP=. make -C $(UVCS_MODULE_OUT)/src/makefile $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELDIR=$(KERNEL_OUT)
	mv $(UVCS_MODULE_OUT)/src/makefile/uvcs_drv.ko $(TARGET_KERNEL_MODULES_OUT)/

# QoS module
.PHONY: kernel-module-qos
kernel-module-qos:
	mkdir -p $(QOS_MODULE_OUT)
	cp -R $(QOS_MODULE_PATH)/* $(QOS_MODULE_OUT)/
	make -C $(QOS_MODULE_OUT) $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT)
	mv $(QOS_MODULE_OUT)/qos.ko $(TARGET_KERNEL_MODULES_OUT)/

# Ethernet avb-streaming module
.PHONY: kernel-module-ethavb-streaming
kernel-module-ethavb-streaming:
	mkdir -p $(ETHAVB_STREAMING_OUT)
	cp -R $(ETHAVB_STREAMING_PATH)/* $(ETHAVB_STREAMING_OUT)/
	make -C $(KERNEL_OUT) $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) M=$(ETHAVB_STREAMING_OUT)
	mv $(ETHAVB_STREAMING_OUT)/*.ko $(TARGET_KERNEL_MODULES_OUT)/

# avb-mch module
.PHONY: kernel-module-ethavb-mch
kernel-module-ethavb-mch:
	mkdir -p $(ETHAVB_MCH_OUT)
	cp -R $(ETHAVB_MCH_PATH)/* $(ETHAVB_MCH_OUT)/
	make -C $(KERNEL_OUT) $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) M=$(ETHAVB_MCH_OUT)
	mv $(ETHAVB_MCH_OUT)/*.ko $(TARGET_KERNEL_MODULES_OUT)/

# avb-mse module
.PHONY: kernel-module-ethavb-mse
kernel-module-ethavb-mse:
	mkdir -p $(ETHAVB_MSE_OUT)
	cp -R $(ETHAVB_MSE_PATH)/* $(ETHAVB_MSE_OUT)/
	make -C $(KERNEL_OUT) $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) INCSHARED="$(ETHAVB_INCLUDES)" M=$(ETHAVB_MSE_OUT)
	mv $(ETHAVB_MSE_OUT)/*.ko $(TARGET_KERNEL_MODULES_OUT)/

# adsp driver
.PHONY: kernel-module-xtensa-hifi
kernel-module-xtensa-hifi:
	mkdir -p $(ADSP_MODULE_OUT)
	cp -R $(ADSP_MODULE_PATH)/* $(ADSP_MODULE_OUT)/
	make -C $(ADSP_MODULE_OUT) $(KERNEL_COMPILE_FLAGS) ARCH="arm64" KERNELSRC=$(ANDROID_ROOT)/$(TARGET_KERNEL_SOURCE) KERNELDIR=$(KERNEL_OUT) M=$(ADSP_MODULE_OUT)
	mv $(ADSP_MODULE_OUT)/xtensa-hifi.ko $(TARGET_KERNEL_MODULES_OUT)/

TARGET_KERNEL_EXT_MODULES += \
	kernel-module-pvrsrvkm \
	kernel-module-vspm \
	kernel-module-vspmif \
	kernel-module-mmngr \
	kernel-module-mmngrbuf \
	kernel-module-uvcs \
	kernel-module-qos \
	kernel-module-ethavb-streaming \
	kernel-module-ethavb-mch \
	kernel-module-ethavb-mse

ifeq ($(ENABLE_ADSP),true)
	TARGET_KERNEL_EXT_MODULES += kernel-module-xtensa-hifi
endif
