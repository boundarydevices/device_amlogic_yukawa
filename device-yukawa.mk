$(call inherit-product, device/amlogic/yukawa/device-common.mk)

ifeq ($(TARGET_VIM3L),)
# Light HAL
PRODUCT_PACKAGES += \
    lights.yukawa \
    android.hardware.light@2.0-impl:64 \
    android.hardware.light@2.0-service

TARGET_DTB := meson-sm1-sei610.dtb
else
TARGET_DTB := meson-sm1-khadas-vim3l.dtb
endif

BOARD_KERNEL_DTB := device/amlogic/yukawa-kernel/$(TARGET_DTB)

ifeq ($(TARGET_PREBUILT_DTB),)
LOCAL_DTB := $(BOARD_KERNEL_DTB)
else
LOCAL_DTB := $(TARGET_PREBUILT_DTB)
endif

PRODUCT_COPY_FILES +=  $(LOCAL_DTB):$(TARGET_DTB)

# Feature permissions
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/permissions/yukawa.xml:/system/etc/sysconfig/yukawa.xml
