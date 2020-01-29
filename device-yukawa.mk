ifndef TARGET_KERNEL_USE
TARGET_KERNEL_USE=4.19
endif

$(call inherit-product, device/amlogic/yukawa/device-common.mk)

ifeq ($(TARGET_VIM3L),)
PRODUCT_PROPERTY_OVERRIDES += ro.product.device=sei610
else
PRODUCT_PROPERTY_OVERRIDES += ro.product.device=vim3l
endif


BOARD_KERNEL_DTB := device/amlogic/yukawa-kernel/

ifeq ($(TARGET_PREBUILT_DTB),)
LOCAL_DTB := $(BOARD_KERNEL_DTB)
else
LOCAL_DTB := $(TARGET_PREBUILT_DTB)
endif

# Feature permissions
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/permissions/yukawa.xml:/system/etc/sysconfig/yukawa.xml
