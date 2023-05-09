#!/bin/bash
###################################################################
# ntfy-ng-withconf.sh (new generation, with configuration file)
# Push notification via ntfy.sh (public or private server)
# This scripts sends a notification to a ntfy topic
# If no arguments : send to the default topic
###################################################################
# author : Mr Xhark - twitter.com/xhark
# source : https://blogmotion.fr/
# licence : Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
#         : https://creativecommons.org/licenses/by-nc-sa/4.0/
###################################################################

VERSION="2023.02.21"

# DO NOT TOUCH ANYTHING FROM THIS LINE ############################

#==============================================================
# VARIABLES

RUNDIR="$( cd "$( dirname "$0" )" && pwd -P )"
DEFAULTCONF="ntfy.cfg"
LOGENABLED=true
DEBUG=true
LOGFILE="${RUNDIR}/ntfy.log"
DATELIVE=$(date '+%d/%m/%Y %H:%M:%S')

#==============================================================
# FONCTIONS

function usage() {
  echo "
Usage :
  `basename $0` [-c] [-s] [-o] [-m] [-p <1-5 (default=3)>] [-t (default=o)] [-u mylogin:Passw0rd] [-s (default=ntfy.sh)]

Options :
  -c --config         config file (default=ntfy.cfg)
  -s --server         ntfy server
  -u --user           user:password
  -o --topic          topic name
  -m --message        message
  -p --priority       priority 1 to 5 (higher)
  -t --tag --tags     tag (emoji)
  -h --help    	      prints this help and exit

E.g:
ntfy-ng-withconf.sh \"Voici un message\"
ntfy-ng-withconf.sh --message \"Voici un message\"
ntfy-ng-withconf.sh --topic \"nom_du_topic\" --message \"Voici un message\"
ntfy-ng-withconf.sh --topic \"nom_du_topic\" --message \"Voici un message\"  --tags chart_with_downwards_trend,money_mouth_face --prio 5

With specific config file:
ntfy-ng-withconf.sh --config \"custom.cfg\" --topic \"nom_du_topic\" --message \"Voici un message\"  --tags chart_with_downwards_trend,money_mouth_face --prio 5
"
  exit 3
}


function read_config {
   local CONF_FILE="${RUNDIR}/$1"
   if [ -f "$CONF_FILE" ]; then
       source "$CONF_FILE"
   else
       echo "Configuration file cannot be found: $CONF_FILE" && exit 1
   fi
}

function sendNtfy() {
  echo -e "\t\n---start---\n[${TOPIC}] ${MESSAGE}\n---end---\n"

  if [ ${DEBUG} = true ]; then
    echo curl $CREDS -d "le ${DATELIVE}" -H "Title: ${MESSAGE}" -H "Priority: ${PRIO}" -H "Tags: ${TAGS}" ${SERVER}/${TOPIC}
  fi

  # https://docs.ntfy.sh/examples/ and https://docs.ntfy.sh/publish/
  curl \
      $CREDS \
      -d "le ${DATELIVE}" \
      -H "Title: ${MESSAGE}" \
      -H "Priority: ${PRIO}" \
      -H "Tags: ${TAGS}" \
      ${SERVER}/${TOPIC}

  RETVALUE=$?

  # Log
  if [[ ${RETVALUE} -eq 0 && ${LOGENABLED} = true ]]; then
    DATE=$(date +"%x-%X")
    ONELINEMESSAGE=$(echo ${MESSAGE} | tr "\\r\\n" " ")
    echo "${DATE};${TOPIC};${ONELINEMESSAGE}" >> ${LOGFILE}
  fi
  return ${RETVALUE}
}

#==============================================================

# Compte le nombre d'arguments
if [ $# -eq 0 ] ; then
  usage
elif [ $# -eq 1 ]; then
  MESSAGE=$1
fi

# Lecture des arguments explicites
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -s|--server)
	SERVER="$2"; shift 2
	;;
    -o|--topic)
    	TOPIC="$2"; shift 2
	;;
    -m|--message)
	MESSAGE="$2"; shift 2
	;;
    -p|--prio|--priority)
	# Priorite : 1(min), 2(low), 3(default), 4(high),5 (urgent)
	PRIO="$2"; shift 2
	;;
    -t|--tag|--tags)
	# Separer par virgules si plusieurs
	TAGS="$2"; shift 2
	;;
    -u|--user|--login)
	CREDS="$2"; shift 2
	;;
    -c|--config)
	CONF_FILE="$2"; shift 2
	;;
    -h|--help)
	usage
	;;
    *)   # tout autre argument
	shift # passer au prochain argument
	;;
  esac
done

# lecture fichier de conf en parametre, sinon lecture ntfy.cfg
CONF_FILE=${CONF_FILE:-$DEFAULTCONF}

# lecture fichier de configuration
read_config "$CONF_FILE"

# traitement de ces variables passees en argument, sinon lecture depuis le fichier de conf (surcharge)
SERVER=${SERVER:-$DEFAULTSERVER}
TOPIC=${TOPIC:-$DEFAULTTOPIC}
MESSAGE=${MESSAGE:-$DEFAULTMESSAGE}
TAGS=${TAGS:-$DEFAULTTAGS} 		# https://docs.ntfy.sh/publish/#tags-emojis
PRIO=${PRIO:-$DEFAULTPRIO} 		# https://docs.ntfy.sh/publish/#message-priority
CREDS=${CREDS:-$DEFAULTCREDS}
[ -z "$CREDS" ] && CREDS='' || CREDS="-u ${CREDS}"

sendNtfy