# Inherit the full_base and device configurations
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, device/amlogic/yukawa/device.mk)

PRODUCT_SYSTEM_VERITY_PARTITION := /dev/block/platform/ffe07000.emmc/by-name/system
PRODUCT_VENDOR_VERITY_PARTITION := /dev/block/platform/ffe07000.emmc/by-name/vendor
$(call inherit-product, build/target/product/verity.mk)
PRODUCT_SUPPORTS_BOOT_SIGNER := false

PRODUCT_NAME := yukawa
PRODUCT_DEVICE := yukawa
PRODUCT_BRAND := Android
PRODUCT_MODEL := ATV on yukawa

