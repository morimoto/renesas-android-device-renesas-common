/****************************************************************************
 ****************************************************************************
 ***
 ***   This header was automatically generated from a Linux kernel header
 ***   of the same name, to make information necessary for userspace to
 ***   call into the kernel available to libc.  It contains only constants,
 ***   structures, and macros generated from the original header, and thus,
 ***   contains no copyrightable information.
 ***
 ***   To edit the content of this header, modify the corresponding
 ***   source file (e.g. under external/kernel-headers/original/) then
 ***   run bionic/libc/kernel/tools/update_all.py
 ***
 ***   Any manual change here will be lost the next time this script will
 ***   be run. You've been warned!
 ***
 ****************************************************************************
 ****************************************************************************/
#ifndef __UAPI_RCAR_ION_H__
#define __UAPI_RCAR_ION_H__
struct ion_custom_data {
  unsigned int cmd;
  unsigned long arg;
};
struct ion_phys_addr {
  unsigned int dma_fd;
  unsigned long phys_addr;
};
enum OOM_EVENTS {
  OOM_THRESHOLD = 1,
  OOM_ERROR = 2,
};
enum OOM_STATE {
  OOM_RELEASED = 1,
  OOM_WAIT_EVENT,
};
struct ion_oom_event {
  __u64 memory_available;
  __u64 oom_threshold;
  __u32 oom_event;
  enum OOM_STATE state;
};
#define RCAR_ION_MAGIC 'R'
#define RCAR_ION_CUSTOM _IOWR(RCAR_ION_MAGIC, 6, struct ion_custom_data)
enum RCAR_CUSTOM_COMMANDS {
  RCAR_GET_PHYS_ADDR = 1,
  RCAR_GET_OOM_EVENT = 2,
};
#endif
