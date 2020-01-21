include device/amlogic/yukawa/BoardConfigCommon.mk

ifeq ($(TARGET_VIM3L),)
DEVICE_MANIFEST_FILE += device/amlogic/yukawa/yukawa/manifest.xml
endif

BOARD_USERDATAIMAGE_PARTITION_SIZE := 13416529920

TARGET_BOARD_INFO_FILE := device/amlogic/yukawa/sei610/board-info.txt
