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

PRODUCT_ABS_OUT         := $(abspath $(PRODUCT_OUT))
BOOTLOADER_OUT          := $(PRODUCT_ABS_OUT)/obj/BOOTLOADER_OBJ
BOOTLOADER_HF_OUT       := $(PRODUCT_ABS_OUT)/obj/BOOTLOADER_HF_OBJ

$(BOOTLOADER_OUT):
	$(hide) mkdir -p $(BOOTLOADER_OUT)

$(BOOTLOADER_HF_OUT):
	$(hide) mkdir -p $(BOOTLOADER_HF_OUT)

bootloader: $(BOOTLOADER_OUT) u-boot.bin bootparam_sa0.bin cert_header_sa6.bin bl2.bin bl31.bin tee.bin
	$(hide) cp $(PRODUCT_OUT_ABS)/bootparam_sa0.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/cert_header_sa6.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/bl2.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/bl31.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/u-boot.bin $(BOOTLOADER_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/tee.bin $(BOOTLOADER_OUT)/

bootloader_hf: $(BOOTLOADER_HF_OUT) u-boot_hf.bin bootparam_sa0_hf.bin cert_header_sa6_hf.bin bl2_hf.bin bl31_hf.bin tee_hf.bin
	$(hide) cp $(PRODUCT_OUT_ABS)/bootparam_sa0_hf.bin $(BOOTLOADER_HF_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/cert_header_sa6_hf.bin $(BOOTLOADER_HF_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/bl2_hf.bin $(BOOTLOADER_HF_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/bl31_hf.bin $(BOOTLOADER_HF_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/u-boot_hf.bin $(BOOTLOADER_HF_OUT)/
	$(hide) cp $(PRODUCT_OUT_ABS)/tee_hf.bin $(BOOTLOADER_HF_OUT)/

include $(CLEAR_VARS)

# Build bootloader image for emmc
BOOTLOADER_EMMC := bootloader.img
BOOTLOADER_EMMC_IMG_PATH := $(BOOTLOADER_OUT)/$(BOOTLOADER_EMMC)

$(BOOTLOADER_EMMC_IMG_PATH): bootloader pack_ipl_emmc
	$(hide) pack_ipl_emmc all $(BOOTLOADER_OUT)

$(PRODUCT_OUT)/$(BOOTLOADER_EMMC) : $(BOOTLOADER_EMMC_IMG_PATH)
	$(hide) cp $(BOOTLOADER_EMMC_IMG_PATH) $(PRODUCT_OUT)/$(BOOTLOADER_EMMC)

LOCAL_MODULE := $(BOOTLOADER_EMMC)
LOCAL_PREBUILT_MODULE_FILE := $(BOOTLOADER_EMMC_IMG_PATH)
LOCAL_MODULE_PATH := $(PRODUCT_OUT_ABS)

include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

# Build bootloader image for hf (deprecated and eventually, it should be removed)
BOOTLOADER_HF := bootloader_hf.img
BOOTLOADER_HF_IMG_PATH := $(BOOTLOADER_HF_OUT)/$(BOOTLOADER_HF)

$(BOOTLOADER_HF_IMG_PATH): bootloader_hf pack_ipl_hf
	$(hide) pack_ipl_hf all $(BOOTLOADER_HF_OUT)

$(PRODUCT_OUT)/$(BOOTLOADER_HF) : $(BOOTLOADER_HF_IMG_PATH)
	$(hide) cp $(BOOTLOADER_HF_IMG_PATH) $(PRODUCT_OUT)/$(BOOTLOADER_HF)

LOCAL_MODULE := $(BOOTLOADER_HF)
LOCAL_PREBUILT_MODULE_FILE := $(BOOTLOADER_HF_IMG_PATH)
LOCAL_MODULE_PATH := $(PRODUCT_OUT_ABS)

include $(BUILD_EXECUTABLE)
