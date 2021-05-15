#! /bin/sh
### BEGIN INIT INFO
# File:				wifi_run.sh	
# Provides:         manage wifi station and ap
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
ssid=

ssid_err=0
wifi_offline=0

play_please_config_net()
{
	ssid=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`

	ssid=`echo "$ssid"|awk '{print $1}'`
	if [ "$ssid" = "" ]
	then
		echo "/usr/share/anyka_please_config_net.mp3" > /tmp/alarm_audio_list
		echo "play please config wifi tone"
		sleep 3
		killall -12 anyka_ipc	## send signal to anyka_ipc
		## anyka_ipc receive it and read the file "/tmp/alarm_audio_list" to choice play which tone
		## the same as next 3 way
	fi
}

play_wifi_afresh_config()
{
	if [ "$ssid_err" = "0" ]
	then
		echo "/usr/share/anyka_afresh_net_config.mp3" > /tmp/alarm_audio_list
		echo "play ssid or password error, please afresh wifi config tone"
		killall -12 anyka_ipc
		ssid_err=1
	fi
}

play_wifi_offline()
{
	if [ "$wifi_offline" = "0" ]
	then
		echo "/usr/share/anyka_connected_failed.mp3" > /tmp/alarm_audio_list
		echo "play wifi offline tone"
		killall -12 anyka_ipc
		wifi_offline=1
	fi
}

play_wifi_connected_tone()
{
	echo "/usr/share/anyka_connected_success.mp3" > /tmp/alarm_audio_list
	echo "play wifi connected success tone"
	killall -12 anyka_ipc

	if [ "$wifi_offline" = "1" ]
	then
		wifi_offline=0
	fi
}

check_ssid_valid()
{
	ap=""
	scan_time=0
	while [ "$ap" = "" ]
	do
		ssid=`awk 'BEGIN {FS="="}/\[wireless\]/{a=1} a==1&&$1~/^ssid/{gsub(/\"/,"",$2);gsub(/\;.*/, "", $2);gsub(/^[[:blank:]]*/,"",$2);print $2}' $cfgfile`
		ssid=`echo "$ssid"|awk '{print $1}'`
		if [ "$ssid" = "" ]
		then
			ifconfig wlan0 down
			sleep 10
			continue
		fi
		ifconfig wlan0 up
		scan_time=`expr $scan_time + 1`
		echo "scanning.. $scan_time"

		for wpa_cli_try_time in 1 2 3 4 5 6 7 8 9 10
		do 
			scan_result=`wpa_cli -iwlan0 scan | grep OK` 
			if [ "$scan_result" != "" ]
			then 
				break
			fi	
			sleep 1		
		done

		#	echo "scan is $wpa_cli_try_time"

		if [ "$scan_result" != "" ]
		then
			for wpa_cli_try_time in 1 2 3 4 5
			do
				scan_result=`wpa_cli -iwlan0 scan_results |grep "\b$ssid\b"`
				if [ "$scan_result" != "" ]
				then 
					break
				fi
				sleep 1
			done
		fi

		ap=$scan_result
		if [ "$ap" = "" ]
		then
			echo "we can't find the wifi of $ssid"
			ifconfig wlan0 down
			sleep 60
		else
			value=`wpa_cli -iwlan0 scan_results |grep "\b$ssid\b" | awk '{print $3}'`
			echo "wifi is $value"
			value=`expr $value + 0`
			if [ $value -lt -80 ]
			then
				echo "the wifi signal is very weak, we can't connect it "
				ifconfig wlan0 down
				sleep 10
				continue
			else
				break
			fi
		fi
	done
	echo "Scan results: $ap"
}

check_ip_and_start()
{
	status=
	i=0
	while [ $i -lt 20 ] 
	do
		echo "Getting ip address..."
		killall udhcpc
		udhcpc -i wlan0
		status=`ifconfig wlan0 | grep "inet addr:"`
		if [ "$status" != "" ] 
		then
			break
		fi
		i=`expr $i + 1`
		sleep 1
	done
	
	if [ "$i" = "20" ]
	then
		echo "wifi fails to get ip address"
		return 0
	fi
	if [ -d "/sys/class/net/eth0" ]
	then
	    ifconfig eth0 down
	    ifconfig eth0 up
	fi
	
	/usr/sbin/led.sh blink 4000 200
	echo "wifi connected!"

	play_wifi_connected_tone

	return 1
}

check_station_connect()
{	
	stat=
	i=0
	while [ $i -lt 5 ] 
	do
		sleep 2
		stat=`wpa_cli -iwlan0 status |grep wpa_state`
		echo "time$i: $stat"
		if [ "$stat" = "wpa_state=COMPLETED" ]
		then		
			echo " wpa_cli connect info $stat"
			check_ip_and_start
			return $?
		fi
		i=`expr $i + 1`
	done

	echo " wpa_cli connect time out $i $stat"
	return 0
}

check_station_run()
{
	while true 
	do
		stat=`wpa_cli -iwlan0 status |grep wpa_state`
		if [ "$stat" != "wpa_state=COMPLETED" ]
		then	
			echo station is unconnected	
			play_wifi_offline
			return 0
		fi
	
		sleep 1
	done
	return 1
}

play_please_config_net 	### new machine need to configure ssid and password, play one time

while true
do
	/usr/sbin/wifi_ap.sh start
	while true
	do
		/usr/sbin/wifi_station.sh start
		check_ssid_valid
		/usr/sbin/wifi_station.sh connect
		check_station_connect
		status=$?
		if [ "$status" = "0" ]
		then
			echo station_connect fail
			if [ "$ssid_err" = "0" ]
			then
				play_wifi_afresh_config
			fi
			/usr/sbin/wifi_station.sh stop
			sleep 60
		else
			echo station connect is ok
			break
		fi			
	done
	/usr/sbin/wifi_ap.sh stop
	check_station_run
	/usr/sbin/wifi_station.sh stop
done

