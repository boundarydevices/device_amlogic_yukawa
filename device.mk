ifeq ($(TARGET_PREBUILT_KERNEL),)
LOCAL_KERNEL := device/amlogic/yukawa-kernel/Image.lz4
else
LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

ifeq ($(TARGET_PREBUILT_DTB),)
LOCAL_DTB := device/amlogic/yukawa-kernel/meson-g12a-sei510.dtb
else
LOCAL_DTB := $(TARGET_PREBUILT_DTB)
endif

PRODUCT_COPY_FILES +=  $(LOCAL_KERNEL):kernel \
                       $(LOCAL_DTB):meson-g12a-sei510.dtb \

# Build and run only ART
PRODUCT_RUNTIMES := runtime_libart_default

DEVICE_PACKAGE_OVERLAYS := device/amlogic/yukawa/overlay

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/fstab.yukawa:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.yukawa

# Enable AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_ROLLBACK_INDEX := 0
