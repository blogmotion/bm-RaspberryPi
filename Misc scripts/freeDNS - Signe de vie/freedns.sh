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
VERSION="2021.12.23"

# === INFORMATIONS FREEDNS (MODIFIEZ CES VARIABLES !) :

# Identifiants FreeDNS, identiques à https://freedns.afraid.org/subdomain/
USERNAME='identifiant'
PASSWORD='VotreMot2Passe'

# (sous) domaine FreeDNS lisible sur https://freedns.afraid.org/subdomain/ (ID="data_id" dans l'URL)
DOMAIN="monsous.domaine.fr"
DOMAIN_ID="12344321"

# === FIN DES VARIABLES - NE RIEN TOUCHER SOUS CETTE LIGNE ========================================================================

rouge=$(tput setaf 1)
vert=$( tput setaf 2)
cyan=$( tput setaf 6)
reset=$(tput sgr0)

shw_OK ()   { echo -e "${bold}${vert} OK! ${@}${reset}";}
shw_err ()  { echo -e "${bold}${rouge}${@}${reset}";	}
shw_info () { echo -e "${bold}${cyan}${@}${reset}";	}

COOKIE_FILE="`mktemp /tmp/freedns_cookie.XXXXXXXX`"
TXTID_FILE="`mktemp /tmp/freedns_txtid.XXXXXXXX`"

REGEX_DOMAINID="s/.*data_id=\\([0-9]*\\)>${DOMAIN}.*/\\1/;t;d"

shw_info "\n======= FreeDNS Signe de Vie v${VERSION} ========================================"
echo -n "Connexion au site freedns..."

curl -s "https://freedns.afraid.org/zc.php?step=2 " \
     -c ${COOKIE_FILE}                              \
     -d "action=auth"                               \
     -d "submit=Login"                              \
     -d "username=${USERNAME}"                      \
     -d "password=${PASSWORD}"                      \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:86.0) Gecko/20100101 Firefox/95.0" \
     && shw_OK

# DEBUG:
#curl -s "https://freedns.afraid.org/subdomain/" -b $COOKIE_FILE; exit

echo -n "Recherche de l'ID du domaine..."

DOM_READ_ID=$(curl -s "https://freedns.afraid.org/subdomain/" \
                   -b $COOKIE_FILE                            \
             | sed --posix $REGEX_DOMAINID)

if [ "$DOM_READ_ID" == "$DOMAIN_ID" ]; then
	shw_OK "(${DOM_READ_ID} = ${DOMAIN_ID})"
	EXITCODE=0
else
	shw_err " [ERREUR] ID INCORRECT:\n\t lu ${DOM_READ_ID} au lieu de l'ID attendu ${DOMAIN_ID}"
	EXITCODE=1
fi

rm -f ${COOKIE_FILE} ${TXTID_FILE}

echo && exit ${EXITCODE}