# Targets for builing kernels
#
# The following must be set before including this file:
# TARGET_KERNEL_DEFCONFIG must name a base kernel config.
# TARGET_KERNEL_ARCH must be set to match kernel arch.
#
# The following maybe set:
# TARGET_KERNEL_SRC must point to the kernel tree.
# ENABLE_GCC_BUILD which enbale external gcc compiler

TARGET_KERNEL_SRC ?= $(ANDROID_BUILD_TOP)/vendor/boundary/kernel

ifeq ($(TARGET_KERNEL_DEFCONFIG),)
$(error TARGET_KERNEL_DEFCONFIG not defined)
endif

ifeq ($(TARGET_KERNEL_ARCH),)
$(error TARGET_KERNEL_ARCH not defined)
endif

# Check target arch.
TARGET_KERNEL_ARCH := $(strip $(TARGET_KERNEL_ARCH))
KERNEL_ARCH := $(TARGET_KERNEL_ARCH)
KERNEL_CC_WRAPPER := $(CC_WRAPPER)
KERNEL_AFLAGS :=

CLANG_TO_COMPILE := LLVM=1 LLVM_IAS=1
CLANG_PATH := $(realpath prebuilts/clang/host/linux-x86)
CLANG_BIN := $(CLANG_PATH)/clang-r416183b1/bin
ifeq (,$(wildcard $(CLANG_BIN)))
$(error CLANG_BIN:$(CLANG_BIN) does not exist)
endif

ifeq ($(TARGET_KERNEL_ARCH), arm)
KERNEL_CFLAGS :=
CLANG_TRIPLE := CLANG_TRIPLE=$(strip $(AARCH32_GCC_CROSS_COMPILE))
KERNEL_SRC_ARCH := arm
KERNEL_NAME := zImage
else ifeq ($(TARGET_KERNEL_ARCH), arm64)
CLANG_TRIPLE := CLANG_TRIPLE=$(strip $(AARCH64_GCC_CROSS_COMPILE))
KERNEL_SRC_ARCH := arm64
KERNEL_CFLAGS :=
KERNEL_NAME ?= Image.lz4
else
$(error kernel arch not supported at present)
endif

ENABLE_GCC_BUILD ?= false
ifeq ($(ENABLE_GCC_BUILD), true)
CLANG_TRIPLE :=
CLANG_TO_COMPILE :=
CLANG_BIN :=
endif

ifeq ($(TARGET_KERNEL_ARCH), arm)
ifneq ($(AARCH32_GCC_CROSS_COMPILE),)
KERNEL_CROSS_COMPILE := $(strip $(AARCH32_GCC_CROSS_COMPILE))
else
$(error shell env AARCH32_GCC_CROSS_COMPILE is not set)
endif
else ifeq ($(TARGET_KERNEL_ARCH), arm64)
ifneq ($(AARCH64_GCC_CROSS_COMPILE),)
KERNEL_CROSS_COMPILE := $(strip $(AARCH64_GCC_CROSS_COMPILE))
else
$(error shell env AARCH64_GCC_CROSS_COMPILE is not set)
endif
endif

# Use ccache if requested by USE_CCACHE variable
KERNEL_CROSS_COMPILE_WRAPPER := $(realpath $(KERNEL_CC_WRAPPER)) $(KERNEL_CROSS_COMPILE)

ifeq ($(CLANG_TO_COMPILE),)
KERNEL_GCC_NOANDROID_CHK := $(shell (echo "int main() {return 0;}" | $(KERNEL_CROSS_COMPILE)gcc -E -mno-android - > /dev/null 2>&1 ; echo $$?))
else
KERNEL_GCC_NOANDROID_CHK := $(shell (echo "int main() {return 0;}" | $(CLANG_BIN)clang --target=$(CLANG_TRIPLE:%-=%) \
  -E -mno-android - > /dev/null 2>&1 ; echo $$?))
endif

ifeq ($(strip $(KERNEL_GCC_NOANDROID_CHK)),0)
KERNEL_CFLAGS += -mno-android
KERNEL_AFLAGS += -mno-android
endif

# options are used to eliminate compilation errors with qca wifi driver when use clang
ifneq ($(CLANG_TO_COMPILE),)
KERNEL_CFLAGS := -Wno-incompatible-pointer-types
endif

# Set the output for the kernel build products.
KERNEL_BIN := $(TARGET_KERNEL_OUT)/arch/$(KERNEL_SRC_ARCH)/boot/$(KERNEL_NAME)

# Figure out which kernel version is being built (disregard -stable version).
KERNEL_VERSION := $(shell PATH=$$PATH $(MAKE) --no-print-directory -C $(TARGET_KERNEL_SRC) -s SUBLEVEL="" kernelversion)

# Kernel config file sources.
KERNEL_CONFIG := $(TARGET_KERNEL_OUT)/.config
KERNEL_CONFIG_DEFAULT := $(realpath $(TARGET_KERNEL_SRC)/arch/$(KERNEL_SRC_ARCH)/configs/$(TARGET_KERNEL_DEFCONFIG))

$(TARGET_KERNEL_OUT):
	mkdir -p $@

# use deferred expansion
kernel_build_shell_env = PATH=$(CLANG_BIN):$(realpath prebuilts/misc/linux-x86/lz4):$${PATH} \
	$(CLANG_TRIPLE) CCACHE_NODIRECT="true"
kernel_build_common_env = ARCH=$(KERNEL_ARCH) CROSS_COMPILE=$(strip $(KERNEL_CROSS_COMPILE_WRAPPER)) \
	KCFLAGS="$(KERNEL_CFLAGS)" KAFLAGS="$(KERNEL_AFLAGS)"
kernel_build_make_env = $(kernel_build_common_env) $(CLANG_TO_COMPILE) -C $(TARGET_KERNEL_SRC) O=$(realpath $(TARGET_KERNEL_OUT))

$(KERNEL_CONFIG): $(KERNEL_CONFIG_DEFAULT) $(TARGET_KERNEL_SRC) | $(TARGET_KERNEL_OUT)
	$(hide) echo Configuring kernel: $(KERNEL_CONFIG_SRC)
	$(hide) $(kernel_build_shell_env) $(MAKE) $(kernel_build_make_env) $(TARGET_KERNEL_DEFCONFIG)

$(KERNEL_BIN): $(KERNEL_CONFIG) $(TARGET_KERNEL_SRC) | $(TARGET_KERNEL_OUT)
	$(hide) echo "Building $(KERNEL_ARCH) $(KERNEL_VERSION) kernel ..."
	$(hide) if [ ${clean_build} = 1 ]; then \
		PATH=$$PATH $(MAKE) -C $(TARGET_KERNEL_SRC) O=$(realpath $(TARGET_KERNEL_OUT)) clean; \
	fi
	$(hide) $(kernel_build_shell_env) $(MAKE) $(kernel_build_make_env)
	$(hide) $(kernel_build_shell_env) lz4c -f $(TARGET_KERNEL_OUT)/arch/$(KERNEL_SRC_ARCH)/boot/Image \
		$(TARGET_KERNEL_OUT)/arch/$(KERNEL_SRC_ARCH)/boot/Image.lz4

kernel: $(KERNEL_BIN)
