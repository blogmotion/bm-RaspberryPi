#!/bin/bash
# tempUpdate.sh : met à jour 2 variables utilisateur en ne gardant que la temperature sans l'humidité
#
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr
VERSION="2016.08.15"

# === NOM DES VARIABLES UTILISATEURS (UserVariables)===============================================
VU_INT='tempInt'
VU_EXT='tempExt'

# === IDX SONDES BANGGOOD =========================================================================
ID_INT=1098
ID_EXT=1100

# === LECTURE DES TEMPERATURES ====================================================================
T_INT=`curl -s "http://localhost:8080/json.htm?type=devices&rid=$ID_INT" | jq -r .result[]."Data" | cut -d' ' -f1`
T_EXT=`curl -s "http://localhost:8080/json.htm?type=devices&rid=$ID_EXT" | jq -r .result[]."Data" | cut -d' ' -f1`

# === INJECTION DANS LES VARIABLES UTILISATEURS ==================================================
echo -e "\nInjection Temperature INT ($T_INT):" && curl -s "http://localhost:8080/json.htm?type=command&param=updateuservariable&vname=$VU_INT&vtype=1&vvalue=$T_INT" # Temp INT
echo -e "\nInjection Temperature EXT ($T_EXT):" && curl -s "http://localhost:8080/json.htm?type=command&param=updateuservariable&vname=$VU_EXT&vtype=1&vvalue=$T_EXT" # Temp EXT

echo -e "\n\n\tFin du script - `date` - v$VERSION\n"
exit 0
