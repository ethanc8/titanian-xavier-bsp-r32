#!/bin/bash

#
# Copyright (c) 2020-2022, NVIDIA CORPORATION.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of NVIDIA CORPORATION nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Set minimum cpu freq.
if [ -e "/proc/device-tree/compatible" ]; then
	machine="$(tr -d '\0' < /proc/device-tree/compatible)"
	if [[ "${machine}" =~ "jetson-nano" ]]; then
		machine="jetson-nano"
	elif [[ "${machine}" =~ "e3900" ]]; then
		machine="e3900"
	elif [[ "${machine}" =~ "jetson-xavier-industrial" ]]; then
		machine="jetson-xavier-industrial"
	elif [[ "${machine}" =~ "jetson-xavier" ]]; then
		machine="jetson-xavier"
	elif [[ "${machine}" =~ "jetson-cv" ]]; then
		machine="jetson_tx1"
	elif [[ "${machine}" =~ "storm" ]]; then
		machine="storm"
	elif [[ "${machine}" =~ "quill" ]]; then
		machine="quill"
	elif [[ "${machine}" =~ "lightning" ]]; then
		machine="lightning"
	elif [[ "${machine}" =~ "p3636-0002" ]]; then
		machine="p3636-0002"
	elif [[ "${machine}" =~ "p3636" ]]; then
		machine="p3636"
	elif [[ "${machine}" =~ "p2972-0006" ]]; then
		machine="p2972-0006"
	elif [[ "${machine}" =~ "p3668" ]]; then
		if [[ "${machine}" =~ "nvidia,p3668-emul" ]]; then
			machine="p3668-emul"
		else
			machine="p3668"
		fi
	else
		machine="`cat /proc/device-tree/model`"
	fi

	CHIP="$(tr -d '\0' < /proc/device-tree/compatible)"
	if [[ ${CHIP} =~ "tegra186" ]]; then
		SOCFAMILY="tegra186"
	elif [[ ${CHIP} =~ "tegra210" ]]; then
		SOCFAMILY="tegra210"
	elif [[ ${CHIP} =~ "tegra194" ]]; then
		SOCFAMILY="tegra194"
	fi
fi

# create /etc/nvpmodel.conf symlink
if [ ! -e "/etc/nvpmodel.conf" ]; then
	conf_file=""
	if [ "${SOCFAMILY}" = "tegra186" ]; then
		if [ "${machine}" = "storm" ]; then
			use_case_model="`cat /proc/device-tree/use_case_model`"
			if [ "${use_case_model}" = "ucm1" ]; then
				conf_file="/etc/nvpmodel/nvpmodel_t186_storm_ucm1.conf"
			elif [ "${use_case_model}" = "ucm2" ]; then
				conf_file="/etc/nvpmodel/nvpmodel_t186_storm_ucm2.conf"
			fi
		elif [ "${machine}" = "p3636" ] ||
			[ "${machine}" = "p3636-0002" ]; then
			conf_file="/etc/nvpmodel/nvpmodel_t186_p3636.conf"
		else
			conf_file="/etc/nvpmodel/nvpmodel_t186.conf"
		fi
	elif [ "${SOCFAMILY}" = "tegra194" ]; then
		if [ "${machine}" = "e3900" ]; then
			if [ -d "/sys/devices/gpu.0" ] &&
				[ -d "/sys/devices/17000000.gv11b" ]; then
				conf_file="/etc/nvpmodel/nvpmodel_t194_e3900_iGPU.conf"
			else
				conf_file="/etc/nvpmodel/nvpmodel_t194_e3900_dGPU.conf"
			fi
		elif [ "${machine}" = "p2972-0006" ]; then
			conf_file="/etc/nvpmodel/nvpmodel_t194_8gb.conf"
		elif [ "${machine}" = "p3668" ]; then
			conf_file="/etc/nvpmodel/nvpmodel_t194_p3668.conf"
		elif [ "${machine}" = "p3668-emul" ]; then
			conf_file="/etc/nvpmodel/nvpmodel_t194_p3668_emul.conf"
		elif [ "${machine}" = "jetson-xavier-industrial" ]; then
			conf_file="/etc/nvpmodel/nvpmodel_t194_agxi.conf"
		else
			conf_file="/etc/nvpmodel/nvpmodel_t194.conf"
		fi
	elif [ "${SOCFAMILY}" = "tegra210" ]; then
		if [ "${machine}" = "jetson-nano" ]; then
			conf_file="/etc/nvpmodel/nvpmodel_t210_jetson-nano.conf"
		else
			conf_file="/etc/nvpmodel/nvpmodel_t210.conf"
		fi
	fi

	if [ "${conf_file}" != "" ]; then
		if [ -e "${conf_file}" ]; then
			ln -sf "${conf_file}" /etc/nvpmodel.conf
		else
			echo "${SCRIPT_NAME} - WARNING: file ${conf_file} not found!"
		fi
	fi
fi

if [ ! -e /etc/nv/nvfirstboot ]; then
	exit 0
fi

function wait_debconf_resource() {
	# Wait for the process to finish which has aquired this lock
	while fuser "/var/cache/debconf/config.dat" > "/dev/null" 2>&1; do sleep 1; done;
	while fuser "/var/cache/debconf/templates.dat" > "/dev/null" 2>&1; do sleep 1; done;
}

ARCH=`/usr/bin/dpkg --print-architecture`
if [ "${ARCH}" = "arm64" ]; then
	echo "/usr/lib/aarch64-linux-gnu/tegra" > \
		/etc/ld.so.conf.d/nvidia-tegra.conf
	echo "/usr/lib/aarch64-linux-gnu/tegra-egl" > \
		/usr/lib/aarch64-linux-gnu/tegra-egl/ld.so.conf
	echo "/usr/lib/aarch64-linux-gnu/tegra" > \
		/usr/lib/aarch64-linux-gnu/tegra/ld.so.conf
	update-alternatives \
		--install /etc/ld.so.conf.d/aarch64-linux-gnu_EGL.conf \
		aarch64-linux-gnu_egl_conf \
		/usr/lib/aarch64-linux-gnu/tegra-egl/ld.so.conf 1000
	update-alternatives \
		--install /etc/ld.so.conf.d/aarch64-linux-gnu_GL.conf \
		aarch64-linux-gnu_gl_conf \
		/usr/lib/aarch64-linux-gnu/tegra/ld.so.conf 1000
fi

ldconfig

# Read total memory size in megabyte
TOTAL_MEM=$(free --mega | awk '/^Mem:/{print $2}')
if [ $? -eq 0 ]; then
	TOTAL_MEM=$(echo "scale=1;${TOTAL_MEM}/1000" | bc)
	TOTAL_MEM=$(echo "${TOTAL_MEM}" | awk '{print int($1+0.5)}')

	# If RAM size is less than 4 GB, set default display manager as LightDM
	if [ -e "/lib/systemd/system/lightdm.service" ] &&
		[ "${TOTAL_MEM}" -lt 4 ]; then
		DEFAULT_DM=$(cat "/etc/X11/default-display-manager")
		if [ "${DEFAULT_DM}" != "/usr/sbin/lightdm" ]; then
			echo "/usr/sbin/lightdm" > "/etc/X11/default-display-manager"
			wait_debconf_resource
			DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure lightdm
			echo set shared/default-x-display-manager lightdm | debconf-communicate
		fi
	fi
else
	echo "ERROR: Cannot get total memory size."
fi

# Allow anybody to run X
if [ -f "/etc/X11/Xwrapper.config" ]; then
	sed -i 's/allowed_users.*/allowed_users=anybody/' "/etc/X11/Xwrapper.config"
fi

groupadd -rf debug # Add debug group - http://nvbugs/2823941

# WAR (to be fixed in http://nvbugs/200640832): udev and this script will have synchronization
# problem in the first run, manually chown until the bug is fixed.

if [ -e /dev/nvhost-ctxsw-gpu ];then
    chown root:debug /dev/nvhost-ctxsw-gpu
fi
if [ -e /dev/nvhost-dbg-gpu ];then
    chown root:debug /dev/nvhost-dbg-gpu
fi
if [ -e /dev/nvhost-prof-gpu ];then
    chown root:debug /dev/nvhost-prof-gpu
fi
if [ -e /dev/nvhost-sched-gpu ];then
    chown root:root /dev/nvhost-sched-gpu
fi
