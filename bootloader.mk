#
# Copyright (C) 2011 The Android Open-Source Project
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

PRODUCT_OUT_ABS := $(abspath $(PRODUCT_OUT))

BOOTLOADER_OUT=$(PRODUCT_OUT_ABS)/obj/BOOTLOADER_OBJ
EMMC_PACK_DIR=$(abspath $(HOST_OUT)/bin)

.PHONY: bootloader_out_dir
bootloader_out_dir:
	$(MKDIR) -p $(BOOTLOADER_OUT)

.PHONY: bootloader
bootloader: bootloader_out_dir u-boot.bin bootparam_sa0.bin cert_header_sa6.bin bl2.bin bl31.bin tee.bin
	$(hide) cp $(PRODUCT_OUT_ABS)/bootparam_sa0.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/cert_header_sa6.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/bl2.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/bl31.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/u-boot.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/tee.bin $(BOOTLOADER_OUT)/

#include $(CLEAR_VARS)

# Build bootloader image for emmc
BOOTLOADER_EMMC := bootloader.img
BOOTLOADER_EMMC_IMG_PATH := $(BOOTLOADER_OUT)/$(BOOTLOADER_EMMC)

.PHONY: bootloader_emmc_img
bootloader_emmc_img: bootloader pack_ipl_emmc
	$(hide) $(EMMC_PACK_DIR)/pack_ipl_emmc all $(BOOTLOADER_OUT)

.PHONY: $(BOOTLOADER_EMMC)
$(BOOTLOADER_EMMC) : bootloader_emmc_img
	$(hide) cp $(BOOTLOADER_EMMC_IMG_PATH) $(PRODUCT_OUT)/$(BOOTLOADER_EMMC)
