#!/bin/bash
# immosquare.sh
#
# Envoie une notification (via ntfy) si presence d'un solde en 
# attente de reglement chez immosquare (syndic d'immeubles de Grenoble)
#
# author : Mr Xhark - twitter.com/xhark
# source : https://blogmotion.fr
# licence : Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
#         : https://creativecommons.org/licenses/by-nc-sa/4.0/
VERSION="2023.10.10"
########################################################################

# Vos identifiants de connexion (acces client)
IMMOLOGIN="123456"
IMMOPASSW="votre-mot-de-passe"

# Variables de fonctionnement
MIRE="https://extranet2.ics.fr/V5/connexion-immosquare.html"
COOKIE="/tmp/immosquare_cookies.txt"
COOKIEREPONSE="/tmp/immosquare_reponse.txt"

# https://github.com/blogmotion/bm-RaspberryPi/blob/master/Notification%20scripts/ntfy.sh/ntfy-ng/ntfy-ng.sh
NTFYSCRIPT="/home/pi/scripts/ntfy/ntfy-ng.sh"
NTFYTOPIC="le-nom-de-votre-topic-ntfy"


########################### DEBUT DU SCRIPT ############################

# Récupéreration du cookie PHPSESSID
login_response=$(curl --silent -c $COOKIE $MIRE)

# Extraction PHPSESSID du fichier de cookies
PHPID=$(grep -oP "(?<=PHPSESSID\t)[^;]+" ${COOKIE})

curl --silent "https://extranet2.ics.fr/login_externe.php" -X POST \
	-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0" \
	-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
	-H "Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3" -H "Accept-Encoding: gzip, deflate, br"\
	-H "Content-Type: application/x-www-form-urlencoded" -H "Origin: https://extranet2.ics.fr"\
	-H "DNT: 1" -H "Connection: keep-alive" \
	-H "Referer: ${MIRE}"\
	-H "Cookie: CABINET_GROUPE=immosquare; PHPSESSID=${PHPID}"\
	-H "Upgrade-Insecure-Requests: 1" -H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: same-origin" -H "Sec-Fetch-User: ?1" -H "Sec-GPC: 1" \
	-H "Pragma: no-cache" -H "Cache-Control: no-cache" -H "TE: trailers"\
	--data-raw "login=${IMMOLOGIN}&mdp=${IMMOPASSW}&groupe=immosquare"
	
curl --silent "https://extranet2.ics.fr/V5/initialisation.html" \
	-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0" \
	-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
	-H "Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3" -H "Accept-Encoding: gzip, deflate, br"\
	-H "Referer: https://extranet2.ics.fr/V5/connexion-immosquare.html" -H "DNT: 1" -H "Connection: keep-alive"\
	-H "Cookie: CABINET_GROUPE=immosquare; PHPSESSID=${PHPID}" -H "Upgrade-Insecure-Requests: 1"\
	-H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: same-origin" -H "Sec-Fetch-User: ?1" -H "Sec-GPC: 1"\
	-H "Pragma: no-cache" -H "Cache-Control: no-cache" -H "TE: trailers" \
	--compressed --output ${COOKIEREPONSE}

if ! grep -q . "${COOKIEREPONSE}"; then
   echo "ERREUR DE LOGIN"
   $NTFYSCRIPT --topic $NTFYTOPIC --message "[Immosquare] ERREUR LOGIN" --tags houses,no_entry --priority 3
   exit 1
fi


if grep -q -i "VOTRE SOLDE EST A JOUR" ${COOKIEREPONSE}; then
    echo "OK, RIEN A PAYER"
else
    MONTANT=$(grep -oP '<p class="prix-gros">\K[^€]+' ${COOKIEREPONSE})
    SOLDEMSG="[Immosquare] SOLDE ${MONTANT}€ A REGLER"
    echo $SOLDEMSG
    $NTFYSCRIPT --topic $NTFYTOPIC --message "$SOLDEMSG" --tags houses,moneybag --priority 3
fi

exit 0
