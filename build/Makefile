# below variables are defined in AOSP build makefile, to build kernel independently, redefine them here
hide := @

PRODUCT_OUT := ${OUT}
TARGET_OUT_INTERMEDIATES := $(PRODUCT_OUT)/obj
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ

include ${product_path}/device-yukawa.mk
include ${product_path}/build/kernel/kernel.mk
include ${product_path}/build/kernel/qcacld.mk
