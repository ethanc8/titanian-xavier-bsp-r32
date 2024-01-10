#!/bin/bash

# Copyright (c) 2020-2022, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# Usage: ./l4t_flash_from_kernel.sh
# This script flashes the target from the Network File Systems on the target or
# from the host using the images inside the flash package generated by
# l4t_create_flash_image_in_nfs

set -e


function cleanup
{
	for f in "${LOG_DIR}"/*
	do
		if ! [ -f "${f}" ]; then
			break
		fi
		print_log "$(cat "${f}")"
	done
	for i in "${error_message[@]}"
	do
		print_log "$i"
	done
	if [ "${qspi_only}" = "0" ] && [ "${host_mode}" = "0" ] && [ "${external_only}" = "0" ]; then
		# Only do this if we are flashing the internal emmc / sd from NFS flash
		if [ -f "/sys/block/${mmcblk0boot0}/force_ro" ]; then
			echo 1 > "/sys/block/${mmcblk0boot0}/force_ro"
		fi
		if [ -f "/sys/block/${mmcblk0boot1}/force_ro" ]; then
			echo 1 > "/sys/block/${mmcblk0boot1}/force_ro"
		fi
	fi
}

run_commmand_on_target()
{
	echo "Run command: ${2} on root@fe80::1%${1}"
	sshpass -p root ssh -q -oServerAliveInterval=15 -oServerAliveCountMax=3 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -6 "root@fe80::1%${1}" "$2";
}

function print_at_end
{
	local temp_file
	temp_file=$(mktemp "${LOG_DIR}/XXX")
	echo -e "${@}" > "${temp_file}"
}

function usage
{
	echo -e "
Usage: $0 [--external-only | --host-mode | --qspi-only | --no-reboot]
Where,
	--external-only             Skip flashing the internal storage
	--qspi-only                 Flashing the qspi storage only
	--host-mode                 Flashing options used when flashing using initrd
	--no-reboot                 Don't reboot after finishing
This script flashes the target using the kernel on NFS of the target or the host
using the images inside the flash package generated by l4t_create_flash_image_in_nfs

	"; echo;
	exit 1
}

function print_log
{
	if [ -z "${*}" ]; then
		return
	fi
	local end=$SECONDS
	local duration=$(( end - START ))
	echo -e "[ ${duration}]: ${SCRIPT_NAME}: ${*}"
}

function get_disk_name
{
	local ext_dev="${1}"
	local disk=
	# ${ext_dev} could be specified as a partition; therefore, removing the
	# number if external storage device is scsi, otherwise, remove the trailing
	# "p[some number]" here
	if [[ "${ext_dev}" = sd* ]]; then
		disk=${ext_dev%%[0-9]*}
	else
		disk="${ext_dev%p*}"
	fi
	echo "${disk}"
}

function is_internal_device()
{
	if [ "${1}" = "${SDCARD_STORAGE_DEVICE}" ] ||
	   [ "${1}" = "${SDMMC_USER_DEVICE}" ]; then
			return 0;
	fi
	return 1;
}

function is_gpt_supported_device()
{
	if [ "${1}" = "${SDCARD_STORAGE_DEVICE}" ] ||
	   [ "${1}" = "${SDMMC_USER_DEVICE}" ] ||
	   [ "${1}" =  "${EXTERNAL_STORAGE_DEVICE}" ]; then
			return 0;
	fi
	return 1;
}

function is_not_qspi()
{
	if [ "${1}" = "${SDMMC_BOOT_DEVICE}" ] \
		|| [ "${1}" = "${SDMMC_USER_DEVICE}" ] \
		|| [ "${1}" = "${SDCARD_STORAGE_DEVICE}" ] \
		|| [ "${1}" = "${EXTERNAL_STORAGE_DEVICE}" ]; then
		return 0;
	fi
	return 1;
}

function erase_spi
{
	flash_erase "${1}" 0 0
}

function is_sparse_image
{
	[ "$(xxd -p -s 0f -l 4 "${1}")" = "${SPARSE_FILE_MAGIC}" ]
}

function is_tar_archive
{
	file "${file_image}" | grep -q 'tar archive'
}

function is_spi_flash
{
	if [ ! -f "${FLASH_INDEX_FILE}" ];then
		print_at_end "Error: ${FLASH_INDEX_FILE} is not found"
		exit 1
	fi

	readarray index_array < "${FLASH_INDEX_FILE}"
	echo "Flash index file is ${FLASH_INDEX_FILE}"

	lines_num=${#index_array[@]}
	echo "Number of lines is $lines_num"

	max_index=$((lines_num - 1))
	echo "max_index=${max_index}"

	for i in $(seq 0 ${max_index})
	do
		local item="${index_array[$i]}"

		# Try to search for a device that has type SPI flash(3)
		local device_type
		device_type=$(echo "${item}" | cut -d, -f 2 | \
			sed 's/^ //g' - | cut -d: -f 1)

		if [ "${device_type}" = "${SPI_DEVICE}" ];then
			return 0
		fi
	done
	return 1
}

function write_to_spi
{

	if [ ! -f "${FLASH_INDEX_FILE}" ];then
		print_at_end "Error: ${FLASH_INDEX_FILE} is not found"
		exit 1
	fi

	readarray index_array < "${FLASH_INDEX_FILE}"
	echo "Flash index file is ${FLASH_INDEX_FILE}"

	lines_num=${#index_array[@]}
	echo "Number of lines is $lines_num"

	max_index=$((lines_num - 1))
	echo "max_index=${max_index}"

	for i in $(seq 0 ${max_index})
	do
		local item="${index_array[$i]}"
		# break if device type is other than SPI flash(3) as only generating
		# image for SPI flash(3)
		local device_type
		device_type=$(echo "${item}" | cut -d, -f 2 | \
			sed 's/^ //g' - | cut -d: -f 1)

		if [ "${device_type}" != "${SPI_DEVICE}" ];then
			echo "Reach the end of the SPI device"
			break
		fi

		# fill the partition image into the SPI image
		if ! write_to_spi_partition "${item}" /dev/mtd0; then
			exit 1
		fi
	done

	return 0
}

# When flashing in host mode, all of the USB gadget MSD appears as /dev/sd* on the host
# But on the target it actually can be backed by /dev/mmcblk0, /dev/mmcblk0boot0
# Therefore, we need to create a mapping to keep track of which USB gadget MSD
# corresponds to which storage device on the target
function fill_device_map
{
	if [[ "${host_mode}" = "0" ]]; then
		return 0
	fi
	device_map["${mmcblk0}"]="mmcblk0"
	device_map["${mmcblk0boot0}"]="mmcblk0boot0"
	device_map["${mmcblk0boot1}"]="mmcblk0boot1"
	if [ -n "${external_device}" ]; then
		device_map["${external_device}"]="${external_device_on_target}"
	fi
}

# Use the mapping the get the actual backing device
function get_dev_name_on_target
{
	local disk_name=
	local device_name="$1"
	local part_num
	if [[ "${host_mode}" = "0" ]]; then
		echo "${device_name}"
	else
		disk_name=$(get_disk_name "$(basename "${device_name}")")
		part_num=${device_name##${disk_name}}
		get_partition "${device_map["${disk_name}"]}" "${part_num}"
	fi
}

function write_to_spi_partition
{
	local item="${1}"
	local spi_image="${2}"
	local part_name
	local file_name
	local start_offset
	local file_size
	local part_size
	local sha1_chksum
	part_name=$(echo "${item}" | cut -d, -f 2 | sed 's/^ //g' - | cut -d: -f 3)
	file_name=$(echo "${item}" | cut -d, -f 5 | sed 's/^ //g' -)
	part_size=$(echo "${item}" | cut -d, -f 4 | sed 's/^ //g' -)
	start_offset=$(echo "${item}" | cut -d, -f 3 | sed 's/^ //g' -)
	file_size=$(echo "${item}" | cut -d, -f 6 | sed 's/^ //g' -)
	sha1_chksum=$(echo "${item}" | cut -d, -f 8 | sed 's/^ //g' -)

	if [ -n "${target_partname}" ] && [ "${target_partname}" != "${part_name}" ]; then
		echo "Skip writing ${part_name}"
		return
	fi

	if [ -z "${file_name}" ];then
		print_log "Warning: skip writing ${part_name} partition as no image is \
specified"
		return 0
	fi

	echo "Writing ${file_name} (parittion: ${part_name}) into ${spi_image}"

	local part_image_file="${COMMON_IMAGES_DIR}/${INTERNAL}/${file_name}"
	if [ ! -f "${part_image_file}" ];then
		print_log "Error: image for partition ${part_name} is not found at \
${part_image_file}"
		return 1
	fi

	sha1_verify "${part_image_file}" "${sha1_chksum}"

	if [ -n "${target_partname}" ] && [ "${target_partname}" = "${part_name}" ]; then
		echo "Erasing ${part_name} for ${file_size} bytes at ${start_offset}"
		if ! mtd_debug erase "${spi_image}" "${start_offset}" "${part_size}"; then
			print_log "Erasing ${part_name} for ${file_size} bytes at ${start_offset} failed"
			return 1
		fi
	fi

	echo "Writing ${part_image_file} (${file_size} bytes) into "\
		"${spi_image}:${start_offset}"
	if ! mtd_debug write "${spi_image}" "${start_offset}" "${file_size}" \
		"${part_image_file}"; then
		print_log "Writing ${part_image_file} (${file_size} bytes) into \
${spi_image}:${start_offset} failed"
		return 1
	fi
	# Write BCT redundancy
	# BCT image should be written in multiple places: (Block 0, Slot 0), (Block
	# 0, Slot 1) and (Block 1, Slot 0). In this case, block size is 32KB and the
	# slot size is 4KB, so the BCT image should be written at the place where
	# offset is 4096 and 32768
	if [ "${part_name}" = "BCT" ]; then
		# Block 0, Slot 1
		start_offset=4096
		echo "Writing ${part_image_file} (${file_size} bytes) into " \
			"${spi_image}:${start_offset}"
		if ! mtd_debug write "${spi_image}" "${start_offset}" "${file_size}" \
		"${part_image_file}"; then
			print_log "Writing ${part_image_file} (${file_size} bytes) into \
${spi_image}:${start_offset} failed"
			return 1
		fi

		# Block 1, Slot 0
		start_offset=32768
		echo "Writing ${part_image_file} (${file_size} bytes) into " \
		"${spi_image}:${start_offset}"
		if ! mtd_debug write "${spi_image}" "${start_offset}" "${file_size}" \
			"${part_image_file}"; then
			print_log "Writing ${part_image_file} (${file_size} bytes) into \
${spi_image}:${start_offset} failed"
			return 1
		fi
	fi
}

# Verify sha1 checksum for image
# @file_image: file for caculating check sum
# @sha1chksum: sha1 check sum
function sha1_verify
{
	local file_image="${1}"
	local sha1_chksum="${2}"

	if [ -z "${sha1_chksum}" ];then
		print_log "Passed-in sha1 checksum is NULL"
		return 1
	fi

	if [ ! -f "${file_image}" ];then
		print_log "$file_image is not found !!!"
		return 1
	fi

	local sha1_chksum_gen
	sha1_chksum_gen=$(sha1sum "${file_image}" | cut -d\  -f 1)
	if [ "${sha1_chksum_gen}" = "${sha1_chksum}" ];then
		echo "Sha1 checksum matched for ${file_image}"
		return 0
	else
		print_log "Sha1 checksum does not match (${sha1_chksum_gen} \
!= ${sha1_chksum}) for ${file_image}"
		return 1
	fi
}

# This function read and write partitions using the infile and outfile name
# ,the infile offset and theout file offset, and the total size given.
function read_write_file
{
	local infile="${1}"
	local outfile="${2}"
	local inoffset="${3}"
	local outoffset="${4}"
	local size="${5}"

	if [ ! -e "${infile}" ];then
		print_log "Input file ${infile} is not found"
		return 1
	fi

	if [ "${size}" -eq 0 ];then
		print_log "The size of bytes to be read is ${size}"
		return 1
	fi

	local inoffset_align_K=$((inoffset % K_BYTES))
	local outoffset_align_K=$((outoffset % K_BYTES))
	if [ "${inoffset_align_K}" -ne 0 ] || [ "${outoffset_align_K}" -ne 0 ];then
		echo "Offset is not aligned to K Bytes, no optimization is applied"
		echo "dd if=${infile} of=${outfile} bs=1 skip=${inoffset} "\
			"seek=${outoffset} count=${size}"
		dd if="${infile}" of="${outfile}" bs=1 skip="${inoffset}" \
			seek="${outoffset}" count="${size}"
		return 0
	fi

	local block=$((size / K_BYTES))
	local remainder=$((size % K_BYTES))
	local inoffset_blk=$((inoffset / K_BYTES))
	local outoffset_blk=$((outoffset / K_BYTES))

	echo "${size} bytes from ${infile} to ${outfile}: 1KB block=${block} \
remainder=${remainder}"

	if [ ${block} -gt 0 ];then
		echo "dd if=${infile} of=${outfile} bs=1K skip=${inoffset_blk} "\
			"seek=${outoffset_blk} count=${block}"
		dd if="${infile}" of="${outfile}" bs=1K skip="${inoffset_blk}" \
			seek="${outoffset_blk}" count="${block}" conv=notrunc
		sync
	fi
	if [ ${remainder} -gt 0 ];then
		local block_size=$((block * K_BYTES))
		local outoffset_rem=$((outoffset + block_size))
		local inoffset_rem=$((inoffset + block_size))
		echo "dd if=${infile} of=${outfile} bs=1 skip=${inoffset_rem} "\
			"seek=${outoffset_rem} count=${remainder}"
		dd if="${infile}" of="${outfile}" bs=1 skip="${inoffset_rem}" \
			seek="${outoffset_rem}" count="${remainder}" conv=notrunc
		sync
	fi
	return 0
}

function flash_partition
{
	local file_name="${1}"
	local part_name="${2}"
	local start_offset="${3}"
	local file_size="${4}"
	local attributes="${5}"
	local sha1_chksum="${6}"
	local device="${7}"
	local location="${8}"
	local tmp_file=/tmp/tmp.img
	local file_image="${COMMON_IMAGES_DIR}/${location}/${file_name}"
	local sha1_chksum_gen=
	local res=0
	local tmp_size=0

	if [ ! -f "${file_image}" ];then
		print_at_end "Cannot find file ${file_image}"
		exit 1
	fi

	if is_sparse_image "${file_image}"; then
		if [ -n "${device}" ];then
			local device_name
			IFS='-' read -r -a attribute <<< "${attributes}"
			entry_id="${attribute[2]}"
			device_name=$(basename "${device}")
			write_sparse_image "/dev/$(get_partition "${device_name}" "${entry_id}")" "${file_image}"
			return 0
		fi
	fi

	if [ "${VERIFY_WRITE}" -eq 1 ];then
		# skip verifying SMD/SMD_b/kernel-bootctrl/kernel-bootctrl_b
		# paritions as the sha1 cheksum in the index file is generated
		# from the dummy image file other than the exact image file
		if [ "${part_name}" != "SMD" ] \
			&& [ "${part_name}" != "SMD_b" ] \
			&& [ "${part_name}" != "kernel-bootctrl" ] \
			&& [ "${part_name}" != "kernel-bootctrl_b" ];then
			if ! sha1_verify "${file_image}" "${sha1_chksum}"; then
				return 1
			fi
		fi

		# verify whether this partition has been writen
		rm -f "${tmp_file}"
		if [ -n "${device}" ];then
			if ! read_write_file "${device}" "${tmp_file}" \
				"${start_offset}" 0 "${file_size}";then
				print_log "Failed to read ${file_size} bytes from \
${device}:${start_offset} to ${tmp_file}"
				return 1
			fi
		else
			tmp_size=$((SDMMC_BOOT0_SIZE - start_offset))
			dd if="/dev/${mmcblk0boot0}" of="${tmp_file}" skip="${start_offset}" \
				bs=1 count="${tmp_size}"
			tmp_size=$((file_size - tmp_size))
			dd if="/dev/${mmcblk0boot1}" bs=1 count="${tmp_size}" >> "${tmp_file}"
		fi
		sync
		sha1_chksum_gen=$(sha1sum "${tmp_file}" | cut -d\  -f 1)
		if [ "${sha1_chksum_gen}" = "${sha1_chksum}" ];then
			print_log "Partition ${part_name} has been updated, skip writing"
			return 0
		fi
	fi

	# write image
	if [ -n "${device}" ];then
		if ! read_write_file "${file_image}" "${device}" 0 \
			"${start_offset}" "${file_size}";then
			print_log "Failed to write ${file_size} bytes from ${file_image} to \
${device}:${start_offset}"
			return 1
		fi
	else
		tmp_size=$((SDMMC_BOOT0_SIZE - start_offset))
		echo "dd if=${file_image} of=${device} seek=${start_offset} bs=1"\
			" count=${tmp_size} conv=notrunc"
		dd if="${file_image}" of="/dev/${mmcblk0boot0}" seek="${start_offset}" bs=1 \
			count="${tmp_size}" conv=notrunc

		dd if="${file_image}" of="/dev/${mmcblk0boot1}" bs=1 skip="${tmp_size}" \
			conv=notrunc
	fi
	sync

	if [ "${VERIFY_WRITE}" -eq 1 ];then
		rm -f "${tmp_file}"
		# verify writing
		if [ -n "${device}" ];then
			if ! read_write_file "${device}" "${tmp_file}" \
				"${start_offset}" 0 "${file_size}"; then
				print_log "Failed to read ${file_size} bytes from \
${device}:${start_offset} to ${tmp_file}"
				return 1
			fi
		else
			tmp_size=$((SDMMC_BOOT0_SIZE - start_offset))
			echo "dd if=/dev/${mmcblk0boot0} of=${tmp_file} skip=${start_offset} "\
				"bs=1 count=${tmp_size}"
			dd if="/dev/${mmcblk0boot0}" of="${tmp_file}" skip="${start_offset}" \
				bs=1 count="${tmp_size}"
			tmp_size=$((file_size - tmp_size))
			echo "dd if=/dev/${mmcblk0boot1} bs=1 count=${tmp_size} >>${tmp_file}"
			dd if="/dev/${mmcblk0boot1}" bs=1 count="${tmp_size}" >> "${tmp_file}"
		fi

		# For SMD/SMD_B and kernel-bootctrl/kernel-bootctrl_b, the
		# sha1 chksum needs to be re-generated from the exact image file
		if [ "${part_name}" = "SMD" ] \
			|| [ "${part_name}" = "SMD_b" ] \
			|| [ "${part_name}" = "kernel-bootctrl" ] \
			|| [ "${part_name}" = "kernel-bootctrl_b" ];then
			echo "Re-generate sha1sum for the image ${file_image}"
			sha1_chksum=$(sha1sum "${file_image}" | cut -d\  -f 1)
		fi

		sha1_verify "${tmp_file}" "${sha1_chksum}"
	fi
	return "${?}"
}

flash_sdmmc_boot_partition()
{
	local start_offset=$3
	local file_size=$4
	local sdmmc_device=
	local args=("$@")
	local end_offset=

	start_offset=$((start_offset))
	file_size=$((file_size))
	end_offset=$((start_offset + file_size))
	if [ -z "${SDMMC_BOOT0_SIZE}" ]; then
		print_at_end "mmcblk0bootx is not available"
		exit 1
	fi
	if [ ${start_offset} -ge "${SDMMC_BOOT0_SIZE}" ]; then
		sdmmc_device=/dev/${mmcblk0boot1}
		start_offset=$((start_offset - SDMMC_BOOT0_SIZE))
		args[2]=${start_offset}
	elif [ ${end_offset} -le "${SDMMC_BOOT0_SIZE}" ]; then
		sdmmc_device=/dev/${mmcblk0boot0}
	else
		# partition cross over mmcblk0boot0 and mmcblk0boot1 and
		# it should be handled in special way
		sdmmc_device=""
	fi

	flash_partition "${args[@]}" "${sdmmc_device}" "${INTERNAL}"
	return $?
}

function flash_sdmmc_user_partition
{
	local sdmmc_device=/dev/${mmcblk0}

	flash_partition "$@" "${sdmmc_device}" "${INTERNAL}"
	return "${?}"
}

function flash_extdev_partition
{
	# external_device is going to be generated by
	# l4t_create_images_for_kernel_flash.sh
	local disk=

	disk="/dev/$(get_disk_name "${external_device}")"
	flash_partition "$@" "${disk}" "${EXTERNAL}"
	return "${?}"
}

function get_partition
{
	local device="${1}"
	local count="${2}"
	local partition
	local disk
	if [[ "${device}" = sd* ]]; then
		disk=${device%%[0-9]*}
		partition="${disk}${count}"
	else
		disk="${device%p*}"
		partition="${disk}p${count}"
	fi
	if [ -z "${count}" ] || [ "${count}" -eq 0 ]; then
		echo "${disk}"
		return
	fi
	echo "${partition}"
}

# function to write a sparse image to a dev node
# first argument is the destination dev node, second argument is the file to write
function write_sparse_image
{
	# sparse file
	if [ "${host_mode}" = "0" ]; then
		echo "blkdiscard ${1}"
		if ! blkdiscard "${1}"; then
			echo "Cannot erase using blkdiscard. Write zero to partition ${1}"
			echo "dd if=/dev/zero of=${1}"
			dd if=/dev/zero of="${1}" status=progress oflag=direct
		fi
	else
		local dev_name
		dev_name="/dev/$(get_dev_name_on_target "$(basename "${1}")")"
		run_commmand_on_target "${net}" \
		"if ! blkdiscard ${dev_name}; then
		echo Cannot erase before writing sparse image. Write zero to partition ${dev_name};
		dd if=/dev/zero of=${dev_name} status=progress oflag=direct; fi";
	fi

	local simg2img="nvsimg2img"

	if ! command -v "${simg2img}" &> /dev/null; then
		if [ "${host_mode}" = "1" ]; then
			print_at_end "ERROR: cannot find ${simg2img}. You might have set up your flashing env wrong"
			exit 1
		fi;

		# Running from NFS
		simg2img="simg2img"
		if ! command -v "${simg2img}" &> /dev/null; then
			print_at_end "ERROR simg2img not found! To install - please run: \"sudo apt-get install \
	simg2img\" or \"sudo apt-get install android-tools-fsutils\""
			exit 1
		fi;
	fi;
	echo "${simg2img} ${2} ${1}"
	"${simg2img}" "${2}" "${1}"
	chkerr "${simg2img} ${2} ${1} failed"
	sync
	return
}

function chkerr ()
{
	# As it checks the exit code of previous statement before this function,
	# we have to use $?
	if [ "$?" -ne 0 ]; then
		if [ "$1" != "" ]; then
			print_at_end "$1";
		else
			print_at_end "failed.";
		fi;
		exit 1;
	fi;
	if [ "$1" = "" ]; then
		echo "done.";
	fi;
}

function wait_for_block_dev()
{
	local partition="${1}"
	local count=0
	while ! blockdev --getpbsz "/dev/${partition}" > /dev/null 2>&1
	do
		printf "..."
		count=$((count + 1))
		if [ "${count}" -ge "${maxcount}" ]; then
			echo "Timeout"
			exit 1
		fi
		sleep 1
	done
}

function do_write_storage
{
	local item="${1}"
	local count="${2}"
	local device_type
	local part_name
	local file_name
	local start_offset
	local file_size
	local attributes
	local sha1_chksum
	local partition
	local start_sector
	local disk
	device_type=$(echo "${item}" | cut -d, -f 2 | sed 's/^ //g' - | cut -d: -f 1)
	part_name=$(echo "${item}" | cut -d, -f 2 | sed 's/^ //g' - | cut -d: -f 3)
	file_name=$(echo "${item}" | cut -d, -f 5 | sed 's/^ //g' -)
	start_offset=$(echo "${item}" | cut -d, -f 3 | sed 's/^ //g' -)
	file_size=$(echo "${item}" | cut -d, -f 6 | sed 's/^ //g' -)
	attributes=$(echo "${item}" | cut -d, -f 7 | sed 's/^ //g' -)
	sha1_chksum=$(echo "${item}" | cut -d, -f 8 | sed 's/^ //g' -)
	local res=0

	if [ -z "${file_name}" ];then
		print_log "Warning: skip writing ${part_name} partition as no image \
is specified"
		return 0
	fi

	if [ -n "${target_partname}" ] && [ "${target_partname}" != "${part_name}" ]; then
		echo "Skip writing ${part_name}"
		return
	fi

	echo "Writing ${part_name} partition with ${file_name}"
	# if this device is emmc's boot partitions
	if [ "${device_type}" = "${SDMMC_BOOT_DEVICE}" ];then
		flash_sdmmc_boot_partition "${file_name}" "${part_name}" \
			"${start_offset}" "${file_size}" "${attributes}" "${sha1_chksum}"
		res="${?}"
		if [ "${res}" -ne 0 ];then
			return "${res}"
		fi

	 # if this device is emmc's user partitions
	elif is_internal_device "${device_type}" ;then
		if [ -n "${count}" ] && [ "${count}" -ne 0 ]; then
			partition=$(get_partition "${mmcblk0}" "${count}")
			echo "Get size of partition through connection."
			# For host mode, the connection might get reset. Therefore, if it fails,
			# need to do this to wait until the conenction is reestablished
			wait_for_block_dev "${partition}"
			pblksz=$(blockdev --getpbsz "/dev/${partition}")
			chkerr "Get size of partition failed"
			start_sector=$(cat "/sys/block/${mmcblk0}/${partition}/start")
			chkerr "Get start sector of partition failed"
			if [ $((start_sector * pblksz)) -ne 0 ]; then
				start_offset=$((start_sector * pblksz))
			fi
		fi
		flash_sdmmc_user_partition "${file_name}" "${part_name}" \
"${start_offset}" "${file_size}" "${attributes}" "${sha1_chksum}"
		res="${?}"
	elif [ "${device_type}" = "${EXTERNAL_STORAGE_DEVICE}" ]; then
		if [ -n "${count}" ]  && [ "${count}" -ne 0 ]; then
			partition=$(get_partition "${external_device}" "${count}")
			echo "Get size of partition through connection."
			# For host mode, the connection might get reset. Therefore, if it fails,
			# need to do this to wait until the conenction is reestablished
			wait_for_block_dev "${partition}"
			pblksz=$(blockdev --getpbsz "/dev/${partition}")
			chkerr "Get size of partition failed"
			disk="$(get_disk_name "${external_device}")"
			start_sector=$(cat "/sys/block/${disk}/${partition}/start")
			chkerr "Get start sector of partition failed"
			if [ $((start_sector * pblksz)) -ne 0 ]; then
				start_offset=$((start_sector * pblksz))
			fi
		fi
		flash_extdev_partition "${file_name}" "${part_name}" \
			"${start_offset}" "${file_size}" "${attributes}" "${sha1_chksum}"
		res="${?}"
	else
		print_log "Error: invalid device type ${device_type}"
		return 1
	fi
	echo "Writing ${part_name} partition done"
	return "${res}"
}

function do_write_APP
{
	local item="${1}"
	local external="${2}"
	local count="${3}"
	local file_image
	local sha1_file
	local sha1_chksum=
	local APP_partition=
	local device_type=
	local disk=
	local part_name
	local tool=mkfs.ext4
	local location=""
	local name=
	local ext=

	device_type=$(echo "$item" | cut -d, -f 2 | sed 's/^ //g' - | cut -d: -f 1)

	part_name=$(echo "${item}" | cut -d, -f 2 | sed 's/^ //g' - | cut -d: -f 3)

	if [ -n "${target_partname}" ] && [ "${target_partname}" != "${part_name}" ]; then
		echo "Skip writing ${part_name}"
		return
	fi


	if [ "${device_type}" = "${EXTERNAL_STORAGE_DEVICE}" ]; then
		if [ -n "${external_device}" ]; then
			APP_partition=/dev/$(get_partition "${external_device}" "${count}")
			location="${EXTERNAL}"
			ext="_ext"
		else
			print_log "Error: external device is not specified"
			return 1
		fi
	elif is_internal_device "${device_type}"; then
		APP_partition="/dev/$(get_partition "${mmcblk0}" "${count}")"
		location="${INTERNAL}"
	else
		print_log "Error: unsupported device type ${device_type}"
		return 1
	fi


	name=${part_name}${ext}
	file_image="${COMMON_IMAGES_DIR}/${location}/${!name}"

	sha1_file="${file_image}.sha1sum"


	if [ ! -f "${file_image}" ];then
		print_log "APP image ${file_image} is not found !!!"
		return 1
	fi

	if [ ! -f "${sha1_file}" ];then
		print_log "Sha1 checksum file ${sha1_file} is not found !!!"
		return 1
	fi

	if [ ! -e "${APP_partition}" ];then
		print_log "APP paritiion ${APP_partition} is not found !!!"
		return 1
	fi

	# verify sha1 checksum
	# sha1_chksum=$(cat "${sha1_file}")
	# if ! sha1_verify "${file_image}" "${sha1_chksum}";then
	# 	return 1
	# fi

	# Using magic to check if this is a sparse file
	if is_sparse_image "${file_image}"; then
		write_sparse_image "${APP_partition}" "${file_image}"
		return 0
	fi

	# Check if this is a tar archive
	if is_tar_archive; then
		# tar file
		# format APP partition and mount it
		echo "Formatting APP partition ${APP_partition} ..."
		"${tool}" -F "${APP_partition}"
		echo "Formatting APP parition done"
		tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

		if ! mount "${APP_partition}" "${tmp_dir}"; then
			print_log "Failed to mount APP partition ${APP_partition}"
			return 1
		fi

		# decompress APP image into APP partition
		echo "Formatting APP partition ${APP_partition} ..."
		echo "tar --xattrs -xpf ${file_image} " "${COMMON_TAR_OPTIONS[@]}" " -C "\
			"${tmp_dir}"
		if ! tar --xattrs -xpf "${file_image}" "${COMMON_TAR_OPTIONS[@]}" \
			-C "${tmp_dir}"; then
			print_log "Failed to decompress APP image into ${APP_partition}"
			# umount APP parition
			umount "${tmp_dir}"
			rm -rf "${tmp_dir}"
			return 1
		fi
		sync

		# umount APP parition
		umount "${tmp_dir}"
		rm -rf "${tmp_dir}"
		return 0
	fi

	# raw image. Simply dd to the destination
	dd if="${file_image}" of="${APP_partition}" status=progress bs=4096 oflag=sync
	sync
}

function create_gpt
{
	local device_type=
	local part_name=
	local start_offset=
	local part_size=
	local res=0
	local GPT_EXIST=false
	local index_file="${1}"
	local external="1"
	local disk=
	local size=
	local pblksz=
	local item


	if [ -z "${index_file}" ]; then
		index_file="${FLASH_INDEX_FILE}"
		external=""
	fi

	echo "Active index file is ${index_file}"
	readarray ACTIVE_INDEX_ARRAY < "${index_file}"


	lines_num=${#ACTIVE_INDEX_ARRAY[@]}
	echo "Number of lines is $lines_num"

	max_index=$((lines_num - 1))
	echo "max_index=${max_index}"

	local entry_id=0
	local shouldExpandLastPart=0
	local expandedPartId=0
	local has_gpt_supported_dev=0


	# The GPT must be the first partition flashed, so this block ensures that
	# the GPT exists and is flashed first.

	for i in $(seq 0 ${max_index})
	do
		item=${ACTIVE_INDEX_ARRAY[$i]}

		part_name=$(echo "$item" | cut -d, -f 2 | \
			sed 's/^ //g' - | cut -d: -f 3)

		device_type=$(echo "$item" | cut -d, -f 2 | \
			sed 's/^ //g' - | cut -d: -f 1)

		start_offset=$(echo "${item}" | cut -d, -f 3 | sed 's/^ //g' -)
		part_size=$(echo "${item}" | cut -d, -f 4 | sed 's/^ //g' -)
		IFS='-' read -r -a attribute <<< "$(echo "${item}" | cut -d, -f 7 | sed 's/^ //g' -)"


		if is_gpt_supported_device "${device_type}"; then
			has_gpt_supported_dev=1
			# device type equals 1 indicates internal user emmc storage
			# device type equals 9 indicates external storage

			disk="/dev/${mmcblk0}"
			if [ "${device_type}" = "${EXTERNAL_STORAGE_DEVICE}" ]; then
				# This is an external storage device so try to find the name of
				# the devnode here.
				disk="/dev/$(get_disk_name "${external_device}")"
			fi

			if [ -z "${attribute[2]}" ]; then
				entry_id="$((entry_id + 1))"
			else
				entry_id="${attribute[2]}"
			fi
			if [ "${part_name}" = "primary_gpt" ]; then
				echo -n "writing item=${item}"
				# This recreates the mbr and clears gpt. In the case where mbr
				# is invalid or does not exist, this will help partx read gpt table
				flock -w 60 /var/lock/nvidiainitrdflash parted -s "${disk}" mklabel gpt
				do_write_storage "${item}" ""
				if ! flock -w 60 /var/lock/nvidiainitrdflash partprobe "${disk}"; then
					 print_at_end "Error: partprobe failed. This indicates that:\n" \
						"-   the xml indicates the gpt is larger than the device storage\n" \
						"-   the xml might be invalid\n" \
						"-   the device might have a problem.\n" \
						"Please make correction."
					exit 1
				fi

				GPT_EXIST=true
				entry_id=0
				continue
			elif [ "${part_name}" = "secondary_gpt" ]; then
				local size=
				size=$(blockdev --getsize64 "${disk}")
				do_write_storage "${item}" ""
				if [ $((start_offset + part_size)) -gt "${size}" ]; then
					print_at_end "Error: the ${disk} size $((start_offset + part_size)) set in \
partition layout xml is greater than the ${disk} actual size ${size}. Please make correction"
					exit 1
				elif [ $((start_offset + part_size)) -lt "${size}" ]; then
					print_at_end "The device size indicated in the partition \
layout xml is smaller than the actual size. This utility will try to fix the GPT."
					set +e
					echo -e "Fix\nFix" | parted ---pretend-input-tty "${disk}" print
					if [ "${shouldExpandLastPart}" = "1" ]; then
						print_log "Expanding last partition to fill the storage device"
						parted -s "${disk}" "resizepart ${expandedPartId} 100%"
					fi
					set -e
				fi
			elif [ "${attribute[0]}" = "expand" ]; then
				shouldExpandLastPart="1"
				expandedPartId="${entry_id}"
			fi

		fi
	done

	# if GPT does not exist exit.
	if [ "${GPT_EXIST}" != true ] && [ "${has_gpt_supported_dev}" -eq 1 ]; then
		print_at_end "The GPT does not exist in the index file"
		exit 1
	fi
}

function write_to_storage
{
	local device_type=
	local part_name=
	local start_offset=
	local part_size=
	local res=0
	local GPT_EXIST=false
	local index_file="${1}"
	local external="1"
	local disk=
	local size=
	local pblksz=
	local item


	if [ -z "${index_file}" ]; then
		index_file="${FLASH_INDEX_FILE}"
		external=""
	fi

	echo "Active index file is ${index_file}"
	readarray ACTIVE_INDEX_ARRAY < "${index_file}"


	lines_num=${#ACTIVE_INDEX_ARRAY[@]}
	echo "Number of lines is $lines_num"

	max_index=$((lines_num - 1))
	echo "max_index=${max_index}"

	local entry_id=0

	for i in $(seq 0 ${max_index})
	do
		item=${ACTIVE_INDEX_ARRAY[$i]}
		part_name=$(echo "${item}" | cut -d, -f 2 | \
			sed 's/^ //g' - | cut -d: -f 3)

		device_type=$(echo "${item}" | cut -d, -f 2 | \
			sed 's/^ //g' - | cut -d: -f 1)

		IFS='-' read -r -a attribute <<< "$(echo "${item}" | cut -d, -f 7 | sed 's/^ //g' -)"

		if is_not_qspi "${device_type}"; then
			echo -n "writing item=${item}"

			if [ "${part_name}" = "primary_gpt" ]; then
				entry_id=0
				if is_gpt_supported_device "${device_type}"; then
					continue
				fi
			elif [ "${part_name}" = "secondary_gpt" ] || [ "${part_name}" = "master_boot_record" ]; then
				# skip as we have already put these in
				if is_gpt_supported_device "${device_type}"; then
					continue
				fi
			fi
			if [ -z "${attribute[2]}" ]; then
				entry_id="$((entry_id + 1))"
			else
				entry_id="${attribute[2]}"
			fi
			# Starting writing partitions
			if [ "${part_name}" = "APP" ] || [ "${part_name}" = "APP_b" ] ; then
				if ! do_write_APP "${item}" "${external}" "${entry_id}"; then
					print_at_end "Failed to write to ${part_name}"
					exit 1
				fi
			else
				if ! do_write_storage "${item}" "${entry_id}"; then
					print_at_end "Failed to write to ${part_name}"
					exit 1
				fi
			fi
		elif [ "${device_type}" = "${SPI_DEVICE}" ]; then
			continue
		fi
	done
}

function flash_qspi
{
	if [ "${host_mode}" = "0" ] && [ "${external_only}" = "0" ] && is_spi_flash; then
		print_log "Starting to flash to qspi"
		if [ -z "${target_partname}" ]; then
			erase_spi /dev/mtd0
		fi
		write_to_spi

		print_log "Successfully flash the qspi"
	fi
}

function create_gpt_emmc
{
	if [ "${qspi_only}" = "0" ] && [ "${external_only}" = "0" ] && [ -f "${FLASH_INDEX_FILE}" ]; then
		print_log "Starting to create gpt for emmc"
		create_gpt
		print_log "Successfully create gpt for emmc"
	fi
}

function create_gpt_extdev
{
	if [ "${qspi_only}" = "0" ] && [ -f "${FLASH_INDEX_FILE_EXT}" ]; then
		print_log "Starting to create gpt for external device"
		create_gpt "${FLASH_INDEX_FILE_EXT}"
		print_log "Successfully create gpt for external device"
	fi
}

function flash_emmc
{
	if [ "${qspi_only}" = "0" ] && [ "${external_only}" = "0" ] && [ -f "${FLASH_INDEX_FILE}" ]; then
		print_log "Starting to flash to emmc"
		write_to_storage
		print_log "Successfully flash the emmc"
	fi
}

function flash_extdev
{
	if [ "${qspi_only}" = "0" ] && [ -f "${FLASH_INDEX_FILE_EXT}" ]; then
		print_log "Starting to flash to external device"
		write_to_storage "${FLASH_INDEX_FILE_EXT}"
		print_log "Successfully flash the external device"
	fi
}


trap cleanup EXIT

should_exit=""
LOG_DIR=$(mktemp -d)
VERIFY_WRITE=0
external_only=0
host_mode=0
qspi_only=0
no_reboot=0
error_message=()

COMMON_TAR_OPTIONS=("--checkpoint=10000" \
	"--warning=no-timestamp" \
	"--numeric-owner")
K_BYTES=1024
COMMON_IMAGES_DIR=$(cd "$(dirname "${0}")" && pwd);
SCRIPT_NAME="l4t_flash_from_kernel"
readonly SDMMC_USER_DEVICE="1"
readonly SDCARD_STORAGE_DEVICE="6"
readonly SDMMC_BOOT_DEVICE="0"
readonly EXTERNAL_STORAGE_DEVICE="9"
readonly SPI_DEVICE="3"
readonly SPARSE_FILE_MAGIC="3aff26ed"
readonly INTERNAL="internal"
readonly EXTERNAL="external"
mmcblk0boot0="${MMCBLKB0:-mmcblk0boot0}"
mmcblk0boot1="${MMCBLKB1:-mmcblk0boot1}"
maxcount=60
mmcblk0="${MMCBLK0:-mmcblk0}"
SDMMC_BOOT0_SIZE=""
if blockdev --getsize64 "/dev/${mmcblk0boot0}"; then
	SDMMC_BOOT0_SIZE=$(blockdev --getsize64 "/dev/${mmcblk0boot0}")
fi
target_partname=""

opstr+="h-:k:"
while getopts "${opstr}" OPTION; do
	case $OPTION in
	h) usage; ;;
	k) target_partname="${OPTARG}"; ;;
	-) case ${OPTARG} in
	   external-only) external_only=1; ;;
	   host-mode) host_mode=1; no_reboot=1 ;;
	   qspi-only) qspi_only=1; ;;
	   no-reboot) no_reboot=1; ;;
	   *) usage ;;
	   esac;;
	*)
	   usage
	   ;;
	esac;
done

START="${SECONDS}"

if [ "${USER}" != "root" ]; then
	echo "${0} requires root privilege";
	exit 1;
fi

if [ "${qspi_only}" = "0" ] && [ "${host_mode}" = "0" ] && [ "${external_only}" = "0" ]; then
	# Only do this if we are flashing the internal emmc / sd from NFS flash
	if [ -f "/sys/block/${mmcblk0boot0}/force_ro" ]; then
		echo 0 > "/sys/block/${mmcblk0boot0}/force_ro"
	fi
	if [ -f "/sys/block/${mmcblk0boot1}/force_ro" ]; then
		echo 0 > "/sys/block/${mmcblk0boot1}/force_ro"
	fi
fi

FLASH_INDEX_FILE="${COMMON_IMAGES_DIR}/${INTERNAL}/flash.idx"
FLASH_INDEX_FILE_EXT="${COMMON_IMAGES_DIR}/${EXTERNAL}/flash.idx"

# Restore the flash configuration
# This file is generated by l4t_create_images_for_kernel_flash.sh
if [ -f "${COMMON_IMAGES_DIR}/${INTERNAL}/flash.cfg" ]; then
	source "${COMMON_IMAGES_DIR}/${INTERNAL}/flash.cfg"
fi
if [ -f "${COMMON_IMAGES_DIR}/${EXTERNAL}/flash.cfg" ]; then
	source "${COMMON_IMAGES_DIR}/${EXTERNAL}/flash.cfg"
fi
external_device="${EXTDEV_ON_HOST:-${external_device}}"
# external device name on the host might be different on target
# For example, on the host USB MSD gadget device might appear as /dev/sda
# but on the target the block device backing the USB MSD gadget device
# is called /dev/nvme0n1
external_device_on_target="${EXTDEV_ON_TARGET:-${external_device}}"
# Network interface to communicate with target
net="${TARGET_IP}"
declare -A device_map
fill_device_map



# The GPT must be the first partition flashed, so this block ensures that
# the GPT exists and is flashed first. Moreover, creating GPT must be done
# sequentially otherwise horrible things will happen
if [ -z "${target_partname}" ]; then
	create_gpt_emmc
	create_gpt_extdev
	if [ "${host_mode}" = "1" ]; then
		run_commmand_on_target "${net}" "partprobe"
	fi
fi

flash_qspi &
qspi=$!
flash_emmc &
emmc=$!
flash_extdev &
extdev=$!

if ! wait "${qspi}"; then
	error_message+=("Error flashing qspi")
	should_exit=1
fi

if ! wait "${emmc}"; then
	error_message+=("Error flashing emmc")
	should_exit=1
fi

if ! wait "${extdev}"; then
	error_message+=("Error flashing external device")
	should_exit=1
fi

wait
if [ -n "${should_exit}" ]; then
	exit 1
fi

if [ -z "${target_partname}" ]; then
	print_log "Flashing success"
else
	print_log "Flashing partition ${target_partname} success"
fi

if [ "${no_reboot}" = "0" ]; then
	print_log "The device is going to reboot in 5 seconds...."
	sleep 5
	reboot now
fi
