LOCAL_PATH := $(call my-dir)

################################################################################
# Build hyper flash driver CA                                                  #
################################################################################
include $(CLEAR_VARS)
LOCAL_CFLAGS += -DANDROID_BUILD
LOCAL_CFLAGS += $(CFLAGS)

LOCAL_SRC_FILES += activate.c bitmap.c classify.c cputree.c irqbalance.c \
        irqlist.c numa.c placement.c procinterrupts.c glib/glist.c

LOCAL_C_INCLUDES := $(LOCAL_PATH)/glib

LOCAL_MODULE := irqbalance
LOCAL_MODULE_TAGS := optional
LOCAL_PROPRIETARY_MODULE=true

include $(BUILD_EXECUTABLE)
