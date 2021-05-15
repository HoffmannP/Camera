stat=`wpa_cli -iwlan0 status |grep wpa_state`
if [ "$stat" != "wpa_state=COMPLETED" ]
	then
		echo station is unconnected
		exit 1
fi
exit 0
