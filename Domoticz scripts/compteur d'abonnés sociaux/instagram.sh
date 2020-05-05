#!/bin/bash
# instagram.sh : récupère les abonnes d'une chaine instagram et les injecte dans un capteur virtuel domoticz
#
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr/diy/domoticz-compteur-abonnes-instagram-18320
VERSION="2020.06.05"

# === IDX DU CAPTEUR VIRTUEL DOMOTICZ ======================================================================
IDX=1125

# === PSEUDO INSTAGRAM ====================================================================================
INSTANAME="xhark"

############################################################################################################
# === LECTURE DU NOMBRE DE FOLLOWERS =======================================================================
URLINSTA="https://www.instagram.com/${USER}/?__a=1"
ABO=$(curl -G -s $URLINSTA | jq -r '.["graphql"] ."user" ."edge_followed_by" ."count"')

# === INJECTION DANS LE CAPTEUR VIRTUEL ===========================================================
URL="http://localhost:8080/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${ABO}"
RETOUR=$(curl -s $URL | grep -i status)

### debug
#echo $ABO $RETOUR
#echo -e "\n\n\tFin du script - `date` - v$VERSION\n"
exit 0
