#!/bin/bash
# flashPluie.sh : allume une ampoule Phillips Hue en bleu avec un flash bleu
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr/diy/hue-flash-bleu-si-risque-pluie-17954 
VERSION="2019.06.22"

# === BRIDGE INFORMATIONS (MODIFIEZ CECI !) =============
IP=192.168.0.20
USER=1111a2222b3333c4444d5555e66666f
LIGHTID=1
# =======================================================

url="http://${IP}/api/${USER}/lights/${LIGHTID}/state"
log="/var/log/flashPluie-sh.log"

# lecture du risque en mode API
risquePluie=$(/home/pi/scripts_xhark/risquePluie.sh brut)
if [[ $risquePluie -ge 30 ]]; then
	
	# debug
	echo -e "\n\n Risque de pluie: ${risquePluie} \n Donc : Hue en bleu et clignote \n\n"

	# apres 10min, lampe bleue puis clignotte 30s
	curl -s -H "Accept: application/json" -X PUT --data "{\"on\":true, \"xy\":${coulxy['blue']}}" ${url} 	>> $log 2>&1
	sleep 1
	curl -s -H "Accept: application/json" -X PUT --data "{\"on\":true, \"alert\":\"select\"}" ${url} 		>> $log 2>&1
fi

exit 0
