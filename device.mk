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

# Setup TV Build
USE_OEM_TV_APP := true
$(call inherit-product, device/google/atv/products/atv_base.mk)
PRODUCT_CHARACTERISTICS := tv
PRODUCT_AAPT_PREF_CONFIG := tvdpi
PRODUCT_IS_ATV := true
DEVICE_PACKAGE_OVERLAYS := device/amlogic/yukawa/overlay
DEVICE_PACKAGE_OVERLAYS += device/google/atv/overlay

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/fstab.yukawa:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.yukawa \
    $(LOCAL_PATH)/init.yukawa.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.yukawa.rc \
    $(LOCAL_PATH)/init.yukawa.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.yukawa.usb.rc \
    $(LOCAL_PATH)/ueventd.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml

# TV Specific Packages
PRODUCT_PACKAGES += \
    LiveTv \
    google-tv-pairing-protocol \
    TvProvision \
    LeanbackSampleApp \
    TvSampleLeanbackLauncher \
    tv_input.default \
    com.android.media.tv.remoteprovider \
    InputDevices

PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=260

PRODUCT_PACKAGES +=  libGLES_mali
PRODUCT_PACKAGES +=  libGLES_android

# Build default bluetooth a2dp and usb audio HALs
PRODUCT_PACKAGES += \
    audio.usb.default \
    audio.primary.yukawa \
    audio.a2dp.default \
    tinyplay \
    tinycap \
    tinymix \
    tinypcminfo \
    cplay

PRODUCT_PACKAGES += \
    android.hardware.audio@2.0-service \
    android.hardware.audio@2.0-impl \
    android.hardware.audio.effect@2.0-impl \
    android.hardware.broadcastradio@1.0-impl \
    android.hardware.soundtrigger@2.0-impl

# Hardware Composer HAL
#
PRODUCT_PACKAGES += \
    hwcomposer.drm_meson \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \

# Memtrack
PRODUCT_PACKAGES += memtrack.default \
    android.hardware.memtrack@1.0-service \
    android.hardware.memtrack@1.0-impl

PRODUCT_PACKAGES += \
    gralloc.yukawa \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.mapper@2.0-impl

PRODUCT_PACKAGES += \
    gatekeeper.yukawa \
    android.hardware.gatekeeper@1.0-impl \
    android.hardware.gatekeeper@1.0-service

PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service

# USB
PRODUCT_PACKAGES += \
	android.hardware.usb@1.0-service

PRODUCT_COPY_FILES +=  \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml

# audio policy configuration
USE_XML_AUDIO_POLICY_CONF := 1
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml

# Copy media codecs config file
PRODUCT_COPY_FILES += \
    device/amlogic/yukawa/media_xml/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml

# Enable AVB
BOARD_AVB_ENABLE := false
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_ROLLBACK_INDEX := 0
