#!/bin/bash
systemRelease=$(lsb_release -is)
printf "######### WARNING ########\n"
printf "You need to be on the latest kernel!\n"
printf "Do you wish to proceed? Clr-boot-manager will RUN (on Solus)!\n"
select yn in "Yes" "No"; do
	case $yn in
		"Yes") if [ $systemRelease == "Solus" ]; then
				sudo clr-boot-manager update
			fi
			break;;
		"No") exit;;
	esac
done

mountPoint="/mnt"
partitionEFI=$(lsblk -o NAME,FSTYPE -l | grep vfat)
partitionEFI=${partitionEFI::-5}
if ! [[ `cat /proc/mounts | grep /boot` == "" ]]; then
	$mountPoint="/boot"
else
	if ! [[ `cat /proc/mounts | grep /mnt` == "" ]]; then
		printf "\n/mnt is busy! Please unmount /mnt!"
		printf "\nExiting...\n"
		exit    
	fi
	printf "\n----------------------\n\n"
	printf "Mounting EFI Partition ($partitionEFI)\n"
	sudo mount /dev/$partitionEFI $mountPoint
fi

printf "\n----------------------\n\n"
printf "Configuring...\n"
printf "Original boot options with Nvidia modules disabled!\n"
configFile=`ls -t $mountPoint/loader/entries/ | grep -iv fallback | grep -i $systemRelease | head -1`

if [[ `sudo cat $mountPoint/loader/entries/$configFile | grep modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm` == '' ]]; then
	sudo sed -i '/options/s/$/ modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm/' $mountPoint/loader/entries/$configFile
fi
sudo cp -f $mountPoint/loader/entries/$configFile $mountPoint/loader/entries/nvidia.conf
sudo sed -i '/title/s/$/ Nvidia/' $mountPoint/loader/entries/nvidia.conf

if [[ `sudo cat $mountPoint/loader/entries/nvidia.conf | grep rd.driver.blacklist=nouveau` == '' ]]; then
	sudo sed -i '/options/s/$/ rd.driver.blacklist=nouveau/' $mountPoint/loader/entries/nvidia.conf
fi
if [[ `sudo cat $mountPoint/loader/entries/nvidia.conf | grep modprobe.blacklist=nouveau` == '' ]]; then
	sudo sed -i '/options/s/$/ modprobe.blacklist=nouveau/' $mountPoint/loader/entries/nvidia.conf
fi
if [[ `sudo cat $mountPoint/loader/entries/nvidia.conf | grep nvidia-drm.modeset=1` == '' ]]; then
	sudo sed -i '/options/s/$/ nvidia-drm.modeset=1/' $mountPoint/loader/entries/nvidia.conf
fi

sudo sed -i 's/\<modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm\> //g' $mountPoint/loader/entries/nvidia.conf
sudo sed -i 's/blacklist/#blacklist/g' /usr/lib/modprobe.d/nvidia.conf
printf "\nNew boot menu entry with Nvidia modules enabled\n"

if [[ $mountPoint == "/mnt" ]]; then
	sudo umount $mountPoint
fi