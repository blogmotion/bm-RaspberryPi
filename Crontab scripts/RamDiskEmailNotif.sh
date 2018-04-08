#!/bin/sh
###########################################
# Email notification with telnet
###########################################
# auteur : Mr Xhark (blogmotion.fr)
# source : http://blogmotion.fr/
#
# licence type	: Creative Commons Attribution-NoDerivatives 4.0 (International)
# licence info	: http://creativecommons.org/licenses/by-nd/4.0/
VERSION="2018.04.08"
###########################################

### VARIABLES ###
DOMAINRECEIVED="sfr.fr"
SMTPSERVER="smtp.sfr.fr"
PORT=25
FROM="bot@mondomaine.fr"
TO="me@mondomaine.fr"
MOUNT='/ramdisk'
EMAIL="Reboot de $(hostname) car RamDisk plein : $(echo; echo ; df -h $MOUNT)"
OBJET="[RamDisk-Plein] Donc reboot de $(hostname)"
### FIN DES VARIABLES ###

DATETIME=$(date +"%d-%m-%Y %H:%M:%S")
MAILERNAME="blogmotion-mailer"
MAILERVERSION="1.0"
DELAY=2

if (
 sleep $DELAY
 echo "HELO $DOMAINRECEIVED"
 sleep $DELAY
 echo "MAIL FROM:<$FROM>"
 sleep $DELAY
 echo "RCPT TO:<$TO>"
 sleep $DELAY
 echo "DATA"
 sleep $DELAY
 echo "Date: $DATETIME"
 echo "From: $FROM"
 echo "To: $TO"
 echo "Subject: $OBJET"
 echo "X-Mailer: $MAILERNAME $MAILERVERSION"
 echo "X-hark: good-joke!"
 echo ""
 echo "$EMAIL"
 echo ""
 echo $DATETIME
 echo "."
 sleep $DELAY
 echo "QUIT"
 sleep $DELAY
 ) | telnet $SMTPSERVER $PORT; then
 :
else
 logger -t "ramdisk_full" "WARNING: impossible d'envoyer le mail de notification de ramdisk plein via telnet. Script : $_"
 exit 0
fi
exit 0
