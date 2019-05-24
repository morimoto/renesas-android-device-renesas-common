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

full_ota_name := $(TARGET_PRODUCT)
target_file_name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
	target_file_name := $(target_file_name)_debug
	full_ota_name := $(full_ota_name)_debug
endif
full_ota_name := $(full_ota_name)-full_ota-$(FILE_NAME_TAG)
target_file_name := $(target_file_name)-target_files-$(FILE_NAME_TAG)

CUSTOM_IMAGES_PATH := $(patsubst %, $(PRODUCT_OUT)/%.img, $(AB_OTA_CUSTOM_PARTITIONS))
ZIP_ROOT := $(call intermediates-dir-for,PACKAGING,target_files)/$(target_file_name)
KEY_CERT_PAIR := build/target/product/security/testkey
FULL_OTA_PACKAGE_TARGET := $(PRODUCT_OUT)/$(full_ota_name).zip
CUSTOM_VBMETA := $(ZIP_ROOT)/IMAGES/vbmeta.img

$(FULL_OTA_PACKAGE_TARGET) : target-files-package \
	build/make/tools/releasetools/add_img_to_target_files \
	build/make/tools/releasetools/ota_from_target_files \
	$(SOONG_ZIP) \
	$(CUSTOM_IMAGES_PATH)

	$(hide) for part in $(AB_OTA_CUSTOM_PARTITIONS); do \
	  echo "$${part}" >> $(ZIP_ROOT)/META/ab_partitions.txt; \
	done
	$(hide) mkdir -p $(ZIP_ROOT)/IMAGES
	$(hide) for img in $(CUSTOM_IMAGES_PATH); do \
	  cp "$${img}" $(ZIP_ROOT)/IMAGES/; \
	done
	$(hide) $(AVBTOOL) make_vbmeta_image \
	  --algorithm SHA256_RSA4096 \
	  --key external/avb/test/data/testkey_rsa4096.pem \
	  --padding_size 4096 --output $(CUSTOM_VBMETA) \
	  --include_descriptors_from_image $(ZIP_ROOT)/IMAGES/boot.img \
	  --include_descriptors_from_image $(ZIP_ROOT)/IMAGES/dtbo.img \
	  --include_descriptors_from_image $(ZIP_ROOT)/IMAGES/system.img \
	  --include_descriptors_from_image $(ZIP_ROOT)/IMAGES/vendor.img \
	  --include_descriptors_from_image $(ZIP_ROOT)/IMAGES/product.img \
	  --include_descriptors_from_image $(ZIP_ROOT)/IMAGES/odm.img
	$(hide) find $(ZIP_ROOT)/META | sort >$(BUILT_TARGET_FILES_PACKAGE).list
	$(hide) find $(ZIP_ROOT) -path $(ZIP_ROOT)/META -prune -o -print \
		| sort >>$(BUILT_TARGET_FILES_PACKAGE).list
	$(hide) $(SOONG_ZIP) -d -o $(BUILT_TARGET_FILES_PACKAGE) -C $(ZIP_ROOT) -l $(BUILT_TARGET_FILES_PACKAGE).list

	@echo "Package Full-OTA: $@"
	build/make/tools/releasetools/ota_from_target_files -v \
	--block \
	--extracted_input_target_files $(patsubst %.zip,%,$(BUILT_TARGET_FILES_PACKAGE)) \
	-p $(HOST_OUT) \
	-k $(KEY_CERT_PAIR) \
	$(BUILT_TARGET_FILES_PACKAGE) $@

full_otapackage: $(FULL_OTA_PACKAGE_TARGET)
