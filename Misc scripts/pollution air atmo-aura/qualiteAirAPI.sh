#!/bin/bash
# Lecture qualité air grenoble via API Atmo (http://api.atmo-aura.fr/documentation)
# Date: 2018.09.03
# Udp : 2026.06.04
# Auteur: @xhark - https://blogmotion.fr/diy/pollution-grenoble-api-atmo-aura-17474
# Licence CC

APIKEY="xxxxxxxxxxxxxxxxxxxxxx"	# Votre cle API Atmo-Aura
INSEEC="38185"					# Code INSEE commune 38185=Grenoble - https://bit.ly/codeinsee

### NE RIEN TOUCHER SOUS CETTE LIGNE #####################################################################
URL="https://api.atmo-aura.fr/api/v1/communes/${INSEEC}/indices/atmo?api_token=${APIKEY}&date_echeance=now"
AUJ=$(date +%Y-%m-%d)

JSON=$(curl -L -s --connect-timeout 5 $URL) || CURL_RETURN_CODE=$?

if [[ ${CURL_RETURN_CODE} -ne 0 ]]; then
        echo "[qualiteAirAPI] Erreur de connexion, verifiez l'URL. Code de retour cURL=${CURL_RETURN_CODE} (https://bit.ly/curlerr)";
        exit 1
fi

if [[ "${JSON}" =~ (bad_token|INSUFFICIENT_ROLE) ]]; then
        echo -e "[qualiteAirAPI] Erreur de token/role, verifiez la variable APIKEY. Retour :\n\n ${JSON}"; exit 1
fi

QUALITE2AIR=$(echo "$JSON"      | jq --arg jqAuj "$AUJ" -r '.data | map(select(.date_echeance == $jqAuj)) | .[] | .qualificatif')
INDICEAIR=$(echo "$JSON"        | jq -r '.data[] .indice')

# On selectionne le polluant majoritaire, puis ses caracteristiques : indice, concentration
POLMAJO_NOM=$(echo "$JSON"      | jq -r '.data[] .polluants_majoritaires[0]')
POLMAJO_INDICE=$(echo "$JSON"   | jq --arg jqPollMaj "$POLMAJO_NOM" -r '.data[] | .sous_indices | map(select(.polluant_nom == $jqPollMaj)) | .[] .indice')
POLMAJO_CONCTR=$(echo "$JSON"   | jq --arg jqPollMaj "$POLMAJO_NOM" -r '.data[] | .sous_indices | map(select(.polluant_nom == $jqPollMaj)) | .[] .concentration | tonumber | floor')

# si appel du script avec 1 argument (comme "brut") alors on retourne juste le %
if [[ $# -eq "1" ]]; then
        echo ${POLMAJO_CONCTR}
        exit 0
fi

# En cas de pollution importante >=  4 on met en MAJUSCULES -- Echelle de 1 à 6 (mauvais) https://api.atmo-aura.fr/api/v1/indices/atmo/definitions?api_token=${APIKEY}
if [[ "${INDICE}" -ge "4" ]]; then
        QUALITE2AIR=$(echo $QUALITE2AIR | awk '{print(toupper($0))}')
fi

echo  "Air ${QUALITE2AIR} (${INDICEAIR}/6). Major: ${POLMAJO_NOM} (${POLMAJO_INDICE}/6 via API)"

exit 0