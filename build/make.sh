#!/bin/bash
# Stop if a command fail
set -e

# help function, it display the usage of this script.
help() {
cat << EOF
    This script is executed after "source build/envsetup.sh" and "lunch".

    usage:
        `basename $0` <option>

        options:
           -h/--help               display this help info
           -j[<num>]               specify the number of parallel jobs when build the target, the number after -j should be greater than 0
           kernel                  kernel, include related dts will be compiled
           qcacld                  wlan.ko, the qcacld-2.0 driver will be compiled
           dtboimage               dtbo images will be built out
           bootimage               boot.img will be built out
           vendorbootimage         vendor_boot.img will be built out
           vendorimage             vendor.img will be built out
           -c                      use clean build for kernel, not incremental build

    an example to build the whole system with maximum parallel jobs as below:
        `basename $0` -j


EOF

exit;
}

# handle special args, now it is used to handle the option for make parallel jobs option(-j).
# the number after "-j" is the jobs in parallel, if no number after -j, use the max jobs in parallel.
# kernel now can't be controlled from this script, so by default use the max jobs in parallel to compile.
handle_special_arg()
{
    # options other than -j are all illegal
    local jobs;
    if [ ${1:0:2} = "-j" ]; then
        jobs=${1:2};
        if [ -z ${jobs} ]; then                                                # just -j option provided
            parallel_option="-j";
        else
            if [[ ${jobs} =~ ^[0-9]+$ ]] && [ ${jobs} -gt 0 ]; then           # integer bigger than 0 after -j
                 parallel_option="-j${jobs}";
            else
                echo invalid -j parameter;
                exit;
            fi
        fi
    else
        echo Unknown option: ${1};
        help;
    fi
}

# check whether the build product and build mode is selected
if [ -z ${OUT} ] || [ -z ${TARGET_PRODUCT} ]; then
    help;
fi

# global variables
build_bootloader_kernel_flag=0
build_android_flag=0
build_kernel=""
build_kernel_module_flag=0
build_qcacld=""
build_bootimage=""
build_vendorbootimage=""
build_dtboimage=""
build_vendorimage=""
parallel_option=""
clean_build=0
TOP=`pwd`

# Force the use of toolchains provided by BD
export AARCH64_GCC_CROSS_COMPILE=$TOP/prebuilts/toolchains/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

product_makefile=`pwd`/`find device -maxdepth 4 -name "${TARGET_PRODUCT}.mk"`;
product_path=${product_makefile%/*}

# process of the arguments
args=( "$@" )
for arg in ${args[*]} ; do
    case ${arg} in
        -h) help;;
        --help) help;;
        -c) clean_build=1;;
        kernel) build_bootloader_kernel_flag=1;
                    build_kernel="kernel";;
        qcacld) build_bootloader_kernel_flag=1;
                    build_kernel_module_flag=1
                    build_qcacld="qcacld";;
        bootimage) build_bootloader_kernel_flag=1;
                    build_android_flag=1;
                    build_kernel="kernel";
                    build_bootimage="bootimage";;
        vendorbootimage) build_bootloader_kernel_flag=1;
                    build_android_flag=1;
                    build_kernel="kernel";
                    build_vendorbootimage="vendorbootimage";;
        dtboimage) build_bootloader_kernel_flag=1;
                    build_android_flag=1;
                    build_kernel="kernel";
                    build_dtboimage="dtboimage";;
        vendorimage) build_bootloader_kernel_flag=1;
                    build_android_flag=1;
                    build_kernel="kernel";
                    build_vendorimage="vendorimage";;
        *) handle_special_arg ${arg};;
    esac
done

# if bootloader and kernel not in arguments, all need to be made
if [ ${build_bootloader_kernel_flag} -eq 0 ] && [ ${build_android_flag} -eq 0 ]; then
    build_kernel="kernel";
    build_android_flag=1
fi

# wlan.ko need build with kernel each time to make sure "insmod wlan.ko" works
if [ -n "${build_kernel}" ]; then
    build_qcacld="qcacld";
    build_kernel_module_flag=1;
fi

# redirect standard input to /dev/null to avoid manually input in kernel configuration stage
product_path=${product_path} clean_build=${clean_build} \
    make -C ./ -f ${product_path}/build/Makefile ${parallel_option} ${build_kernel} </dev/null || exit

if [ ${build_kernel_module_flag} -eq 1 ]; then
    product_path=${product_path} clean_build=${clean_build} \
        make -C ./ -f ${product_path}/build/Makefile ${parallel_option} ${build_qcacld} </dev/null || exit
fi

if [ ${build_android_flag} -eq 1 ]; then
    # source envsetup.sh before building Android rootfs, the time spent on building uboot/kernel
    # before this does not count in the final result
    source build/envsetup.sh
    make ${parallel_option} ${build_bootimage} ${build_vendorbootimage} ${build_dtboimage} ${build_vendorimage}
fi
