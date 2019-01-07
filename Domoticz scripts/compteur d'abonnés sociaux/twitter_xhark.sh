#!/bin/bash
# twitter_xhark.sh : récupère les followers et les injecte dans un capteur virtuel
#
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr/diy/domoticz-twitter-followers-17738
VERSION="2019.01.05"

# === IDX DU CAPTEUR VIRTUEL ======================================================================
IDX=1124

# === PSEUDO TWITTER ==============================================================================
TWITTERNAME="xhark"

# === LECTURE DU NOMBRE DE FOLLOWERS ==============================================================
URL="https://cdn.syndication.twimg.com/widgets/followbutton/info.json?screen_names=${TWITTERNAME}"
ABO=$(curl -G -s $URL | jq -r '.[].followers_count')

# ===  METHODE ALTERNATIVE DANS LE CODE SOURCE (MOINS FIABLE) =====================================
#URL="https://twitter.com/${TWITTERNAME}"
#ABO=$(curl -G -s -L --connect-timeout 5 $URL | grep -Po 'followers_count&quot;:\K[[:digit:]]*')

# === INJECTION DANS LE CAPTEUR VIRTUEL ===========================================================
URL="http://localhost:8080/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${ABO}"
RETOUR=$(curl -s $URL | grep -i status)

### debug
#echo $ABO $RETOUR
#echo -e "\n\n\tFin du script - `date` - v$VERSION\n"
exit 0
