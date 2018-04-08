#!/bin/sh
###########################################
# Check RamDisk left space
###########################################
# auteur : Mr Xhark (blogmotion.fr)
# source : http://blogmotion.fr/
#
# licence type	: Creative Commons Attribution-NoDerivatives 4.0 (International)
# licence info	: http://creativecommons.org/licenses/by-nd/4.0/
# inspired from : https://www.cyberciti.biz/tips/shell-script-to-watch-the-disk-space.html
VERSION="2018.04.08"
###########################################
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

### VARIABLES ###
MOUNT='/ramdisk'	# mount to check
MAXPERCENT=80		# disk space max threshold
### FIN DES VARIABLES ###

df -H | grep -i $MOUNT | awk '{ print $5 " " $1 }' | while read output;
do
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
  partition=$(echo $output | awk '{ print $2 }' )
  if [ $usep -ge $MAXPERCENT ]; then
    
	# email notification with telnet and tty notification
	/root/RamDiskEmailNotif.sh
	echo "REBOOT DANS 60 SECONDES PURGE RAMDISK" | wall && sleep 5 && reboot
	
	# email notification with mail
	#echo "LE RAMDISK EST PLEIN  \"$partition ($usep%)\" sur $(hostname) au $(date)" | mail -s "Alert: Almost out of disk space $usep%" you@somewhere.com
	#echo "LE RAMDISK EST PLEIN  \"$partition ($usep%)\" sur $(hostname) au $(date)"

  fi
done
