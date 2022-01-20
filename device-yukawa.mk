ifndef TARGET_KERNEL_USE
TARGET_KERNEL_USE=4.19
endif

# BD overrides
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_DEFCONFIG := meson_defconfig
TARGET_OUT_INTERMEDIATES := out/target/product/yukawa/obj
TARGET_KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
TARGET_PREBUILT_DTB := $(TARGET_KERNEL_OUT)/arch/arm64/boot/dts/amlogic
TARGET_PREBUILT_KERNEL := $(TARGET_KERNEL_OUT)/arch/arm64/boot/Image.lz4
TARGET_USE_TABLET_LAUNCHER := true
TARGET_AVB_ENABLE := true
BOARD_VENDOR_KERNEL_MODULES += \
    $(TARGET_OUT_INTERMEDIATES)/QCACLD_OBJ/wlan.ko
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/init.insmod.cfg \
    device/amlogic/yukawa/init.insmod.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.insmod.sh

PRODUCT_PACKAGES += \
    bdwlan30.bin \
    cfg.dat \
    otp30.bin \
    qcom_cfg.ini \
    qwlan30.bin \
    tfbtfw11.tlv \
    tfbtnv11.bin

$(call inherit-product, device/amlogic/yukawa/device-common.mk)

ifeq ($(TARGET_VIM3), true)
PRODUCT_PROPERTY_OVERRIDES += ro.product.device=vim3
AUDIO_DEFAULT_OUTPUT := hdmi
GPU_TYPE := gondul_ion
else ifeq ($(TARGET_VIM3L), true)
PRODUCT_PROPERTY_OVERRIDES += ro.product.device=vim3l
AUDIO_DEFAULT_OUTPUT := hdmi
else
PRODUCT_PROPERTY_OVERRIDES += ro.product.device=a311d-bd-som
AUDIO_DEFAULT_OUTPUT := hdmi
GPU_TYPE := gondul_ion
endif
GPU_TYPE ?= dvalin_ion

BOARD_KERNEL_DTB := device/amlogic/yukawa-kernel/$(TARGET_KERNEL_USE)

ifeq ($(TARGET_PREBUILT_DTB),)
LOCAL_DTB := $(BOARD_KERNEL_DTB)
else
LOCAL_DTB := $(TARGET_PREBUILT_DTB)
endif

# Feature permissions
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/permissions/yukawa.xml:/system/etc/sysconfig/yukawa.xml

# Speaker EQ
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/hal/audio/speaker_eq_sei610.fir:$(TARGET_COPY_OUT_VENDOR)/etc/speaker_eq_sei610.fir
