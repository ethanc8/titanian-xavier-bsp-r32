#!/bin/bash

# Copyright (c) 2021, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

compatible="/proc/device-tree/compatible"

if [ -e "${compatible}" ]; then
	machine="$(tr -d '\0' < ${compatible})"
fi

# set mlx5 critical temperature
if [[ "${machine}" =~ "e3900" ]]; then
	mlx5_critical_temp="/sys/devices/14180000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/0000:02:02.0/0000:09:00.0/mlx5_crit_temp"
	if [ -e "${mlx5_critical_temp}" ]; then
		echo 98000 > "${mlx5_critical_temp}"
		echo 1 > "/sys/devices/thermal-fan-est/update_subdevs_crit_temps"
	fi
fi

# Set NV plugins as default settings if oem-config is auto mode
if [ -e "/etc/nv/nvautoconfig" ]; then
	nvresizefs_script="/usr/lib/nvidia/resizefs/nvresizefs.sh"
	if [ -e "${nvresizefs_script}" ]; then
		check_result="$("${nvresizefs_script}" -c)"
		if [[ "${check_result}" = "true" ]]; then
			"${nvresizefs_script}"
		fi
	fi

	nvswap_script="/usr/lib/nvidia/swap/nvswap.sh"
	if [ -e "${nvswap_script}" ]; then
		check_result="$("${nvswap_script}" -c)"
		if [[ "${check_result}" = "true" ]]; then
			"${nvswap_script}" -s
		fi
	fi

	nvqspi_update_script="/usr/lib/nvidia/qspi-update/nvqspi-update.sh"
	if [ -e ""${nvqspi_update_script} ]; then
		check_result="$("${nvqspi_update_script}" -c)"
		if [[ "${check_result}" = "true" ]]; then
			"${nvqspi_update_script}" -u
		fi
	fi

	rm -rf /etc/nv/nvautoconfig
fi
