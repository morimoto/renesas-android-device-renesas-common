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
#define RCAR_ION_MAGIC 'R'
#define RCAR_ION_CUSTOM _IOWR(RCAR_ION_MAGIC, 6, struct ion_custom_data)
enum RCAR_CUSTOM_COMMANDS {
  RCAR_GET_PHYS_ADDR = 1,
};
#endif
