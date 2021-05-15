#! /bin/sh
### BEGIN INIT INFO
# File:				wifi_ap.sh	
# Provides:         wifi ap start and stop
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description:start wifi run at station or softAP
# Author:			
# Email: 			
# Date:				2014-12-19
### END INIT INFO

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin
MODE=$1
cfgfile="/etc/jffs2/anyka_cfg.ini"

usage()
{
	echo "Usage: $0 start | stop "
}

wifi_station_start()
{
	
	wpa_supplicant -B -iwlan0 -Dwext -c /etc/jffs2/wpa_supplicant.conf
	
}


wifi_station_connect()
{
	echo "connect wifi station......"

	
	ssid=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	mode=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^mode/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	security=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^security/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	password=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^password/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
	ssid=`echo "$ssid"|awk '{print $1}'`
	password=`echo "$password"|awk '{print $1}'`
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
	/usr/sbin/station_connect.sh $security "$ssid" "$password" 
	
}

wifi_station_stop()
{
	echo "stop wifi station......"
	killall wpa_supplicant
	killall udhcpc
	ifconfig wlan0 down
}


case "$MODE" in
	start)
		wifi_station_start
		;;
	stop)
		wifi_station_stop
		;;
	connect)
		wifi_station_connect
		;;
	*)
		usage
		;;
esac
exit 0


