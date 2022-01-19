#!/bin/sh

if [ -z "$product" ]; then product=yukawa; fi

help() {
cat << EOF

Usage: $0 <options>

options:
  -h                displays this help message
  -d <directory>    the directory of images (default: \$OUT)
  -D                disables verity verification
  -p <product_name> product/target being flashed (default: $product)
  -u                do NOT erase userdata during the flashing process

EOF
}

# Parse parameters
skip_userdata=0
disable_verity=""
while [ $# -gt 0 ]; do
	case $1 in
		-h) help; exit ;;
		-d) OUT=$2; shift;;
		-D) disable_verity="--disable-verity";;
		-p) product=$2; shift;;
		-u) skip_userdata=1 ;;
		*)  echo "$1 is not a known option";
			help; exit;;
	esac
	shift
done

if [ -z "$OUT" ]; then OUT=out/target/product/$product; fi
if ! [ -d $OUT ]; then
   echo "Missing $OUT";
   exit 1;
fi

# check that partitions properly exist
if fastboot getvar partition-size:dtbo 2>&1 | grep -q FAIL ; then
	echo Formatting the device...
	fastboot oem format
fi

fastboot flash dtbo $OUT/dtbo.img
if ! [ $? -eq 0 ] ; then echo "Failed to flash dtbo.img"; exit 1; fi
fastboot flash boot $OUT/boot.img
if ! [ $? -eq 0 ] ; then echo "Failed to flash boot.img"; exit 1; fi
fastboot flash recovery $OUT/recovery.img
if ! [ $? -eq 0 ] ; then echo "Failed to flash recovery.img"; exit 1; fi
fastboot flash super $OUT/super.img
if ! [ $? -eq 0 ] ; then echo "Failed to flash super.img"; exit 1; fi
fastboot flash vbmeta $OUT/vbmeta.img $disable_verity
if ! [ $? -eq 0 ] ; then echo "Failed to flash vbmeta.img"; exit 1; fi
fastboot flash cache $OUT/cache.img
if ! [ $? -eq 0 ] ; then echo "Failed to flash cache.img"; exit 1; fi
if ! [ ${skip_userdata} -eq 1 ] ; then
	fastboot format:ext4 userdata
	fastboot format:ext4 metadata
	if ! [ $? -eq 0 ] ; then echo "Failed to erase userdata"; exit 1; fi
fi
fastboot reboot
