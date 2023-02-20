#!/bin/bash
###########################################
# Backup a Raspberry Pi to CIFS share
###########################################
# auteur : Mr Xhark (blogmotion.fr)
# source : http://blogmotion.fr/systeme/script-backup-rpi-partage-15977
VERSION="2022.09.18"
# licence type	: Creative Commons Attribution-NoDerivatives 4.0 (International)
# licence info	: http://creativecommons.org/licenses/by-nd/4.0/
###########################################

# Si erreur "mount error(95): Operation not supported Refer to the mount.cifs(8) manual page (e.g. man mount.cifs)"
# Activez SMB 2.0 minimum dans DSM > Pann. de conf. > Service de fichiers > SMB/AFP/NFS > Parametres Avances
# 	Protocole maximum = 3.0
# 	Protocole minimum = 2.0

# VARIABLES MODIFIABLES###############################################################
PARTAGE="//synology/partage/dossier"
PARTAGEMNT="/mnt/cifs/synology"
PARTAGENAME="CIFS NAS Synology" # commentaire pour l'affichage
USERNAME="identifiant"
PASSWORD="motdepasse"

# Fichier(s) ou Dossier(s) a sauvegarder (un element par ligne)
TOBACKUP="
/boot/*.txt
/etc/cron.daily
/etc/cron.hourly
/etc/cron.monthly
/etc/fstab
/etc/init.d
/etc/network/interfaces
/etc/modules
/etc/modprobe.d/
/etc/ssh/sshd_config
/etc/udev
/etc/wpa_supplicant
/home/pi
/root/*.sh*
/root/.bash*
/root/bash_xhark
/var/www
/tmp/crontab
"

# Fichier(s) ou Dossier(s) a exclure du backup (un element par ligne)
TOEXCLUDE="
/home/pi/Desktop
/home/pi/motion
/home/pi/photos
/home/pi/homebridge
/home/pi/.node-*
/home/pi/domoticz/backups/daily
"

### FIN DES VARIABLES MODIFIABLES #####################################################



# __________________ NE RIEN MODIFIER SOUS CETTE LIGNE __________________ #

TOBACKUPFILE="/tmp/tobackup.tmp.txt"
TOEXCLUDEFILE="/tmp/toexclude.tmp.txt"
TMPCRONTAB="/tmp/crontab"

# lecture version de TAR
TARINFO=$(tar --version | head -1)
DELIM="tar (GNU tar) "
TARVERSION=${TARINFO#*$DELIM}

DATE=$(date +%Y-%m-%d_%Hh%M)
YYYY=$(date +%Y)
TAR=$(hostname -s)"-${DATE}.tar.gz"

ipserver=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
locpath=$(dirname "${BASH_SOURCE[0]}") 	# chemin vers le script
scriptpath=$(basename $0)				# script.sh

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

rouge=$(	tput setaf 1)
vert=$(		tput setaf 2)
jaune=$(	tput setaf 3)
bleu=$(		tput setaf 4)
violet=$(	tput setaf 5)
cyan=$(		tput setaf 6)
gris=$(		tput setaf 7)

# Fonctions ##########################################################################
shw_norm () { echo -en "${bold}$(tput setaf 9)${@}${reset}";	}
shw_info () { echo -en "${bold}${cyan}${@}${reset}";			}
shw_OK ()   { echo -en "${bold}${vert}OK!${@}${reset}";			}
shw_warn () { echo -en "${bold}${violet}${@}${reset}";			}
shw_err ()  { echo -en "${bold}${rouge}${@}${reset}";			}
gris() 	    { echo -en "${bold}${gris}${@}${reset}";			}
header()    { echo -e "${bold}${jaune}$*${reset}";				}
headerU()   { echo -e "${underline}${bold}${jaune}$*${reset}";  }

# Compare:  $1>= $2 alors Retourne 0, sinon retourne 1 -- https://stackoverflow.com/a/4024263/6357587 (ou alternative avec vk3: https://stackoverflow.com/a/48998537/6357587)
verMinimale() { 
	[ "$1" = "$2" ] && return 0 || [ "$1" = "$(echo -e "$1\n$2" | sort -rV | head -n1 | grep $1)"
}
# FIN DES FONCTIONS ##################################################################


# DEBUT DU SCRIPT ####################################################################

clear && echo -e "\n\n"
header  "****************************************************************************"
header  "***   bm-PiBackup by @xhark - Creative Commons BY-ND 4.0 (v${VERSION})   ***"
headerU "****************************************************************************"

shw_info "\n\n=== Demarrage sauvegarde Raspberry Pi le $(date +'%d/%m/%Y a %Hh%M'):\n\n"

# Vérification execution en tant que 'root'
shw_norm "\t::: execution en tant que root... "
if [[ $EUID -ne 0 ]]; then
	sudo "$0" "$@" || (shw_err "Ce script doit être executé avec les droits 'root'. Arrêt du script.\n" ; exit 1)
else
	shw_OK
fi

# controle montage
shw_norm "\n\t::: verification du partage ($PARTAGENAME)... "
if grep -qs $PARTAGEMNT /proc/mounts; then
	shw_OK
else
	# creation point montage si non present
	[ -d $PARTAGEMNT ] || mkdir -p $PARTAGEMNT
	# montage du partage syno
	mount.cifs $PARTAGE $PARTAGEMNT -o user=${USERNAME},pass="${PASSWORD},vers=2.0" && shw_OK
	if [[ $? -ne 0 ]]; then
		shw_err "\n\t ERREUR: montage impossible de $PARTAGE -- Arrêt du script \n"
		exit 1
	fi
fi

# Sauvegarde listing cron
for user in $(cut -f1 -d: /etc/passwd); do echo -e "\n\n==> $user:" ; crontab -u $user -l ;  done > $TMPCRONTAB 2>&1

# Creation du repertoire de destination s'il n'existe pas
if [[ ! -d "${PARTAGEMNT}/${YYYY}" ]]; then
	mkdir -p "${PARTAGEMNT}/${YYYY}" || (shw_err "\n\t ERREUR: mkdir YYYY impossible"; exit 1)
fi

cd $PARTAGEMNT || (shw_err "\n\t ERREUR: cd impossible"; exit 1)

# envoie des listings en fichier texte en preservant les sauts de ligne
printf "%s\n" $TOBACKUP > $TOBACKUPFILE
printf "%s\n" $TOEXCLUDE > $TOEXCLUDEFILE

shw_norm "\n\t::: creation de l'archive ${TAR}... "

# si version de TAR >= 1.30 (https://bit.ly/tar-options)
if verMinimale $TARVERSION "1.30"; then
	tar zcf "$TAR" 		\
		--exclude-from="$TOEXCLUDEFILE" \
		--files-from="$TOBACKUPFILE"	\
		> /dev/null 2>&1
else
	tar --exclude-from="$TOEXCLUDEFILE" \
		zcf "$TAR" --files-from="$TOBACKUPFILE" \
		> /dev/null 2>&1
fi

tarsize=$(du -sh "$TAR")

if [[ $? -ne 0 ]]; then
	shw_err "\n\t ERREUR: impossible de creer l'archive $TAR \n"
	umount -l $PARTAGEMNT && shw_warn "\n\t demontage du partage et stop du script!"
	exit 1
fi
shw_OK

# démontage
shw_norm "\n\t::: demontage partage... "
if umount -l $PARTAGEMNT; then
        shw_OK
else
	shw_err "IMPOSSIBLE!"
fi

gris "\n\n\t=> Taille du backup: $tarsize"

shw_info "\n\n=== Fin du Backup le $(date +'%d/%m/%Y a %Hh%M')"
shw_info "\n=== ce script tourne depuis ${ipserver}:${locpath}/${scriptpath}\n\n"

# Nettoyage des fichiers temporaires
rm -f "$TMPCRONTAB" "$TOBACKUPFILE" "$TOEXCLUDEFILE"

exit 0
