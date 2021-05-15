#! /bin/sh
### BEGIN INIT INFO
# File:				service.sh	
# Provides:         init service 
# Required-Start:   $
# Required-Stop:
# Default-Start:     
# Default-Stop:
# Short-Description:web service
# Author:			gao_wangsheng
# Email: 			gao_wangsheng@anyka.oa
# Date:				2012-12-27
### END INIT INFO

MODE=$1
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin

usage()
{
	echo "Usage: $0 start|stop)"
	exit 3
}

stop_service()
{    
	echo "stop daemon service......"
	killall -12 daemon
	sleep 5
	killall -15 daemon
	/usr/sbin/anyka_ipc.sh stop
	
	killall -15 serail_deal
	echo "stop network service......"
	killall -15 net_manage.sh
	
    /usr/sbin/eth_manage.sh stop
    /usr/sbin/wifi_manage.sh stop
}

start_service ()
{
	echo "start daemon service......"
	burn
	#ljh	
	/usr/sbin/wifi_manage.sh install &
	#sleep 1
	#ljh
	daemon &
	sleep 3
	/usr/sbin/anyka_ipc.sh start
	sleep 13
#longjinhe	
	#sleep 2
#longjinhe

	echo "start net service......"
	#/usr/sbin/net_manage.sh &
	serail_deal &	
#	/usr/sbin/sync_time.sh start &
}

restart_service ()
{
	echo "restart service......"
	stop_service
	start_service
}

#
# main:
#

case "$MODE" in
	start)
		start_service
		;;
	stop)
		stop_service
		;;
	restart)
		restart_service
		;;
	*)
		usage
		;;
esac
exit 0

