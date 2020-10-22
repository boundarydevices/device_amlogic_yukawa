include device/amlogic/yukawa/BoardConfigCommon.mk

ifeq ($(TARGET_VIM3), true)
TARGET_BOOTLOADER_BOARD_NAME := vim3
else ifeq ($(TARGET_VIM3L), true)
TARGET_BOOTLOADER_BOARD_NAME := vim3l
else
TARGET_BOOTLOADER_BOARD_NAME := sei610
endif

TARGET_BOARD_INFO_FILE := device/amlogic/yukawa/sei610/board-info.txt

ifeq ($(TARGET_USE_AB_SLOT), true)
BOARD_USERDATAIMAGE_PARTITION_SIZE := 10730078208
else
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12870221824
endif