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

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_ODT := odt
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_ODM := odm

TARGET_NO_BOOTLOADER := true
TARGET_NO_KERNEL := false
TARGET_NO_RADIOIMAGE := true
TARGET_NO_RECOVERY := true

# Primary Arch
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a53

# Secondary Arch
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

TARGET_USES_64_BIT_BINDER := true

TARGET_USES_MKE2FS := true

TARGET_USES_HWC2 := true

BOARD_USES_RECOVERY_AS_BOOT := true
BOARD_USES_UNCOMPRESSED_BOOT := false
BOARD_USES_GENERIC_AUDIO := false
BOARD_USES_ALSA_AUDIO := true

AUDIOSERVER_MULTILIB := 64
BOARD_USE_64BITMEDIA := true
TARGET_ENABLE_MEDIADRM_64 := true

BOARD_HAVE_BLUETOOTH := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/renesas/$(TARGET_PRODUCT)/hal/bluetooth

USE_CAMERA_STUB := true
USE_OPENGL_RENDERER := true

TARGET_BOARD_INFO_FILE := device/renesas/$(TARGET_PRODUCT)/board-info.txt

TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := device/renesas/common/fstab
#TARGET_RECOVERY_UI_LIB := librecovery_ui_renesas

# Android images
#BOARD_USES_PRODUCTIMAGE := true
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_ODMIMAGE := true
BOARD_FLASH_BLOCK_SIZE := 512

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4

# RAW file system images
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_DTBIMAGE_PARTITION_SIZE := 1048576
BOARD_DTBOIMG_PARTITION_SIZE := 524288

# AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_SYSTEM_ADD_HASHTREE_FOOTER_ARGS := --do_not_generate_fec
BOARD_AVB_VENDOR_ADD_HASHTREE_FOOTER_ARGS := --do_not_generate_fec
BOARD_AVB_PRODUCT_ADD_HASHTREE_FOOTER_ARGS := --do_not_generate_fec
BOARD_AVB_ODM_ADD_HASHTREE_FOOTER_ARGS := --do_not_generate_fec

# Dynamic partitions
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true

# One group of partitions (system_a, vendor_a, product_a, odm_a)
# system=2357198848, vendor=268435456, product=524288000, odm=131072000
# Group size = 3280994304
# Reserved for metadata = 4194304

# Group size * slots + metadata ANDROID_MMC_ONE_SLOT
ifeq ($(ANDROID_MMC_ONE_SLOT),true)
  BOARD_SUPER_PARTITION_SIZE := 3285188608
else
  BOARD_SUPER_PARTITION_SIZE := 6566182912
endif

BOARD_GROUP_GENERAL_SIZE := 3280994304
BOARD_SUPER_PARTITION_GROUPS := group_general
BOARD_GROUP_GENERAL_PARTITION_LIST := system vendor product odm

# Enable dex-preoptimization to speed up first boot sequence
WITH_DEXPREOPT := true
ART_USE_HSPACE_COMPACT := true

# Wi-Fi
WPA_SUPPLICANT_VERSION           := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER      := NL80211
BOARD_HOSTAPD_DRIVER             := NL80211

# SELinux support
#BOARD_SEPOLICY_VERS              := 28.0
BOARD_PLAT_PRIVATE_SEPOLICY_DIR  += device/renesas/common/sepolicy/private
BOARD_VENDOR_SEPOLICY_DIRS       += device/renesas/common/sepolicy/vendor
BOARD_VENDOR_SEPOLICY_DIRS       += device/renesas/$(TARGET_PRODUCT)/sepolicy/vendor

#PRODUCT_SEPOLICY_SPLIT           := true
#BOARD_ODM_SEPOLICY_DIRS          += device/renesas/$(TARGET_PRODUCT)/sepolicy/vendor

# Kernel build rules
BOARD_KERNEL_BASE                := 0x48000000
BOARD_MKBOOTIMG_ARGS             := --dtb_offset 0x800 --dtb $(PRODUCT_OUT)/dtb.img --kernel_offset 0x80000 --ramdisk_offset 0x2180000 --header_version 2
TARGET_KERNEL_SOURCE             := device/renesas/kernel

# Kernel headers
TARGET_BOARD_KERNEL_HEADERS      := device/renesas/common/kernel-headers

# Vendor Interface Manifest
DEVICE_MANIFEST_FILE             := device/renesas/$(TARGET_PRODUCT)/manifest.xml
DEVICE_MATRIX_FILE               := device/renesas/$(TARGET_PRODUCT)/compatibility_matrix.xml

# Move device specific properties to /vendor
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
BOARD_VNDK_VERSION                     := current
