#! /bin/sh
### BEGIN INIT INFO
# File:				wifi_manage.sh	
# Provides:         start wifi station and ap
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description:start wifi run at station or softAP
# Author:			
# Email: 			
# Date:				2012-8-8
### END INIT INFO

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin
MODE=$1
cfgfile="/etc/jffs2/anyka_cfg.ini"

usage()
{
	echo "Usage: $0 install | uninstall | start | stop | restart | reset"
}


wifi_remove()
{
	#rm sdio wifi driver
	rmmod 8189es

	#rm usb wifi driver(default)
	#rmmod 8188eu
	#rmmod otg-hs
}

wifi_setup()
{
	#/usr/sbin/led.sh blink 1000 200
	
	#install usb wifi driver(default)
	#sleep 2
	#insmod /usr/modules/otg-hs.ko
	#sleep 2
	#insmod /usr/modules/8188eu.ko

	#install sdio wifi driver
	insmod /usr/modules/8189es.ko
}


wifi_station_start()
{
	echo "start wifi station......"
		
	ssid=`awk 'BEGIN {
	FS="="}/\[wireless\]/{a=1} a==1&&$1~/^ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	mode=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^mode/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	security=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^security/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	password=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^password/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
						
	if [ "$mode" = "Ad-Hoc" ] || [ "`echo $mode|grep -i "hoc"`" != "" ]
	then
		security=adhoc
	elif [ "$security" = "OPEN" ] || [ "$security" = "NONE" ] || [ "$password" = "NONE" ] || [ "`echo $security|grep -i "none"`" != "" ]
	then
		security=open
	elif [ "$security" = "WEP" ] || [ "`echo $security|grep -i "wep"`" != "" ]
	then
		security=wep
	else
		security=wpa
	fi

	echo "security=$security ssid=$ssid password=$password"
	
	wpa_supplicant -B -iwlan0 -Dwext -c /etc/jffs2/wpa_supplicant.conf
			
	/usr/sbin/station_connect.sh $security "$ssid" "$password" &
}


wifi_ap_start()
{
	echo "start wifi soft ap......"
	#read ssid and password
	ssid=`awk 'BEGIN {FS="="}/\[softap\]/{a=1} a==1&&$1~/s_ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	password=`awk 'BEGIN {FS="="}/\[softap\]/{a=1} a==1&&$1~/s_password/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
					
	/usr/sbin/device_save.sh name "$ssid"
	/usr/sbin/device_save.sh password "$password"	
	echo "ssid=$ssid password=$password"
									
	if [ -z $password ]
	then
		/usr/sbin/device_save.sh setwpa 0
	else
		/usr/sbin/device_save.sh setwpa 2
	fi
																				
																				
	hostapd /etc/jffs2/hostapd.conf -B
	test -f /var/run/udhcpd.pid && rm -f /var/run/udhcpd.pid
	test -f /var/run/dhcpd.pid && rm -f /var/run/dhcpd.pid
	ifconfig wlan1 192.168.0.1 #for busybox
	#route add default gw 192.168.0.1 #
	udhcpd /etc/udhcpd.conf #for busybox
	if [  -d "/sys/class/net/eth0" ]
	then
		ifconfig eth0 down
		ifconfig eth0 up
	fi
}

wifi_stop()
{	
	/usr/sbin/wifi_station.sh stop
	/usr/sbin/wifi_ap.sh stop
}


wifi_restart()
{
	echo "wifi restart and update wifi info"
	wifi_station_stop
	wifi_ap_stop
	wifi_station_start
	wifi_ap_start
}


wifi_reset()
{
	echo "wifi reset and update wifi info"
	wifi_stop
	/usr/sbin/wifi_run.sh &
}

my_station_start()
{
	/usr/sbin/wifi_station.sh start
	ifconfig wlan0 up
	/usr/sbin/wifi_station.sh connect
	killall udhcpc
	udhcpc -i wlan0 &
}

my_station_stop()
{
	/usr/sbin/wifi_station.sh stop
}


case "$MODE" in
	install)
		wifi_setup
		;;		
	uninstall)
		wifi_remove
		;;
	start)
		/usr/sbin/wifi_run.sh &
		;;
	stop)
		killall -15 wifi_run.sh
		wifi_stop
		;;
	restart)
		wifi_restart
		;;
	ap_start)
		/usr/sbin/wifi_ap.sh start
		;;
	ap_stop)
		/usr/sbin/wifi_ap.sh stop
		;;
	station_start)
		my_station_start
		;;
	station_stop)
		my_station_stop
		;;
	reset)
		sleep 2
		killall -15 wifi_run.sh
		wifi_reset
		;;
	*)
		usage
		;;
esac
exit 0

