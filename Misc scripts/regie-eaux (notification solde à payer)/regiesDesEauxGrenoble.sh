#!/bin/bash
# regiesDesEauxGrenoble.sh
#
# Envoie une notification (via ntfy) quand
# facture de "Regie Des Eaux" (Metropole Grenobloise) à payer
#
# author : Mr Xhark, @xhark
# tutoriel : https://blogmotion.fr/programmation/bash/script-notification-facture-de-regie-des-eaux-grenoble

# licence : Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
#         : https://creativecommons.org/licenses/by-nc-sa/4.0/
VERSION="2024.03.25"

# Script compatible uniquement avec les communes en gestion par la Metro
# Votre communique doit etre dans cette liste :
# curl -s https://ael.eauxdegrenoblealpes.fr/local/communes.json | jq -r '.items[] | select(.nomSociete == "METROPOLE") | .nomCommune' || echo "JQ est manquant, installez-le"


############################## VARIABLES ###############################

# Identifiants client
LOGIN="mon@email.fr"
PASSW="xxxxxxxxxxxxxxxx"

# Numero de contrat (voir facture / espace client en ligne)
NUMCONTRAT="1234567"

# Script et topic ntfy (voir https://github.com/blogmotion/bm-RaspberryPi/blob/master/Notification%20scripts/ntfy.sh/ntfy-ng/ntfy-ng.sh)
NTFYSCRIPT="/home/pi/ntfy/ntfy-ng.sh"
NTFYTOPIC="topic-ntfy-au-choix"


########################### DEBUT DU SCRIPT ############################

if ! command -v jq &> /dev/null; then
    echo "Erreur : jq n'est pas installé. Veuillez l'installer pour exécuter ce script."
    echo "Debian based : apt install jq -y"
    echo "RedHat based : dnf install jq -y"
    exit 1
fi

COOKIE_HOME=$(mktemp "/tmp/regiedeseaux_cookieHome.XXXXXXXX")
COOKIE_BIGIP=$(mktemp "/tmp/regiedeseaux_cookieBigIP.XXXXXXXX")
CURLHEADER0=$(mktemp "/tmp/regiedeseaux_cUrlHeader0.XXXXXXXX")
CURLHEADER1=$(mktemp "/tmp/regiedeseaux_cUrlHeader1.XXXXXXXX")
CURLHEADER2=$(mktemp "/tmp/regiedeseaux_cUrlHeader2.XXXXXXXX")


# https://stackoverflow.com/a/51487158
HEADERS_DEB=(
	-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0'
	-H 'Accept: application/json, text/plain, */*'
	-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3'
	-H 'Accept-Encoding: gzip, deflate, br'
)

HEADERS_FIN=(
        -H 'Content-Type: application/json;charset=utf-8'
        -H 'Origin: https://eau.grenoblealpesmetropole.fr'
        -H 'Connection: keep-alive'
        -H 'Referer: https://eau.grenoblealpesmetropole.fr/index.html'
        -H 'Sec-Fetch-Dest: empty'
        -H 'Sec-Fetch-Mode: cors'
        -H 'Sec-Fetch-Site: same-origin'
        -H 'Sec-GPC: 1'
        -H 'Pragma: no-cache'
        -H 'Cache-Control: no-cache'
)


echo "___ Debut du script v${VERSION} par @xhark ___" && echo

# Generation conversationId random par bash
conversationId="JS-WEB-Netscape-$(cat /proc/sys/kernel/random/uuid)"
echo " > conversationId=${conversationId}" && echo

dataraw='{
    "ConversationId": "'${conversationId}'",
    "ClientId": "AEL-TOKEN-GAM-PRD",
    "AccessKey": "Bh!66-GAM-GRE-MP1-PRD"
}'

datarawform='{"identifiant": "'${LOGIN}'","motDePasse": "'${PASSW}'"}'


#----------------------------------------------------------------------------------------------------------------------------
echo "=== [CURL_0] Lecture cookie BigIP ==="
HEADER_CURL_0="${CURLHEADER0}"

curl --silent -L 'https://eau.grenoblealpesmetropole.fr/index.html#/login' \
     --dump-header "${HEADER_CURL_0}" \
     --output /dev/null

COOKIE_BIGIP=$(awk -F 'Set-Cookie: BIGipServerfrt-ael-gam_pool=|; ' '/Set-Cookie: BIGipServerfrt-ael-gam_pool=/{print $2}' $HEADER_CURL_0)

echo " > Cookie BigIP=${COOKIE_BIGIP}" && echo


#----------------------------------------------------------------------------------------------------------------------------
echo "=== [CURL_1] Recup openToken et MessageId (/generateToken) ==="
jsonToken=$(curl --silent -L 'https://eau.grenoblealpesmetropole.fr/webapi/Acces/generateToken' -X POST \
    --dump-header "${CURLHEADER1}" \
	"${HEADERS_DEB[@]}" \
    -H 'Cookie: BIGipServerfrt-ael-gam_pool='${COOKIE_BIGIP} \
    -H 'ConversationId: '$conversationId \
    -H 'Token: Bh!66-GAM-GRE-MP1-PRD' \
    "${HEADERS_FIN[@]}" \
     --data-raw  "$dataraw"
)

openToken=$(echo "$jsonToken" | jq -r '.token')
msgId=$(grep -oP "MessageId: \K\S+" "${CURLHEADER1}")

echo " > OpenToken=${openToken}"
echo " > MessageId=${msgId}" && echo


#----------------------------------------------------------------------------------------------------------------------------
echo "=== [CURL_2] Envoi du formulaire de connexion (/authentification) ==="
ret3=$(curl --silent -L 'https://eau.grenoblealpesmetropole.fr/webapi/Utilisateur/authentification' -X POST \
    --dump-header "${CURLHEADER2}" \
	"${HEADERS_DEB[@]}" \
    -H 'Token: '${openToken} \
    -H 'ConversationId: '${conversationId} \
    -H 'Cookie: BIGipServerfrt-ael-gam_pool='${COOKIE_BIGIP} \
    "${HEADERS_FIN[@]}" \
     --data-raw "$datarawform" \
)

tokenAuthentique=$(echo "$ret3" | jq -r '.tokenAuthentique')

echo " > tokenAuthentique=${tokenAuthentique}" && echo


#----------------------------------------------------------------------------------------------------------------------------
echo "=== [CURL_3] Lecture solde euros (/Facturation) ==="
retSolde=$(curl --silent -L "https://eau.grenoblealpesmetropole.fr/webapi/Facturation/soldeComptableContratAbonnement/${NUMCONTRAT}"  \
	"${HEADERS_DEB[@]}" \
	-H 'Token: '${tokenAuthentique} \
	-H 'ConversationId: '${conversationId} \
	-H 'Cookie:  BIGipServerfrt-ael-gam_pool='${COOKIE_BIGIP}'; aelToken='${openToken} \
	"${HEADERS_FIN[@]}" \
)

soldeEuros=$(echo "$retSolde" | jq -r . )

if [[ $soldeEuros -eq "0,0" ]]; then
   echo "OK (Rien a payer: $soldeEuros eur)"
else
    SOLDEMSG="[Facture d'Eau] ${soldeEuros}€ A REGLER"
    echo $SOLDEMSG
    $NTFYSCRIPT --topic $NTFYTOPIC --message "$SOLDEMSG"  --tags droplet,moneybag --priority 3

   echo "Solde a payer : $soldeEuros euros"
fi


trap 'rm -f $COOKIE_HOME $COOKIE_BIGIP' EXIT
echo && exit 0