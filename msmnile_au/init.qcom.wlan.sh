#!/vendor/bin/sh
# Copyright (c) 2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

# Function to enable single wifi
function enable_single_wifi() {
	setprop ro.vendor.wlan.dual_wlan_enaled false
	if [ ! -f /vendor/lib/modules/qca_cld3_wlan.ko ]; then
		if lspci -kn |grep cnss_pci|grep ":1100";then
			setprop ro.vendor.wlan.chip qca6290
		elif lspci -kn |grep cnss_pci|grep ":003e";then
			setprop ro.vendor.wlan.chip qca6174
			setprop ro.vendor.wlan.aware false
			setprop ro.vendor.wlan.11ax false
			setprop ro.vendor.wlan.sta_plus_sta false
		elif lspci -kn |grep cnss_pci|grep ":1101";then
			setprop ro.vendor.wlan.chip qca6390
		elif lspci -kn |grep cnss_pci|grep ":1102";then
			setprop ro.vendor.wlan.chip qcn7605
			setprop ro.vendor.wlan.apf false
			setprop ro.vendor.wlan.11ax false
			setprop ro.vendor.wlan.aware false
		elif lspci -kn |grep cnss_pci|grep ":1103";then
			setprop ro.vendor.wlan.chip qca6490
		fi
	else
		setprop ro.vendor.wlan.chip wlan
	fi

	setprop vendor.wlan.driver.status "ok"
}

# Function to enable dual wifi
function enable_dual_wifi() {
	# automatically get PCI RC numeber for primary and secondary WLAN
	primary_pci_rc=`xxd /sys/devices/platform/soc/soc:qcom,cnss-qca-converged0/of_node/qcom,wlan-rc-num`
	secondary_pci_rc=`xxd /sys/devices/platform/soc/soc:qcom,cnss-qca-converged2/of_node/qcom,wlan-rc-num`
	primary_array=(${primary_pci_rc//:/})
	primary_pci_rc=${primary_array[2]}
	secondary_array=(${secondary_pci_rc//:/})
	secondary_pci_rc=${secondary_array[2]}
	#Get PCI device ID
	primary_dev=`cat /sys/bus/pci/devices/$primary_pci_rc:01:00.0/device`
	secondary_dev=`cat /sys/bus/pci/devices/$secondary_pci_rc:01:00.0/device`

	if [ ! "$primary_dev" ] || [ ! "$secondary_dev" ]; then
		echo "No Dual WLAN device detected."
		return
	fi

	echo "primary_dev=$primary_dev secondary_dev=$secondary_dev"

	setprop ro.vendor.wlan.dual_wlan_enabled true

	case "$primary_dev" in
		"0x1101")
		setprop ro.vendor.wlan.chip qca6390
		;;
		"0x1102")
		setprop ro.vendor.wlan.chip qcn7605
		setprop ro.vendor.wlan.apf false
		setprop ro.vendor.wlan.11ax false
		setprop ro.vendor.wlan.aware false
		;;
		"0x1103")
		setprop ro.vendor.wlan.chip qca6490
		;;
		*)
		echo "Not supported device id $primary_dev"
		;;
	esac

	case "$secondary_dev" in
		"0x1101")
		setprop ro.vendor.wlan.chip2 qca6390
		;;
		"0x1103")
		setprop ro.vendor.wlan.chip2 qca6490
		;;
		*)
		echo "Not supported device id $secondary_dev"
		;;
	esac

	setprop vendor.wlan.driver.status "ok"
}


echo 1 > /sys/kernel/cnss/fs_ready

dev_cnt=`lspci -kn | grep -c cnss_pci`
case "$dev_cnt" in
	"1")
	# Single WiFi
	enable_single_wifi
        ;;
        "2")
        # Dual WiFi
	enable_dual_wifi
	;;
	*)
	echo "NO WLAN Chip is enabled"
	;;
esac
