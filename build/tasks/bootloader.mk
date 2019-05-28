#
# Copyright (C) 2011 The Android Open-Source Project
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
#

ifneq (,$(filter $(TARGET_PRODUCT), salvator ulcb kingfisher))

ifeq ($(PRODUCT_OUT),)
$(error "PRODUCT_OUT is not set")
endif

PRODUCT_OUT_ABS := $(abspath $(PRODUCT_OUT))

.PHONY: bootloaderimage
bootloaderimage: pack_ipl_emmc
bootloaderimage: u-boot.bin bootparam_sa0.bin cert_header_sa6.bin bl2.bin bl31.bin tee.bin
	$(HOST_OUT_EXECUTABLES)/pack_ipl_emmc all $(PRODUCT_OUT_ABS)
	@rm $(PRODUCT_OUT_ABS)/bootparam_sa0.bin
	@rm $(PRODUCT_OUT_ABS)/cert_header_sa6.bin
	@rm $(PRODUCT_OUT_ABS)/bl2.bin
	@rm $(PRODUCT_OUT_ABS)/bl31.bin
	@rm $(PRODUCT_OUT_ABS)/u-boot.bin
	@rm $(PRODUCT_OUT_ABS)/tee.bin
	@echo "Bootloader image: $(PRODUCT_OUT)/bootloader.img"

.PHONY: bootloader.img
bootloader.img: bootloaderimage

ifeq ($(BUILD_BOOTLOADERS),true)
droidcore: bootloaderimage
ifeq ($(BUILD_BOOTLOADERS_SREC),true)
droidcore: bootparam_sa0.srec cert_header_sa6.srec bl2.srec bl31.srec u-boot-elf.srec tee.srec
endif
endif

endif # TARGET_PRODUCT salvator ulcb kingfisher
