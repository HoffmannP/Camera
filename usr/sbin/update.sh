#!/bin/sh
# File:				update.sh	
# Provides:         
# Description:      update zImage&rootfs under dir1/dir2/...
# Author:			xc

VAR1="zImage"
VAR2="root.sqsh4"
VAR3="usr.sqsh4"
VAR4="usr.jffs2"

ZMD5="zImage.md5"
SMD5="usr.sqsh4.md5"
JMD5="usr.jffs2.md5"
RMD5="root.sqsh4.md5"

DIR1="/mnt"
DIR2="/tmp"

update_voice_tip(){
	echo "play update voice tips"
	echo "/usr/share/anyka_update_device.mp3" > /tmp/alarm_audio_list
	killall -12 anyka_ipc
	sleep 3
}

update_ispconfig()
{
	if [ -e "/tmp/isp.conf" ];then
		echo "updating isp.conf ..."
		rm -rf /etc/jffs2/isp.conf && cp /tmp/isp.conf /etc/jffs2/isp.conf
	fi

	if [ -e "/tmp/isp_night.conf" ];then
		echo "updating isp_night.conf ..."
		rm -rf /etc/jffs2/isp_night.conf && cp /tmp/isp_night.conf /etc/jffs2/isp_night.conf
	fi

}

update_kernel()
{
		echo "check ${VAR1}............................."
		
        for dir in ${DIR1} ${DIR2}
        do
            if [ -e ${dir}/${VAR1} ] 
    		then
				if [ -e ${dir}/${ZMD5} ];then
					cd ${dir}

					result=`md5sum -c ${dir}/${ZMD5} | grep OK`
					if [ -z "$result" ];then
						echo "MD5 check zImage failed, can't updata"
						break	
					else
						echo "MD5 check zImage success"
					fi
				fi

				echo "update ${VAR1} under ${dir}...."
				updater local K=${dir}/${VAR1}
				break
    	    fi	
        done
}

update_squash()
{		
		echo "check ${VAR3}.........................."

        for dir in ${DIR1} ${DIR2}
        do
            if [ -e ${dir}/${VAR3} ]
			then
				if [ -e ${dir}/${SMD5} ];then
					cd ${dir}

					result=`md5sum -c ${dir}/${SMD5} | grep OK`
					if [ -z "$result" ];then
						echo "MD5 check usr.sqsh4 failed, can't updata"
						break
					else
						echo "MD5 check usr.sqsh4 success"
					fi
				fi

    		    echo "update ${VAR3} under ${dir}...."
    		    updater local MTD2=${dir}/${VAR3}
    		    break
    	    fi	
        done
}

update_jffs2()
{
		echo "check ${VAR4}........................"

        for dir in ${DIR1} ${DIR2}
        do
            if [ -e ${dir}/${VAR4} ]
    		then
				if [ -e ${dir}/${JMD5} ];then
					cd ${dir}

					result=`md5sum -c ${dir}/${JMD5} | grep OK`
					if [ -z "$result" ];then
						echo "MD5 check usr.jffs2 failed, can't updata"
						break
					else
						echo "MD5 check usr.jffs2 success"
					fi
				fi

    		    echo "update ${VAR4} under ${dir}...."
    		    updater local MTD3=${dir}/${VAR4}
    		    break
    	    fi	
        done
}

update_rootfs_squash()
{		
		echo "check ${VAR2}.........................."

        for dir in ${DIR1} ${DIR2}
        do
            if [ -e ${dir}/${VAR2} ]
			then
				if [ -e ${dir}/${RMD5} ];then
					cd ${dir}

					result=`md5sum -c ${dir}/${RMD5} | grep OK`
					if [ -z "$result" ];then
						echo "MD5 check root.sqsh4 failed, can't updata"
						break
					else
						echo "MD5 check root.sqsh4 success"
					fi
				fi

    		    echo "update ${VAR2} under ${dir}...."
    		    updater local MTD1=${dir}/${VAR2}
    		    break
    	    fi	
        done
}

#
# main:
#
echo "stop system service before update....."
killall -15 syslogd
killall -15 klogd
killall -15 tcpsvd

# play update vioce tip
#update_voice_tip

/usr/sbin/led.sh blink 50 50
# send signal to stop watchdog
killall -12 daemon 
sleep 5
# kill apps, MUST use force kill
killall -9 daemon
killall -9 anyka_ipc
killall -9 net_manage.sh
/usr/sbin/wifi_manage.sh stop
killall -9 smartlink
/usr/sbin/wifi_manage.sh uninstall

# sleep to wait the program exit
i=5
while [ $i -gt 0 ]
do
	sleep 1

	pid=`pgrep anyka_ipc`
	if [ -z "$pid" ];then
		echo "The main app anyka_ipc has exited !!!"
		break
	fi

	i=`expr $i - 1`
done

if [ $i -eq 0 ];then
	echo "The main app anyka_ipc is still run, we don't do update, reboot now !!!"
	reboot
fi

echo "############ please wait a moment. And don't remove TFcard or power-off #############"

#led blink
#/usr/sbin/led.sh blink 50 50

# cp busybox to tmp, avoid the command become no use
cp /bin/busybox /tmp/

update_ispconfig

update_kernel
update_jffs2
update_squash
update_rootfs_squash

/tmp/busybox echo "############ update finished, reboot now #############"

/tmp/busybox sleep 3
if [ -f "/mnt/sdcmd_customer.sh" ]
then
/mnt/sdcmd_customer.sh
rm -rf /mnt/sdcmd_customer.sh
fi

if [ -f "/mnt/sdcmd_factory.sh" ]
then
/mnt/sdcmd_factory.sh
fi
/tmp/busybox sleep 3
/tmp/busybox reboot -f

