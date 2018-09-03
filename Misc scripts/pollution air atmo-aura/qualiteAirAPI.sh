#!/bin/bash
# Lecture qualité air grenoble via API Atmo (http://api.atmo-aura.fr/documentation)
# Date: 2018.09.03
# Auteur: @xhark - http://blogmotion.fr/diy/pollution-grenoble-api-atmo-aura-17474
# Licence CC

APIKEY="xxxxxxxxxxxxxxxxxxxxxx"	# Votre cle API Atmo-Aura
INSEEC="38185"					# Code INSEE commune 38185=Grenoble - https://bit.ly/codeinsee

### NE RIEN TOUCHER SOUS CETTE LIGNE #####################################################################
which jq 2>&1 >/dev/null || (echo "ERREUR: jq absent, essayez: sudo apt install jq"; exit 1)

URLINDICE="https://api.atmo-aura.fr/communes/${INSEEC}/indices?date=now&api_token=${APIKEY}"
JSON=$(curl -L -s --connect-timeout 5 $URLINDICE) || CURL_RETURN_CODE=$?

if [[ ${CURL_RETURN_CODE} -ne 0 ]]; then
	echo "[qualiteAirAPI] Erreur de connexion, verifiez l'URL. Code de retour cURL=${CURL_RETURN_CODE} (https://bit.ly/curlerr)"; exit 1
else
	if [[ ${JSON} = *"bad_token"* ]]; then
        	echo "[qualiteAirAPI] Erreur de token, verifiez la variable APIKEY"; exit 1
	fi
fi

# tonumber car string en entree et erreur "number required" sinon, floor pour arrondir 34.4393939 => 34
POURCENTAIR=$(echo "$JSON" | jq -r '.indices .valeur | tonumber | floor')
QUALITE2AIR=$(echo "$JSON" | jq -r '.indices .qualificatif | ascii_downcase')

# si appel du script avec 1 argument alors on retourne juste le % (cas injection dans domoticz)
if [[ $# -eq "1" ]]; then
	echo ${POURCENTAIR} ; exit 0
fi

# En cas de pollution importante >  90 on met en MAJUSCULES
if [[ "${POURCENTAIR}" -ge "91" ]]; then
	QUALITE2AIR=$(echo $QUALITE2AIR | awk '{print(toupper($0))}')
fi

echo "Air ${QUALITE2AIR}, pollution ${POURCENTAIR}% (via API)." ; exit 0