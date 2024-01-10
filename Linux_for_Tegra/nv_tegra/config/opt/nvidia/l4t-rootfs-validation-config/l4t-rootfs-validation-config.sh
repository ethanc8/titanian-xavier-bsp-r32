#!/bin/bash

# Copyright (c) 2020-2021, NVIDIA CORPORATION. All rights reserved.
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

# This script runs customer specific rootfs validation function to check
# if the root filesystem boots successfully or not.

echo "Checking if the root filesystem boots successfully"

# If the root filesystem fails to boot, make sure to reboot the device,
# so that the nv_update_engine will not update boot status to successful.


# The user-provied rootfs validation script
# Fixed script location and name.
user_rootfs_validation="/usr/sbin/user_rootfs_validation.sh"

# Return:
#  0: success
#  1: failed
#
rootfs_validation ()
{
	if [ -f "${user_rootfs_validation}" ];then
		if "${user_rootfs_validation}"; then
			# rootfs validate success.
			return 0
		else
			# rootfs validate failed.
			return 1
		fi
	else
		# user rootfs validation script doesn't exist
		return 0
	fi
}

#
# Call rootfs validation function. If failed,
# trigger device reboot
#
if ! rootfs_validation; then
	echo "The root filesystem failed to boot. Will reboot the device."
	reboot
	while true; do sleep 1; done
fi

exit 0
