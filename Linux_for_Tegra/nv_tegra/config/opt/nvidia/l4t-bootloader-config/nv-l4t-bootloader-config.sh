#!/bin/bash
# Copyright (c) 2019-2023, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

# This script runs on target to check if need to update QSPI partitions for Nano
# If the running system version match the bootloader debian package,
# then check the VER in QSPI, if the VER is less then running system version,
# install the package to update QSPI.

BOOT_CTRL_CONF="/etc/nv_boot_control.conf"
T210REF_UPDATER="/usr/sbin/l4t_payload_updater_t210"
T186REF_UPDATER="/usr/sbin/nv_bootloader_payload_updater"
BL_PACKAGE_NAME="nvidia-l4t-bootloader"
XUSB_PACKAGE_NAME="nvidia-l4t-xusb-firmware"
T186REF_NVBOOTCTRL="/usr/sbin/nvbootctrl"
APT_SOURCE_LIST="/etc/apt/sources.list.d/nvidia-l4t-apt-source.list"

orig_name=""
unify_name=""
# When create image, user may flash device with symlink board
# config name or orignal/legacy name, so the nv_boot_control.conf
# may have different board name informaton.
# Unify it to "jetson-*"

# Make sure to put the unify_name in the first line in the table.
jetson_nano_devkit_emmc=(
	"unify_name=jetson-nano-devkit-emmc"
	"orig_name=p3449-0000+p3448-0002"
	"orig_name=jetson-nano-emmc"
)

jetson_nano_devkit=(
	"unify_name=jetson-nano-devkit"
	# This canonical name was existed before 32.5
	"orig_name=p3449-0000+p3448-0000-qspi-sd"
	# The "p3449-0000+jetson-nano-qspi-qspi-sd" is an invalid name,
	# but it would be generated in r32.4.3.
	# The case is that fresh flashing device with
	# "p3449-0000+p3448-0000-qspi-sd" and the old script will change
	# it to "p3449-0000+jetson-nano-qspi-qspi-sd".
	"orig_name=p3449-0000+jetson-nano-qspi-qspi-sd"
	"orig_name=jetson-nano-qspi-sd"
)


jetson_nano_qspi=(
	"unify_name=jetson-nano-qspi"
	"orig_name=p3449-0000+p3448-0000-qspi"
	# The "p3449-0000+jetson-nano-qspi-qspi" is an invalid name,
	# but it would be generated in r32.4.3.
	# The case is that fresh flashing device with
	# "p3449-0000+p3448-0000-qspi" and the old script will change
	# it to "p3449-0000+jetson-nano-qspi-qspi".
	"orig_name=p3449-0000+jetson-nano-qspi-qspi"
	"orig_name=p3450"
)

jetson_nano_2gb_devkit=(
	"unify_name=jetson-nano-2gb-devkit"
	"orig_name=p3542"
	"orig_name=p3542-0000+p3448-0003-qspi-sd"
)

jetson_tx1_devkit=(
	"unify_name=jetson-tx1-devkit"
	"orig_name=p2597-0000+p2180-1000"
	"orig_name=p2371"
	"orig_name=jetson-tx1"
)

jetson_tx2_devkit=(
	"unify_name=jetson-tx2-devkit"
	"orig_name=p2597-0000+p3310-1000"
	"orig_name=jetson-tx2"
)

jetson_tx2_devkit_tx2i=(
	"unify_name=jetson-tx2-devkit-tx2i"
	"orig_name=p2597-0000+p3489-0000-ucm1"
	"orig_name=jetson-tx2i"
)

jetson_tx2_devkit_4gb=(
	"unify_name=jetson-tx2-devkit-4gb"
	"orig_name=p2597-0000+p3489-0888"
	"orig_name=jetson-tx2-4GB"
)

jetson_tx2_as_4GB=(
	"unify_name=jetson-tx2-as-4GB"
	"orig_name=p2597-0000+p3310-1000-as-p3489-0888"
)

jetson_xavier_nx_devkit_tx2_nx=(
	"unify_name=jetson-xavier-nx-devkit-tx2-nx"
	"orig_name=p3509-0000+p3636-0001"
)

jetson_xavier_maxn=(
	"unify_name=jetson-xavier-maxn"
	"orig_name=p2972-0000-devkit-maxn"
)

jetson_xavier_slvs_ec=(
	"unify_name=jetson-xavier-slvs-ec"
	"orig_name=p2972-0000-devkit-slvs-ec"
)

jetson_agx_xavier_devkit=(
	"unify_name=jetson-agx-xavier-devkit"
	"orig_name=p2822-0000+p2888-0004"
	"orig_name=p2822-0000+p2888-0001"
	"orig_name=p2972"
	"orig_name=jetson-xavier"
)

jetson_xavier_nx_devkit=(
	"unify_name=jetson-xavier-nx-devkit"
	"orig_name=p3509-0000+p3668-0000-qspi-sd"
	"orig_name=p3449-0000+p3668-0000-qspi-sd"
)

jetson_xavier_nx_devkit_emmc=(
	"unify_name=jetson-xavier-nx-devkit-emmc"
	"orig_name=p3509-0000+p3668-0001-qspi-emmc"
	"orig_name=p3449-0000+p3668-0001-qspi-emmc"
)

jetson_xavier_nx_devkit_qspi=(
	"unify_name=jetson-xavier-nx-devkit-qspi"
	"orig_name=p3509-0000+p3668-0000-qspi"
)

clara_agx_xavier_devkit=(
	"unify_name=clara-agx-xavier-devkit"
	"orig_name=e3900-0000+p2888-0004-b00"
)

jetson_agx_xavier_industrial=(
	"unify_name=jetson-agx-xavier-industrial"
	"orig_name=p2822-0000+p2888-0008"
)

jetson_agx_xavier_industrial_mxn=(
	"unify_name=jetson-agx-xavier-industrial-mxn"
	"orig_name=p2822-0000+p2888-0008-mxn"
)

t21x_board_conf=(
	"board_conf=jetson_nano_devkit_emmc"
	"board_conf=jetson_nano_devkit"
	"board_conf=jetson_nano_qspi"
	"board_conf=jetson_nano_2gb_devkit"
	"board_conf=jetson_tx1_devkit"
)

t18x_board_conf=(
	"board_conf=jetson_tx2_devkit"
	"board_conf=jetson_tx2_devkit_tx2i"
	"board_conf=jetson_tx2_devkit_4gb"
	"board_conf=jetson_tx2_as_4GB"
	"board_conf=jetson_xavier_nx_devkit_tx2_nx"
)

t19x_board_conf=(
	"board_conf=jetson_xavier_maxn"
	"board_conf=jetson_xavier_slvs_ec"
	"board_conf=jetson_agx_xavier_devkit"
	"board_conf=jetson_xavier_nx_devkit"
	"board_conf=jetson_xavier_nx_devkit_emmc"
	"board_conf=jetson_xavier_nx_devkit_qspi"
	"board_conf=clara_agx_xavier_devkit"
	"board_conf=jetson_agx_xavier_industrial"
	"board_conf=jetson_agx_xavier_industrial_mxn"
)

comp_board=""
compatible_board_name() {
	local boards=("${!1}")
	local board_name="$2"

	orig_name=""
	unify_name=""

	for i in "${!boards[@]}"; do
		eval "${boards[$i]}"

		if [[ "${i}" == "0" ]]; then
			# get the unify_name in first loop
			# check if the board_name is the unify_name
			if [[ "${board_name}" == "${unify_name}" ]]; then
				comp_board="${unify_name}"
				break;
			fi

			continue
		fi

		# get the orig_name in next loops.
		# change the orig_name to unify_name for comp_board
		if [[ "${board_name}" == "${orig_name}" ]]; then
			comp_board="${unify_name}"
			break
		fi
	done
}

generate_compatible_board_name () {
	local confs=("${!1}")
	local orig_board_name=${2}

	for i in "${!confs[@]}"; do
		eval "${confs[$i]}"
		compatible_board_name "${board_conf}"[@] "${orig_board_name}"
		if [[ "${comp_board}" != "" ]]; then
			break;
		fi
	done

	# cannot get compatible board name, use original board name.
	if [[ "${comp_board}" == "" ]]; then
		echo "Warning: Cannot get compatible board name."
		comp_board="${orig_board_name}"
	fi
}

board_id=""
board_ver=""
board_sku=""
board_rev=""
board_fuselevel=""
chip_rev=""
compatible_spec=""

update_jetson_nano_spec () {
    if [[ "${board_ver}" -lt "100" ]]; then
        board_ver=000
    elif [[ "${board_ver}" -lt "200" ]]; then
        board_ver=100
    elif [[ "${board_ver}" -lt "300" ]]; then
        board_ver=200
    else
        board_ver=300
    fi
    board_rev=""
    chip_rev=""
}

update_jetson_tx2_spec () {
    if [[ "${board_ver}" == "B01" || "${board_ver}" > "B01" ]]; then
        board_ver="B01"
    fi
    board_sku=""
    board_rev=""
    chip_rev=""
}

update_jetson_tx2i_spec () {
    if [[ "${board_ver}" -lt "300" ]]; then
        board_ver=200
    else
        board_ver=300
    fi
    board_sku=""
    board_rev=""
    chip_rev=""
}

update_jetson_xavier_spec () {
    if [[ "${board_sku}" == "0004" ]]; then
        board_rev=""
        board_ver="400"
        return 0
    fi

    if [[ "${board_ver}" == "400" ]]; then
        if [[ "${board_rev}" == "D.0" || "${board_rev}" < "D.0" ]]; then
            board_rev="D.0"
        else
            board_rev="E.0"
        fi
        board_sku="0001"
        return 0
    fi

    if [[ "${board_ver}" == "600" ]]; then
        if [[ "${board_sku}" == "0008" ]]; then
            board_rev=""
        fi
    fi
}

update_jetson_xavier_nx_spec () {
    if [[ "${board_ver}" != "301" ]]; then
        board_ver="100"
    fi
    board_sku=""
    board_rev=""
    chip_rev=""
}

# Parse all fields in spec, and return all of them:
# ${BOARDID}-${FAB}-${BOARDSKU}-${BOARDREV}-${fuselevel}-${chiprev}-${target_board}-${target_rootdev}
parse_spec_info() {
	local _spec="${1}"
	local _board_id="${2}"
	local _board_ver="${3}"
	local _board_sku="${4}"
	local _board_rev="${5}"
	local _board_fuselevel="${6}"
	local _chip_rev="${7}"
	local _target_board="${8}"
	local _target_rootdev="${9}"

	local _id
	_id=$( echo "${_spec}" | awk -F"-" '{print $1}' )
	local _ver
	_ver=$( echo "${_spec}" | awk -F"-" '{print $2}' )
	local _sku
	_sku=$( echo "${_spec}" | awk -F"-" '{print $3}' )
	local _rev
	_rev=$( echo "${_spec}" | awk -F"-" '{print $4}' )
	local _fuselevel
	_fuselevel=$( echo "${_spec}" | awk -F"-" '{print $5}' )
	local _cp_rev
	_cp_rev=$( echo "${_spec}" | awk -F"-" '{print $6}' )

	local tmp_spec
	tmp_spec="${_id}-${_ver}-${_sku}-${_rev}-${_fuselevel}-${_cp_rev}"
	local boot_info
	boot_info=${_spec//"${tmp_spec}-"/}
	local count
	count=$( echo "${boot_info}" | awk '{print split($0,a,"-");}' );
	local _rootdev
	_rootdev=$( echo "${boot_info}" | awk '{split($0,a,"-"); print a['${count}']}' );

	# Return all fields of spec
	eval "${_board_id}=${_id}"
	eval "${_board_ver}=${_ver}"
	eval "${_board_sku}=${_sku}"
	eval "${_board_rev}=${_rev}"
	eval "${_board_fuselevel}=${_fuselevel}"
	eval "${_chip_rev}=${_cp_rev}"
	eval "${_target_board}=${boot_info//"-${_rootdev}"/}"
	eval "${_target_rootdev}=${_rootdev}"
}

generate_compatible_spec_info () {
	local spec_str=${1}
	local target_board
	local target_rootdev

	parse_spec_info "${spec_str}" "board_id" "board_ver" "board_sku" "board_rev" \
			"board_fuselevel" "chip_rev" "target_board" "target_rootdev"

	case "${board_id}" in
		2180)
			# Jetson-TX1
			board_ver=""
			board_sku=""
			board_rev=""
			chip_rev=""
		;;
		3448)
			# Jetson-Nano
			update_jetson_nano_spec
		;;
		3310)
			# Jetson-TX2, Jetson-TX2i
			update_jetson_tx2_spec
		;;
		3489)
			# Jetson-TX2i
			update_jetson_tx2i_spec
		;;
		3636)
			# Jetson-Xavier-NX-TX2-NX
			board_ver=""
			board_rev=""
			chip_rev=""
		;;
		2888)
			# Jetson-Xavier
			update_jetson_xavier_spec
		;;
		3668)
			# Jetson-Xavier-NX
			update_jetson_xavier_nx_spec
		;;
		*)
			echo "ERROR. Unsupported board ID: ${board_id}."
			echo "Cannot install bootloader package. Exiting..."
			exit 1
	esac

	case "${chipid}" in
		0x21)
			generate_compatible_board_name t21x_board_conf[@] "${target_board}"
			;;
		0x18)
			generate_compatible_board_name t18x_board_conf[@] "${target_board}"
			;;
		0x19)
			generate_compatible_board_name t19x_board_conf[@] "${target_board}"
			;;
		*)
			echo "ERROR. Unrecognized chip ID: ${chipid}."
			echo "Cannot install bootloader package. Exiting..."
			exit 1
	esac

	compatible_spec="${board_id}-${board_ver}-${board_sku}-${board_rev}-${board_fuselevel}-${chip_rev}-${comp_board}-"
	echo "${compatible_spec}"
}

sys_rel=""
sys_maj_ver=""
sys_min_ver=""

read_sys_ver() {
	# 1. get installed bootloader package's version
	# sample: ii  nvidia-l4t-bootloader  32.2.0-20190514154120  arm64  NVIDIA Bootloader Package
	# installed_deb_ver=32.2.0-20190514154120
	installed_deb_ver="$(dpkg -l | grep "${BL_PACKAGE_NAME}" | awk '/'${BL_PACKAGE_NAME}'/ {print $3}')"
	if [ "${installed_deb_ver}" == "" ]; then
		exit 0
	fi

	# 2. get main deb_version
	deb_version="$(echo "${installed_deb_ver}" | cut -d "-" -f 1)"

	# 3. use deb_version as sys_version
	# sample: sys_rel=32, sys_maj_ver=2, sys_min_ver=0
	sys_rel="$(echo "${deb_version}" | cut -d "." -f 1)"
	sys_maj_ver="$(echo "${deb_version}" | cut -d "." -f 2)"
	sys_min_ver="$(echo "${deb_version}" | cut -d "." -f 3)"
}

ver_info=""
qspi_rel=""
qspi_maj_ver=""
qspi_min_ver=""

# read t210ref VER partition to get QSPI version
read_t210ref_qspi_ver_info() {
	ver_info="$(${T210REF_UPDATER} -v)"
}

# read t186ref VER partition to get QSPI version
read_t186ref_qspi_ver_info() {
	ver_info="$(${T186REF_UPDATER} --print-ver)"
}

# parse version info
parse_qspi_ver_info() {
	local ver_line=""
	local info=""
	local rel_number=""
	local version=""

	# version sample:
	# Version:
	# NV3
	# # R32 , REVISION: 4.0
	# BOARDID=xxxx BOARDSKU=yyy FAB=zzz

	ver_line=$(echo "${ver_info}" | sed -n '/Version:/'=)
	((ver_line++))
	info=$(echo "${ver_info}" | sed -n "${ver_line}p")

	if [[ "${info}" == "NV1" ]]; then
		qspi_rel=31
		qspi_maj_ver=0
		qspi_min_ver=0
	elif [[ "${info}" == *"NV"* ]]; then
		((ver_line++))
		ver_info=$(echo "${ver_info}" | sed -n "${ver_line}p")

		rel_number="$(echo "${ver_info}" | awk '/#/ {print $2}')"
		qspi_rel="$(echo "${rel_number}" | sed 's/R//')"

		version=$(echo "${ver_info}" | awk '/#/ {print $5}')
		version="$(echo "${version}" | sed 's/,//')"

		qspi_maj_ver="$(echo "${version}" | cut -d "." -f 1)"
		qspi_min_ver="$(echo "${version}" | cut -d "." -f 2)"
	else
		echo "Error. Cannot get valid version information"
		echo "Exiting ..."
		exit 1
	fi
}

# check qspi version, if need update it.
# return:  0: needs update; 1: doesn't need update.
update_qspi_check () {
	parse_qspi_ver_info

	if (( "${sys_rel}" > "${qspi_rel}" )); then
		# sys_rel > qspi_rel
		# need to update QSPI
		return 0
	elif (( "${sys_rel}" == "${qspi_rel}" )); then
		if (( "${sys_maj_ver}" > "${qspi_maj_ver}" )); then
			# sys_rel == qspi_rel
			# sys_maj_ver > qspi_maj_ver
			# need to update QSPI
			return 0
		elif (( "${sys_maj_ver}" == "${qspi_maj_ver}" )); then
			if (( "${sys_min_ver}" > "${qspi_min_ver}" )); then
				# sys_rel == qspi_rel
				# sys_maj_ver == qspi_maj_ver
				# sys_min_ver > qspi_min_ver
				# need to update QSPI
				return 0
			else
				return 1
			fi
		else
			return 1
		fi
	else
		return 1
	fi
}

auto_update_qspi () {
	# read system version
	read_sys_ver

	# read qspi version
	if [[ ("${comp_board}" == "jetson-nano-devkit" ||
		"${comp_board}" == "jetson-nano-2gb-devkit") &&
		-x "${T210REF_UPDATER}" ]]; then
		read_t210ref_qspi_ver_info
	elif [[ ("${comp_board}" == "jetson-xavier-nx-devkit") &&
		-x "${T186REF_UPDATER}" ]]; then
		read_t186ref_qspi_ver_info
	else
		exit 0
	fi

	if update_qspi_check; then
		if ! dpkg-reconfigure "${BL_PACKAGE_NAME}"; then
			echo "ERROR. Procedure for bootloader dpkg reconfig FAILED."
			echo "Exiting..."
			exit 1
		fi

		if ! dpkg-reconfigure "${XUSB_PACKAGE_NAME}"; then
			echo "ERROR. Procedure for xusb dpkg reconfig FAILED."
			echo "Exiting..."
			exit 1
		fi
	fi
}

# Read board_id, board_sku, board_ver and board_rev from EEPROM
read_eeprom_board_info () {
	local i2c=0
	local pn
	local val
	local ret

	# Get i2c controller and slave address based on chip id,
	# slave address is fixed to 0x50
	case ${chipid} in
		0x21)
			i2c=2
			;;
		0x18)
			i2c=7
			;;
		0x19)
			i2c=0
			;;
		*)
			echo "ERROR. Unrecognized chip ID: ${chipid}."
			exit 1
			;;
	esac

	# Read product part number from EEPROM address 25 to 41.
	# if read EEPROM failed return 1
	for reg in {25..41}
	do
		val=$(i2cget -f -y "${i2c}" 0x50 "${reg}")
		ret=$?
		if [ ${ret} -ne 0 ]; then
			echo "WARNING. Read i2c-${i2c} slave addr: 0x50 failed."
			return 1
		fi
		pn+=$(echo "${val}" | xxd -r)
	done

	# Parse board info
	board_id=${pn:0:4}
	board_sku=${pn:5:4}
	board_ver=${pn:10:3}
	board_rev=${pn:14:3}
	return 0
}

# Generate board_spec by combining info from EEPROM and TNSPEC
# Return generated board_spec
generate_board_spec() {
	local tnspec="${1}"
	local board_spec_gen="${2}"

	local tnspec_id
	local tnspec_ver
	local tnspec_sku
	local tnspec_rev
	local tnspec_fuselevel
	local tnspec_chip_rev
	local tnspec_board
	local tnspec_rootdev

	# Get spec info from TNSPEC
	parse_spec_info "${tnspec}" "tnspec_id" "tnspec_ver" "tnspec_sku" "tnspec_rev" \
					"tnspec_fuselevel" "tnspec_chip_rev" "tnspec_board" "tnspec_rootdev"

	# Generate board_spec where
	# board_id,board_ver,board_sku and board_rev are read from EEPROM
	# board_fuselevel,chip_rev,target_board and target_rootdev are from BOOT_CTRL_CONF
	eval "${board_spec_gen}=${board_id}-${board_ver}-${board_sku}-${board_rev}-${tnspec_fuselevel}-${tnspec_chip_rev}-${tnspec_board}-${tnspec_rootdev}"
}

# Update /dev/disk/by-partlabel if error symbol link found
update_partlabel() {
	local dependecy_table
	local mount_dev_name
	local partlabel_path="/dev/disk/by-partlabel"

	mount_dev_name=$( df / | tail -n 1 | awk '{print $1}' )

	# Find the boot disk device name according to mount_dev_name
	dependecy_table=$( lsblk -sl "${mount_dev_name}" -o NAME,TYPE )

	echo "${dependecy_table}" | while read -r line
	do
		name=$( echo "${line}" | awk '{print $1}' )
		type=$( echo "${line}" | awk '{print $2}' )

		if [ "${type}" == "disk" ]; then
			boot_dev=${name}

			# Check partlabel link, regenerate if error link found
			label_dev_table=$( lsblk -o PARTLABEL,NAME -lp | grep "${boot_dev}" )

			echo "${label_dev_table}" | while read -r line;
			do
				partlabel_name=$( echo "${line}" | awk '{print $1}' )
				partlabel_dev=$( echo "${line}" | awk '{print $2}' )
				if [ "${partlabel_name}" == "" ] || [ "${partlabel_dev}" == "" ]; then
					continue
				fi

				current_device=$( readlink -f ${partlabel_path}/"${partlabel_name}" )
				if [ "${current_device}" == "" ] || [ "${partlabel_dev}" == "${current_device}" ]; then
					continue
				fi

				ln -snf "${partlabel_dev}" ${partlabel_path}/"${partlabel_name}"
				echo "Restore link: ${partlabel_name} to ${partlabel_dev}"
			done
			break;
		fi
	done
}

# When unified bootloader and rootfs A/B is enabled, the Debian update should be disabled.
block_deb_update() {
	local cmnt_str="## Unified bootloader and rootfs A/B is enabled, disable Debian update."

	if [ ! -x "${T186REF_NVBOOTCTRL}" ] || [ ! -f "${APT_SOURCE_LIST}" ]; then
		return
	fi

	if grep -q "${cmnt_str}" "${APT_SOURCE_LIST}"; then
		return
	fi

	if "${T186REF_NVBOOTCTRL}" is-unified-enabled > /dev/null 2>&1; then
		# Comment out entries in source list to disable Debian update.
		sed -i "s/^/# &/g" "${APT_SOURCE_LIST}"
		sed -i "1i ${cmnt_str}" "${APT_SOURCE_LIST}"
	fi
}

generate_compatible_spec_only=""

update_partlabel

while [ $# -gt 0 ]; do
	case "${1}" in
		-c|--comp-spec-only) generate_compatible_spec_only="1" ;;
		-f|--boot-control-file) BOOT_CTRL_CONF="${2}"; shift ;;
		*) echo "Terminating... wrong option: $*" >&2 ; exit 1 ;;
	esac
	shift
done

if [ ! -r "${BOOT_CTRL_CONF}" ]; then
	echo "Error. Cannot open ${BOOT_CTRL_CONF} for reading."
	echo "Cannot install package. Exiting..."
	exit 1
fi

chipid=$( awk '/TEGRA_CHIPID/ {print $2}' "${BOOT_CTRL_CONF}" )
tnspec=$( awk '/TNSPEC/ {print $2}' "${BOOT_CTRL_CONF}" )
compatible_spec_current=$( awk '/COMPATIBLE_SPEC/ {print $2}' "${BOOT_CTRL_CONF}" )
compatible_spec=""
board_spec=""

# if read EEPROM board info successfully, generate board_spec and replace TNSPEC
# if read failed, use tnspec in /etc/nv_boot_control.conf as board_spec
if read_eeprom_board_info; then
	# Generate board_spec by combining info from EEPROM and TNSPEC
	generate_board_spec "${tnspec}" "board_spec"

	# Replace TNSPEC with board_spec
	if [ "${tnspec}" != "${board_spec}" ]; then
		if [ "${tnspec}" != "" ]; then
			sed -i '/TNSPEC*/d' "${BOOT_CTRL_CONF}"
		fi
		sed -i "1i TNSPEC ${board_spec}" "${BOOT_CTRL_CONF}"
	fi
else
	board_spec=${tnspec}
fi

generate_compatible_spec_info "${board_spec}"

if [ "${compatible_spec_current}" != "${compatible_spec}" ]; then
	if [ "${compatible_spec_current}" != "" ]; then
		sed -i '/COMPATIBLE_SPEC*/d' "${BOOT_CTRL_CONF}"
	fi
	sed -i "1 a COMPATIBLE_SPEC ${compatible_spec}" "${BOOT_CTRL_CONF}"
fi

if [ "${generate_compatible_spec_only}" = "1" ]; then
	exit 0;
fi

block_deb_update

case "${chipid}" in
	0x21 | 0x19)
		auto_update_qspi
		;;
esac
