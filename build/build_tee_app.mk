#
# Copyright (C) 2019 GlobalLogic
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

TA_OUT_INTERMEDIATES    := $(abspath $(PRODUCT_OUT)/obj/TA_OBJ)
OPTEE_OUT               := $(abspath $(PRODUCT_OUT)/obj/OPTEE_OBJ)
OPTEE_CROSS_COMPILE     := $(BSP_CROSS_COMPILE)

###########################################################
## Rules for building Trusted Application (TA)           ##
## executable file.                                      ##
###########################################################

ifeq ($(TA_UUID),)
$(error TA_UUID variable is not set)
endif

ifeq ($(TA_SRC),)
$(error TA_SRC variable is not set)
endif

# TA intermediates output folder
TA_OUT := $(TA_OUT_INTERMEDIATES)/$(TA_UUID)_OBJ

# OP-TEE TA developer kit
TA_DEV_KIT_DIR := $(OPTEE_OUT)/export-ta_arm64

# OP-TEE Trusted OS is dependency for TA
.PHONY: TA_OUT_$(TA_UUID)
TA_OUT_$(TA_UUID): tee.bin
	mkdir -p $(TA_OUT)
	mkdir -p $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/optee_armtz

TA_TARGET := $(TA_UUID)_ta

# Parameters for target TA
TA_UUID-$(TA_TARGET) := $(TA_UUID)
TA_SRC-$(TA_TARGET) := $(TA_SRC)
TA_OUT-$(TA_TARGET) := $(TA_OUT)

# Build with OP-TEE Trusted OS build system
.PHONY: $(TA_TARGET)
$(TA_TARGET): TA_OUT_$(TA_UUID)
	CROSS_COMPILE=$(BSP_GCC_CROSS_COMPILE) BINARY=$(TA_UUID-$@) TA_DEV_KIT_DIR=$(TA_DEV_KIT_DIR) make -C $(TA_SRC-$@) O=$(TA_OUT-$@) clean
	CROSS_COMPILE=$(BSP_GCC_CROSS_COMPILE) BINARY=$(TA_UUID-$@) TA_DEV_KIT_DIR=$(TA_DEV_KIT_DIR) make -C $(TA_SRC-$@) O=$(TA_OUT-$@) all

.PHONY: $(TA_UUID).ta
$(TA_UUID).ta: $(TA_TARGET)
	cp $(TA_OUT)/$(TA_UUID).ta $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/optee_armtz/$(TA_UUID).ta
