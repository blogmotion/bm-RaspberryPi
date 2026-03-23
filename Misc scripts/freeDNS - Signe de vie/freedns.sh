#!/bin/bash
# Ce script se connecte de façon automatique à freedns.afraid.org pour
# eviter que le compte devienne dormant (et desactive apres 6 mois)
# Une notification email de compte dormant est envoyee a 5 mois et 1/2
#
# Author: Mr Xhark -> @xhark
# License : Creative Commons (CC BY-ND 4.0) https://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : https://blogmotion.fr/systeme/freedns-afraid-script-connexion-automatique-19092
#
# Inspire de https://gist.github.com/AnthonyWharton/a0e8faae7195a5c1dea210466eda1c92
VERSION="2026.03.23"

# === INFORMATIONS FREEDNS, MODIFIEZ CES VARIABLES :

# Identifiants FreeDNS, identiques à https://freedns.afraid.org/subdomain/
USERNAME="identifiant"     #username ou email
PASSWORD="VotreMot2Passe"

# (sous) domaine FreeDNS lisible sur https://freedns.afraid.org/subdomain/ (ID="data_id" dans l'URL)
DOMAIN="monsous.domaine.fr"
DOMAIN_ID="12344321"

# === FIN DES VARIABLES MODIFIABLES - NE RIEN TOUCHER SOUS CETTE LIGNE ========================================================================

bold=$(tput bold)
rouge=$(tput setaf 1)
vert=$( tput setaf 2)
cyan=$( tput setaf 6)
reset=$(tput sgr0)

cleanAndExit() {
    local code="${1:-${EXITCODE:-0}}"
    rm -f "${COOKIE_FILE}" "${TXTID_FILE}"
    echo && exit "${code}"
}

shw_OK(){ echo -e "${bold}${vert} OK! " "$@" "${reset}"; }
shw_info(){ echo -e "${bold}${cyan}" "$@" "${reset}"; }
shw_err(){ echo -e "${bold}${rouge}" "$@" "${reset}"; cleanAndExit 1; }

COOKIE_FILE="$(mktemp /tmp/freedns_cookie.XXXXXXXX)"
TXTID_FILE="$(mktemp /tmp/freedns_txtid.XXXXXXXX)"
REGEX_DOMAINID="s/.*data_id=\\([0-9]*\\)>${DOMAIN}.*/\\1/;t;d"

shw_info "\n======= FreeDNS Signe de Vie v${VERSION} ========================================"
echo -n "Soumission du formulaire de connexion au site freedns.afraid.org..."

LOGIN_RESPONSE=$(curl -s "https://freedns.afraid.org/zc.php?step=2"	\
     -c "${COOKIE_FILE}"                              			\
     -d "action=auth"                               			\
     -d "submit=Login"                              			\
     -d "username=${USERNAME}"                      			\
     -d "password=${PASSWORD}"                      			\
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0")

if echo "$LOGIN_RESPONSE" | grep -q 'error</'; then
    shw_err "ERREUR : Échec de l'authentification (retentez plus tard si script lancé plusieurs fois)"
else
    shw_OK
fi

# DEBUG
#curl -s "https://freedns.afraid.org/subdomain/" -b $COOKIE_FILE > /tmp/debug.html ; exit

echo -e "Controle des informations:"
LOGGED_MEMBER_PAGE=$(curl -s "https://freedns.afraid.org/subdomain/" -b "${COOKIE_FILE}")

# Lecture et concordance de l'ID membre et ID du domaine
USER_ID=$(printf '%s' "$LOGGED_MEMBER_PAGE" | grep -Po 'UserID:</td><td bgcolor="#eeeeee" align="right">\K[^<]+(?=</td>)' || true)
DOM_READ_ID=$(printf '%s' "$LOGGED_MEMBER_PAGE" | sed --posix "${REGEX_DOMAINID}")

echo -n "-> Recherche du USERID..."
if [ "${USER_ID}" = "$USERNAME" ]; then
    shw_OK "(UserID=${USER_ID})"
else
    shw_err " ERREUR: UserID incorrect (lu=${USER_ID})"
fi

echo -n "-> Recherche de l'ID du domaine..."
if [ "${DOM_READ_ID}" = "${DOMAIN_ID}" ]; then
    shw_OK "(DomainID=${DOM_READ_ID})"
else
    shw_err " ERREUR: DomainID INCORRECT (ID lu=${DOM_READ_ID} au lieu de l'ID attendu=${DOMAIN_ID})"
fi

cleanAndExit