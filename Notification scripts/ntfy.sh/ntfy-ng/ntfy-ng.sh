#!/bin/bash
###################################################################
# ntfy-ng.sh (new generation)
# Push notification via ntfy.sh (public or private server)
# This scripts sends a notification to a ntfy topic
# If no arguments : send to the default topic
###################################################################
# author : Mr Xhark - twitter.com/xhark
# source : https://blogmotion.fr/
# licence : Creative Commons Attribution-NoDerivatives 4.0 (International)
#         : https://creativecommons.org/licenses/by-nd/4.0/
###################################################################

VERSION="2023.02.21"

#==============================================================
# VARIABLES

DEFAULTSERVER="https://ntfy.sh:443"
# Credentials (DEFAULTCREDS="login:pwd")
DEFAULTCREDS=""
# Topic name (public, be careful!)
DEFAULTTOPIC="blogmotion_ntfy_demo" 
DEFAULTMESSAGE="ceci est une notification via ntfy par défaut"
DEFAULTTAGS="o" # https://docs.ntfy.sh/publish/#tags-emojis
DEFAULTPRIO="3" # https://docs.ntfy.sh/publish/#message-priority

# DO NOT TOUCH ANYTHING FROM THIS LINE ############################
RUNDIR="$( cd "$( dirname "$0" )" && pwd -P )"
LOGENABLED=true
LOGFILE="${RUNDIR}/ntfy.log"
DATELIVE=$(date '+%d/%m/%Y %H:%M:%S')

#==============================================================
# FONCTIONS

function usage() {
  echo "
Usage :
  `basename $0` [-s (default=ntfy.sh)] [-u mylogin:Passw0rd] [-o] [-m] [-p <1-5 (default=3)>] [-t (default=o)] 

Options :
  -s --server         ntfy server
  -u --user           user:password
  -o --topic          topic name
  -m --message        message
  -p --priority       priority 1 to 5 (higher)
  -t --tag --tags     tag (emoji)
  -h --help    	      prints this help and exit
  
e.g:
ntfy-ng.sh \"Voici un message\"
ntfy-ng.sh --message \"Voici un message\"
ntfy-ng.sh --topic \"topic_name\" --message \"Voici un message\"
ntfy-ng.sh --topic \"topic_name\" --message \"Voici un message\"  --tags chart_with_downwards_trend,money_mouth_face --prio 5
"
  exit 3
}

# Check the number of arguments
if [ $# -eq 0 ] ; then
  usage
elif [ $# -eq 1 ]; then
  MESSAGE=$1
fi

function sendNtfy() {
  echo -e "\t\n---start---\n[${TOPIC}] ${MESSAGE}\n---end---\n"

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
    -h|--help)
	usage
	;;
    *)    # tout autre argument
	shift # passer au prochain argument
	;;
  esac
done

# traitement de ces variables, sinon récupération de la valeur par defaut en haut du script:
SERVER=${SERVER:-$DEFAULTSERVER}
TOPIC=${TOPIC:-$DEFAULTTOPIC}
MESSAGE=${MESSAGE:-$DEFAULTMESSAGE}
TAGS=${TAGS:-$DEFAULTTAGS} 		# https://docs.ntfy.sh/publish/#tags-emojis
PRIO=${PRIO:-$DEFAULTPRIO} 		# https://docs.ntfy.sh/publish/#message-priority
[ -z "$DEFAULTCREDS" ] && CREDS='' || CREDS="-u ${DEFAULTCREDS}"

sendNtfy