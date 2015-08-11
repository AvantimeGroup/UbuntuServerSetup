#!/bin/bash
# Performance tweaks for vps system. Creating a swap file
swapSize=$1

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

while [ "$swapSize" == "" ]
do
	echo -e $"Please provide swap size (eg. 2G)"
	read swapSize
done



fallocate -l $swapSize /swapfile

chmod 600 /swapfile

mkswap /swapfile

swapon /swapfile

#Confirm that swap is on
swapon -s

echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab

#tweak swap
sysctl vm.swappiness=10

echo "vm.swappiness=10" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
