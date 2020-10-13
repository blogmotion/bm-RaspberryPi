#!/bin/bash
# risquePluie.sh : retourne le risque de pluie quotidien pour la ville de Grenoble (détaillé ou brut si paramètre)
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr/diy/notification-sms-pluie-17958
VERSION="2019.06.22"

# Villes compatibles: https://www.meteo-villes.com
URLWIDGET=""http://data.meteo-villes.com/previsions12j6.php?ville=grenoble"

# Lecture et extraction (-N pour ignorer le retour "(23) Failed writing body")
RISQUEPLUIE=$( curl -N -s --connect-timeout 5 $URLWIDGET | grep -Po '<risquePluie>\K[[:digit:]]*' --max-count=1 )
# 	[[:digit:]] => man 7 regex
#	\K http://perldoc.perl.org/perlrebackslash.html
#################################################################################################################################

# recuperation OK ET retour valeur brute pour API
if [[ $? -eq 0 &&  $# -eq "1" ]]; then
	echo ${RISQUEPLUIE}
	exit 0
fi

# recuperation OK (emoji désactivés car bug en sms avec gammu)
if [[ $? -eq 0 ]]; then
	# echelles
	if [[ "${RISQUEPLUIE}" -ge "0"  && "${RISQUEPLUIE}" -le "0" ]]; then
		prevision="Pas de pluie"
		#emoji="☘️"
	elif [[ "${RISQUEPLUIE}" -ge "10" && "${RISQUEPLUIE}" -le "10" ]]; then
		prevision="Pluie faible"
		#emoji="✅"
    elif [[ "${RISQUEPLUIE}" -ge "30" && "${RISQUEPLUIE}" -le "30" ]]; then
                prevision="Parapluie oblig"
		#emoji="🔰"
    elif [[ "${RISQUEPLUIE}" -ge "31" && "${RISQUEPLUIE}" -le "90" ]]; then
                prevision="Pluie et orage"
		#emoji="😑"
    elif [[ "${RISQUEPLUIE}" -ge "91" && "${RISQUEPLUIE}" -le "100" ]]; then
                prevision="Tempete de dingos"
		#emoji="❎"
    elif [[ "${RISQUEPLUIE}" -eq "100" ]]; then
                prevision="sup a 100 - a definir"
		#emoji="⛔️"
	else
		prevision="*erreur_range* : ${RISQUEPLUIE}"
    fi
	
	# on retourne la prevision et le risque de pluie
	echo "${prevision}, risque de ${RISQUEPLUIE}%"
	exit 0
else
	echo "(pluie timeout)"
	exit 1
fi