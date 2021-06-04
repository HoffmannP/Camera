#!/bin/bash

sudo unsquashfs mtdblock2
sudo cp wifi_station.sh squashfs-root/sbin/
sudo gensquashfs -f -D squashfs-root -k -x mtdblock2.new
sqfsdiff -a mtdblock2 -b mtdblock2.new
sudo rm -rf squashfs-root
