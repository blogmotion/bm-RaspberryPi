# Dynamic MOTD
#
# Author: Mr Xhark -> x.com/xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : https://blogmotion.fr/systeme/raspberry-pi-comment-ajouter-une-banniere-dynamique-motd-15133
VERSION="2025.10.30"

black=$(tput setaf 0); white=$(tput setaf 7); green=$(tput setaf 2); yellow=$(tput setaf 3); magenta=$(tput setaf 5); 
on_green=$(tput setab 2); on_magenta=$(tput setab 5); on_white=$(tput setab 7); 
normal=$(tput sgr0); bold=$(tput bold); title=${bold}${white}${on_magenta}
    
let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
let secs=$((${upSeconds}%60)); let mins=$((${upSeconds}/60%60)); let hours=$((${upSeconds}/3600%24)); let days=$((${upSeconds}/86400))

UPTIME=`printf "%d jours, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs"`
PIVERSION=$(awk -F': ' '/^Model/ {print $2}' /proc/cpuinfo)
DISTRO="Raspbian $(cat /etc/debian_version)"
MYIPS=$(ip -o addr | grep -vE "169|127" | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $4" ("$2")"}' | tr '\n' " ")

# get the load averages
read one five fifteen rest < /proc/loadavg

### LECTURE DES SONDES DOMOTICZ#################################################################################################################################

	TEMP_FILAIRE=$(cat /sys/bus/w1/devices/28-*/w1_slave 2>/dev/null | grep "t=" | awk -F "t=" '{printf("%.1f\n", $2/1000)}' || echo 'erreur sonde salon')
	if [[ ${TEMP_FILAIRE} = "" ]]; then
			TEMP_FILAIRE="-- (capteur absent)"
	else
			TEMP_FILAIRE+="'C" # ajout du suffixe: 'C
	fi
	# Remplacer 1234 par l'ID de votre sonde
	TEMPHUM_BALCON=$(curl -s "http://localhost:8080/json.htm?param=getdevices&rid=1234&type=command" | jq -r '.result[0].Data // empty' 2>/dev/null)

	if [ -n "$TEMPHUM_BALCON" ] && [ "$TEMPHUM_BALCON" != "null" ]; then
		TEMPHUM_BALCON=$(echo "$TEMPHUM_BALCON" | sed "s/ C/°C/")
		TEMPHUM_BALCON="${TEMPHUM_BALCON} d'humidité"
	else
		TEMPHUM_BALCON="erreur sonde balcon"
	fi
################################################################################################################################################################

echo "
		      [ ${title}Bienvenue sur ${HOSTNAME}${normal} ]
		      [ ${black}${on_green}Load: ${one}, ${five}, ${fifteen} (1,5,15 min)${normal} ]
${green}
		      `date +"%A %e %B %Y, %H:%M:%S"`
       .~~.   .~~.    $DISTRO / $PIVERSION
      '. \ ' ' / .'   `uname -srmo`${yellow}
       .~ .~~~..~.   
      : .~.'~'.~. :   Uptime...............: ${UPTIME}
     ~ (   ) (   ) ~  Memoire..............: $((`cat /proc/meminfo | grep MemFree | awk {'print $2'}`/1024))MB (Free) / $((`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`/1024))MB (Total)
    ( : '~'.~.'~' : ) CPU..................: `vcgencmd measure_temp | sed "s/temp=//"`
     ~ .~ (   ) ~. ~  Processus en exec....: `ps ax | wc -l | tr -d " "`
      (  : '~' :  )   Adresses IP...........: ${MYIPS}
       '~ .~~~. ~'    Temperature filaire...: ${TEMP_FILAIRE}
           '~'        Temperature exterieure: ${TEMPHUM_BALCON}
    $(tput sgr0)"