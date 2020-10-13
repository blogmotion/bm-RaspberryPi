#!/bin/bash
# poe.sh : allume ou éteint un port PoE via SNMP (utilisation dans Domoticz)
# Author: Mr Xhark -> @xhark, TurboX
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr/diy/domoticz-port-poe-18546
VERSION="2020.10.14"

# === VARIABLES (MODIFIEZ CECI !) =============
switchIP="192.168.0.250"
snmpCommunity="pass2fou"
# =======================================================

# Nombre d'arguments OK
if [[ $# -eq 2 ]]
then
        PORT=$1
        ACTION=$2
		
		# port 1 à 99
        if ! [[ $PORT =~ ^[1-9][0-9]*$ ]]; then
                echo -e "\n\nERREUR: le port est invalide (1-99)\n\n"
                exit 0
        fi

		# ordre 1 ou 2
		if [[ $ACTION == "ON" ]]; then 
			ACTIONCMD=1
		elif [[ $ACTION == "OFF" ]]; then 
			ACTIONCMD=2
        else
			echo -e "\n\nERREUR: ordre invalide (ON,OFF)\n\n"
			exit 0
        fi
else
        echo -e "\n\nUsage : `basename $0` <port> <ON,OFF>\n\n"
        exit 0
fi

snmpset -v2c -c ${snmpCommunity} ${switchIP} 1.3.6.1.2.1.105.1.1.1.3.1.${PORT} i ${ACTIONCMD} && exit 0 \
	|| (echo -e "\n\nERREUR: impossible d'envoyer la commande SNMP\n\n"; exit 1)