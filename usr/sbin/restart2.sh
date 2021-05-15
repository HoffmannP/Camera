#!/bin/sh
# File:				update.sh	
# Provides:         
# Description:      update zImage&rootfs under dir1/dir2/...
# Author:			xc

echo "stop the anyka_ipc thread"
/usr/sbin/service.sh stop
#echo 0 > /sys/user-gpio/wifi_en
sleep 4
echo "start the anyka_ipc thread"
#echo 1 > /sys/user-gpio/wifi_en
/usr/sbin/service.sh start
