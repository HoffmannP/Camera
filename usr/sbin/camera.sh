#! /bin/sh
### BEGIN INIT INFO
# File:				camera.sh	
# Provides:         
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description: install or remove camera drivers
# Author:			
# Email: 			
# Date:				2015-9-28
### END INIT INFO

MODE=$1

usage()
{
	echo "Usage: $0 setup | remove"
}


camera_remove()
{
	rmmod /usr/modules/akcamera.ko
	find /usr/modules -maxdepth 1 -type f -name "sensor_*.ko" -exec rmmod {} \;
	find /etc/jffs2 -maxdepth 1 -type f -name "sensor_*.ko" -exec rmmod {} \;
}

camera_setup()
{
	find /etc/jffs2 -maxdepth 1 -type f -name "sensor_*.ko" -exec insmod {} \;
	find /usr/modules -maxdepth 1 -type f -name "sensor_*.ko" -exec insmod {} \;
#	insmod /usr/modules/sensor_h42.ko
	insmod /usr/modules/akcamera.ko
}

case "$MODE" in
	setup)
		camera_setup
		;;
	remove)
		camera_remove
		;;
	*)
		usage
		;;
esac
exit 0

