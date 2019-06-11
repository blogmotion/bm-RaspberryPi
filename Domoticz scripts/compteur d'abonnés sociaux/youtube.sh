#!/bin/bash
# youtube_xhark.sh : récupère les abonnes d'une chaine YouTube et les injecte dans un capteur virtuel domoticz
#
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr/diy/domoticz-compteur-abonnes-youtube-17931
VERSION="2019.06.12"

# === IDX DU CAPTEUR VIRTUEL DOMOTICZ ======================================================================
IDX=1123

# === ID CHAINE YOUTUBE ====================================================================================
IDCHAINE="UC9_nxvBohH1G2yR77XTdA2g"

# Cle API Google Dev
APIKEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

############################################################################################################
# === LECTURE DU NOMBRE DE FOLLOWERS =======================================================================
# lecture du nombre d'abo
ABO=$(curl -G -s https://www.googleapis.com/youtube/v3/channels \
     -d part="statistics" \
     -d id=${IDCHAINE} \
     -d key=${APIKEY} | \
     jq -r '.items[].statistics | (.subscriberCount)')

# === INJECTION DANS LE CAPTEUR VIRTUEL ===========================================================
URL="http://localhost:8080/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${ABO}"
RETOUR=$(curl -s $URL | grep -i status)

### debug
#echo $ABO $RETOUR
#echo -e "\n\n\tFin du script - `date` - v$VERSION\n"
exit 0
