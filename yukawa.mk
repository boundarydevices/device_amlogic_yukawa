# Inherit the full_base and device configurations
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, device/amlogic/yukawa/device.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

PRODUCT_NAME := yukawa
PRODUCT_DEVICE := yukawa
PRODUCT_BRAND := Android
PRODUCT_MODEL := ATV on yukawa

