#! /bin/sh
### BEGIN INIT INFO
# File:				net_manage.sh
# Provides:         select eth or wifi
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description 
# Author:			
# Email: 			
# Date:				2013-1-15
### END INIT INFO

mode=""
status=""

check_and_start_wlan()
{
	if [ "$mode" != "wlan" ]
	then
		mode=wlan
		#/usr/sbin/wifi_manage.sh start
		/usr/sbin/wifi_manage.sh station_start
	fi
}

check_and_start_eth()
{
	if [ "$mode" != "eth" ]
	then
		mode=eth
		/usr/sbin/wifi_manage.sh stop
		/usr/sbin/eth_manage.sh start
	fi
}


#
#main
#

#Do load ethernet module?
echo "load wifi manage install"
/usr/sbin/wifi_manage.sh install
sleep 3
echo "load wifi manage install ok"


if [ ! -d "/sys/class/net/eth0" ]
then
	/usr/sbin/wifi_manage.sh start
	exit 1
else
	#ethernet always up
	ifconfig eth0 up
	sleep 3
fi
	
status=`ifconfig eth0 | grep RUNNING`
while true
do
	#check whether insert internet cable
	
	if [ "$status" = "" ]
	then
		#don't insert internet cable
		echo "insert internet cable  check_and_start_wlan"
		check_and_start_wlan		
	else
		#have inserted internet cable
		check_and_start_eth
	fi

	tmp=`ifconfig eth0 | grep RUNNING`
	if [ "$tmp" != "$status" ]
	then		
		sleep 2
		tmp=`ifconfig eth0 | grep RUNNING`
		status=$tmp
	fi
    sleep 1
done
exit 0

