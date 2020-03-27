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
#ifndef __UAPI_RCAR_ION_LMK_H__
#define __UAPI_RCAR_ION_LMK_H__
#include <linux/sched.h>
#ifndef TASK_COMM_LEN
#define TASK_COMM_LEN (16)
#endif
struct ion_proc_info {
  char comm[TASK_COMM_LEN];
  __u64 mem;
  __u32 pid;
};
struct ion_proc_info_buf {
  size_t size;
  struct ion_proc_info * info;
};
#define RCAR_ION_LMK_MAGIC 'L'
#define ION_IOC_GET_ION_CONSUMERS_СNТR _IOWR(RCAR_ION_LMK_MAGIC, 0, size_t)
#define ION_IOC_GET_ION_CONSUMERS_INFO _IOWR(RCAR_ION_LMK_MAGIC, 1, struct ion_proc_info_buf)
#endif
