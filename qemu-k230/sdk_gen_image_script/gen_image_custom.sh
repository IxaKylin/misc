#!/bin/bash
set -e;

K230_SDK_ROOT="$(pwd)/.."
UBOOT_BUILD_DIR="${K230_SDK_ROOT}/output/k230_canmv_defconfig/little/uboot"
BUILD_DIR="${K230_SDK_ROOT}/output/k230_canmv_defconfig"
LINUX_BUILD_DIR="${K230_SDK_ROOT}/output/k230_canmv_defconfig/little/linux"
env_dir="${K230_SDK_ROOT}/board/common/env"
GENIMAGE_CFG_DIR="${K230_SDK_ROOT}/board/common/gen_image_cfg"
GENIMAGE_CFG_SD="${GENIMAGE_CFG_DIR}/genimage-sdcard.cfg"
GENIMAGE_CFG_SD_AES="${GENIMAGE_CFG_DIR}/genimage-sdcard_aes.cfg"
GENIMAGE_CFG_SD_SM="${GENIMAGE_CFG_DIR}/genimage-sdcard_sm.cfg"
#GENIMAGE_CFG_SD_DDR4="${GENIMAGE_CFG_DIR}/genimage-sdcard_ddr4.cfg"
GENIMAGE_CFG_SPI_NOR="${GENIMAGE_CFG_DIR}/genimage-spinor.cfg"
GENIMAGE_CFG_SPI_NAND="${GENIMAGE_CFG_DIR}/genimage-spinand.cfg"
GENIMAGE_CFG_SD_REMOTE="${GENIMAGE_CFG_DIR}/genimage-sdcard_remote.cfg"

cfg_data_file_path="${GENIMAGE_CFG_DIR}/data"
quick_boot_cfg_data_file="${GENIMAGE_CFG_DIR}/data/quick_boot.bin"
face_database_data_file="${GENIMAGE_CFG_DIR}/data/face_data.bin"
sensor_cfg_data_file="${GENIMAGE_CFG_DIR}/data/sensor_cfg.bin"
ai_mode_data_file="${BUILD_DIR}/images/big-core/ai_mode.bin" #"${GENIMAGE_CFG_DIR}/data/ai_mode.bin"
speckle_data_file="${GENIMAGE_CFG_DIR}/data/speckle.bin"
rtapp_data_file="${BUILD_DIR}/images/big-core/fastboot_app.elf"


#生成可用uboot引导的linux版本文件
gen_linux_bin ()
{
	local mkimage="${UBOOT_BUILD_DIR}/tools/mkimage"
	local LINUX_SRC_PATH="src/little/linux"
	local LINUX_DTS_PATH="src/little/linux/arch/riscv/boot/dts/kendryte/${CONFIG_LINUX_DTB}.dts"

	cd  "${BUILD_DIR}/images/little-core/" ;
	#cpp -nostdinc -I ${K230_SDK_ROOT}/${LINUX_SRC_PATH}/include -I ${K230_SDK_ROOT}/${LINUX_SRC_PATH}/arch  -undef -x assembler-with-cpp ${K230_SDK_ROOT}/${LINUX_DTS_PATH}  hw/k230.dts.txt

	ROOTFS_BASE=`cat hw/k230.dts.txt | grep initrd-start | awk -F " " '{print $4}' | awk -F ">" '{print $1}'`
	ROOTFS_SIZE=`ls -lt rootfs-final.cpio.gz | awk '{print $5}'`
	((ROOTFS_END= $ROOTFS_BASE + $ROOTFS_SIZE))
	ROOTFS_END=`printf "0x%x" $ROOTFS_END`
	sed -i "s/linux,initrd-end = <0x0 .*/linux,initrd-end = <0x0 $ROOTFS_END>;/g" hw/k230.dts.txt

	${LINUX_BUILD_DIR}/scripts/dtc/dtc -I dts -q -O dtb ${K230_SDK_ROOT}/src/k230_canmv.dts  >k230.dtb;
	
	# 不压缩fw_payload.bin，直接使用原文件
	# k230_gzip fw_payload.bin;  # 注释掉压缩步骤
	
	echo a>rd;
	
	# 修改mkimage参数：去掉gzip压缩(-C none)，使用原始文件(fw_payload.bin而不是fw_payload.bin.gz)
	${mkimage} -A riscv -O linux -T multi -C none -a ${CONFIG_MEM_LINUX_SYS_BASE} -e ${CONFIG_MEM_LINUX_SYS_BASE} -n linux -d fw_payload.bin:rd:k230.dtb  ulinux.bin;

	add_firmHead  ulinux.bin
	mv fn_ulinux.bin  linux_system.bin
	[ -f fa_ulinux.bin ] && mv fa_ulinux.bin  linux_system_aes.bin
	[ -f fs_ulinux.bin ] && mv fs_ulinux.bin  linux_system_sm.bin
	rm -rf rd;
}

gen_linux_bin










