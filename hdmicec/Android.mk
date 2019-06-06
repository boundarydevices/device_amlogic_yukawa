#
# Copyright (C) 2019 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# WARNING: Everything listed here will be built on ALL platforms,
# including x86, the emulator, and the SDK.  Modules must be uniquely
# named (liblights.tuna), and must build everywhere, or limit themselves
# to only building on ARM if they include assembly. Individual makefiles
# are responsible for having their own logic, for fine-grained control.

LOCAL_PATH:= $(call my-dir)
# HAL module implementation, not prelinked and stored in
# hw/<COPYPIX_HARDWARE_MODULE_ID>.<ro.board.platform>.so
include $(CLEAR_VARS)

LOCAL_SRC_FILES := hdmi_cec.c
LOCAL_CFLAGS := -Werror

LOCAL_MODULE_RELATIVE_PATH := hw

LOCAL_SHARED_LIBRARIES := liblog libcutils

LOCAL_MODULE := hdmi_cec.$(TARGET_BOARD_PLATFORM)
LOCAL_MODULE_TAGS := optional

include $(BUILD_SHARED_LIBRARY)

########################################################
include $(CLEAR_VARS)

LOCAL_SRC_FILES := hdmi_cec_test_hal.c
LOCAL_SRC_FILES += hdmi_cec.c
LOCAL_CFLAGS := -Wno-error -Wno-unused-parameter

LOCAL_MODULE_PATH := $(TARGET_OUT)/bin

LOCAL_SHARED_LIBRARIES := liblog libcutils

LOCAL_MODULE := hdmicec_test
LOCAL_MODULE_TAGS := optional

include $(BUILD_EXECUTABLE)
