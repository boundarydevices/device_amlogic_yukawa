$(call inherit-product, device/amlogic/yukawa/device-common.mk)

BOARD_KERNEL_DTB := device/amlogic/yukawa-kernel/meson-g12a-sei510.dtb

ifeq ($(TARGET_PREBUILT_DTB),)
LOCAL_DTB := $(BOARD_KERNEL_DTB)
else
LOCAL_DTB := $(TARGET_PREBUILT_DTB)
endif

PRODUCT_COPY_FILES +=  $(LOCAL_DTB):meson-g12a-sei510.dtb

