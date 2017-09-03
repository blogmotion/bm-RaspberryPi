# Dynamic MOTD
#
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr 
VERSION="2016.09.23"

black=$(tput setaf 0); white=$(tput setaf 7); green=$(tput setaf 2); yellow=$(tput setaf 3); magenta=$(tput setaf 5); 
on_green=$(tput setab 2); on_magenta=$(tput setab 5); on_white=$(tput setab 7); 
normal=$(tput sgr0); bold=$(tput bold); title=${bold}${white}${on_magenta}
    
let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
let secs=$((${upSeconds}%60)); let mins=$((${upSeconds}/60%60)); let hours=$((${upSeconds}/3600%24)); let days=$((${upSeconds}/86400))

UPTIME=`printf "%d jours, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs"`
DISTRO="$(lsb_release -is) $(lsb_release -cs) $(lsb_release -rs)"

# get the load averages
read one five fifteen rest < /proc/loadavg

echo "
		      [ ${title}   Bienvenue sur la framboise :)   ${normal} ]
		      [ ${black}${on_green}Load: ${one}, ${five}, ${fifteen} (1,5,15 min)${normal} ]
${green}
		      `date +"%A %e %B %Y, %H:%M:%S"`
       .~~.   .~~.    $DISTRO
      '. \ ' ' / .'   `uname -srmo`${yellow}
       .~ .~~~..~.   
      : .~.'~'.~. :   Uptime...............: ${UPTIME}
     ~ (   ) (   ) ~  Memoire..............: $((`cat /proc/meminfo | grep MemFree | awk {'print $2'}`/1024))MB (Free) / $((`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`/1024))MB (Total)
    ( : '~'.~.'~' : ) CPU..................: `vcgencmd measure_temp | sed "s/temp=//"`
     ~ .~ (   ) ~. ~  Processus en exec....: `ps ax | wc -l | tr -d " "`
      (  : '~' :  )   Adresses IP..........: `/sbin/ifconfig | /bin/grep "Bcast:" | /usr/bin/cut -d ":" -f 2 | /usr/bin/cut -d " " -f 1`
       '~ .~~~. ~'    Temperature salon....: `cat /sys/bus/w1/devices/28-*/w1_slave | grep "t=" | awk -F "t=" '{printf("%.1f\n", $2/1000)}'`'C
           '~'        Temperature balcon...: `curl --ipv4 -s "http://localhost:8080/json.htm?type=devices&rid=760" | jq -r .result[]."Data" | sed "s/ C/\'C/g" `
    $(tput sgr0)"