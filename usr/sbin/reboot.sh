#!/bin/sh
# File:				update.sh	
# Provides:         
# Description:      update zImage&rootfs under dir1/dir2/...
# Author:			xc

#
# main:
#
echo "stop system service before reboot....."
killall -15 syslogd
killall -15 klogd
killall -15 tcpsvd

# send signal to stop watchdog
#killall -12 daemon 
#sleep 3
 kill apps
killall -15 daemon
killall -15 discovery
killall -15 anyka_ipc
killall -15 net_manage.sh
killall -15 wifi_run.sh
/usr/sbin/wifi_manage.sh stop
/usr/sbin/wifi_manage.sh uninstall

echo "############  finished, reboot now #############"
sleep 6
reboot -f

exit 0
