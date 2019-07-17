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

ifneq (,$(filter $(TARGET_PRODUCT), salvator ulcb kingfisher))

full_ota_name := $(TARGET_PRODUCT)
target_file_name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
	target_file_name := $(target_file_name)_debug
	full_ota_name := $(full_ota_name)_debug
endif
full_ota_name := $(full_ota_name)-full_ota-$(FILE_NAME_TAG)
target_file_name := $(target_file_name)-target_files-$(FILE_NAME_TAG)

ZIP_ROOT := $(call intermediates-dir-for,PACKAGING,target_files)/$(target_file_name)
KEY_CERT_PAIR := build/target/product/security/testkey
FULL_OTA_PACKAGE_TARGET := $(PRODUCT_OUT)/$(full_ota_name).zip

# Ota-package with bootloaders
full_otapackage: otapackage \
	build/make/tools/releasetools/add_img_to_target_files \
	build/make/tools/releasetools/ota_from_target_files \
	$(SOONG_ZIP) \
	bootloader.img

	echo "bootloader" >> $(ZIP_ROOT)/META/ab_partitions.txt;
	cp $(abspath $(PRODUCT_OUT)/bootloader.img) $(ZIP_ROOT)/IMAGES/

	$(hide) find $(ZIP_ROOT)/META | sort >$(BUILT_TARGET_FILES_PACKAGE).list
	$(hide) find $(ZIP_ROOT) -path $(ZIP_ROOT)/META -prune -o -print \
		| sort >> $(BUILT_TARGET_FILES_PACKAGE).list
	$(hide) $(SOONG_ZIP) -d -o $(BUILT_TARGET_FILES_PACKAGE) -C $(ZIP_ROOT) -l $(BUILT_TARGET_FILES_PACKAGE).list

	@echo "Package Full-OTA: $(FULL_OTA_PACKAGE_TARGET)"
	build/make/tools/releasetools/ota_from_target_files -v \
	--block --output_metadata_path $(abspath $(PRODUCT_OUT)/ota_metadata) \
	--extracted_input_target_files $(abspath $(patsubst %.zip,%,$(BUILT_TARGET_FILES_PACKAGE))) \
	-p $(abspath $(HOST_OUT)) \
	-k $(abspath $(KEY_CERT_PAIR)) \
	$(abspath $(BUILT_TARGET_FILES_PACKAGE)) $(abspath $(FULL_OTA_PACKAGE_TARGET))

.PHONY: full_otapackage

endif