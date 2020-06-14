#!/bin/bash

PROGNAME=$(basename $0)

# DEFAULT VARIABLE

SRC_DIR="/data/"
DEST_USER="root"
DEST_HOST="192.168.10.151"
DEST_DIR="/data/"
RSYNC_OPTION="-az --delete"
KEY="NO"
KEY_FILE="~/.ssh/id_rsa"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
LOG_FILE="log_${TIMESTAMP}.log"
SHA512="NO"
SHA512_FILE="sha_${TIMESTAMP}.log"
MD5="NO"
MD5_FILE="md5_${TIMESTAMP}.log"
FIND_EXCLUDE="-not -type b -not -type c -not -type p"

# UTILITIES

debugprint() {
	# JUST SHOW SOME VALUES
	cat <<"EOF"
STATE:

SRC_DIR      : $SRC_DIR
DEST_DIR     : $DEST_DIR
DEST_USER    : $DEST_USER
DEST_HOST    : $DEST_HOST
RSTNC_OPTION : $RSYNC_OPTION
KEY          : $KEY
KEY_FILE     : $KEY_FILE

CHECK:

MD5          : $MD5
SHA512       : $SHA512
MD5_FILE     : $MD5_FILE
SHA512_FILE  : $SHA512_FILE

EOF
}

usage() {
	cat <<"EOF"
Usage $PROGNAME [-s|--src-dir SRC_DIR] [-u|--user|--dest-user USER] [-d|--dest-dir DEST_DIR] [--host|--dest-host DEST_HOST] [-r|--rsync-opt RSYNC_OPT] [--sha] [--sha-file FILE] [--md5] [--md5-file FILE] [-k|--ssh-key KEY]
      $PROGNAME [-h|--help|-v|--version]

VARIABLE OPTION

-s | --src-dir SRC_DIR
	specify the source directory
-d | --dest-dir DEST_DIR
	specify the destination directory
-u | --user|--dest-user USER
	specfy the user of destination host
-host | --dest-host DEST_HOST
	specity the destination host
-r | --rsync-opt RSYNC_OPTION
	specify RSYNC's options : YOU MUST USE QUOTE IF IT HAS SPACE
-k | --ssh-key KEY
	specify KEY of ssh

HELP OPTION

-h | -help | -v | --version
	show this help and quit

CHECK OPTION

--sha | --md5 | --both | --none
	check data by sha512, md5 : THIS REQUIRE sha512sum/md5sum command on LOCAL and DEST_HOST. If not, chose --none to check by rerunning rsync
--sha-file FILE | --md5-file FILE
        the same check above except reusing FILE as check sum of LOCAL

EOF
exit 0
}

echo "--- reading options... ---"

for OPT in "$@"
do
	case "$OPT" in
		'-h'|'--help'|'-v'|'--version')
			usage
			exit 0
			;;
		'--md5')
			MD5="YES"
			shift 1
			;;
		'--sha'|'--sha512')
			SHA512="YES"
			shift 1
			;;
		'--both')
			SHA512="YES"
			MD5="YES"
			shift 1
			;;
		'--none')
			SHA512="NO"
			MD5="NO"
			shift 1
			;;
		'--md5-file')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			if [[ ! -r "$2" ]] ; then
				echo "FILE : $2 must be readble"
				exit 1
			fi
			MD5="YES"
			MD5_FILE="$2"
			shift 2
			;;
		'--sha-file'|'--sha512-file')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			if [[ ! -r "$2" ]] ; then
				echo "FILE : $2 must be readble"
				exit 1
			fi
			SHA512="YES"
			SHA512_FILE="$2"
			shift 1
			;;
		'-k'|'--ssh-key')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			KEY="YES"
			KEY_FILE="$2"
			shift 2
			;;
		'-s'|'--src-dir')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			SRC_DIR="$2"
			shift 2
			;;
		'-u'|'--user'|'--dest-user')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			DEST_USER="$2"
			shift 2
			;;
		'-d'|'--dest-dir')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			DEST_DIR="$2"
			shift 2
			;;
		'-r'|'--rsync-opt')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			RSYNC_OPTION="$2"
			shift 2
			;;
		'--host'|'--dest-host')
			if [[ -z "$2" ]] ; then
				echo "$PROGNAME : option $1 require one more argument "
				exit 1
			fi
			DEST_HOST="$2"
			shift 2
			;;
	esac
done

echo "--- reading options is completed ---"
debugprint

# CHECK

if [[ ! -d "${SRC_DIR}" ]] ; then
	echo "SRC_DIR : ${SRC_DIR} must be exist and be directory"
	exit 2
fi

if [[ "$MD5" = "YES" ]] ; then
	echo "--- md5sum cache file is required ---"
	if [[ ! -r "$MD5_FILE" ]] ; then
		echo "--- making md5sum cache file"
		find "${SRC_DIR}" -type f ${FIND_EXCLUDE} | xargs -n 1 md5sum > "$MD5_FILE"
	fi
fi

if [[ "$SHA512" = "YES" ]] ; then
	echo "--- sha512 cache file is required ---"
	if [[ ! -r "$SHA512_FILE" ]] ; then
		echo "--- makng sha512 cache file"
		find "${SRC_DIR}" -type f ${FIND_EXCLUDE} | xargs -n 1 sha512sum > "$SHA512_FILE"
	fi
fi

# RUN RSYNC
rsync ${RSYNC_OPTION} --log-file="${LOG_FILE}" "${SRC_DIR}" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}"

# CHECK SEND DATA

if [[ "$MD5" = "YES" ]] ; then
	echo "--- check files with md5 cache ---"
	if [[ "$KEY" = "YES" ]] ; then
		scp -i "${KEY_FILE}" "${MD5_FILE}" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}${MD5_FILE}" > /dev/null
		ssh -i "${KEY_FILE}" "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; md5sum -c ${MD5_FILE} > /dev/null"
		CHECKSUM_RESULT=$?
	else
		scp "${MD5_FILE}" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}${MD5_FILE}" > /dev/null
		ssh "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; md5sum -c ${MD5_FILE} > /dev/null"
		CHECKSUM_RESULT=$?
	fi
fi
if [[ "$SHA512" = "YES" ]] ; then
	echo "--- check files with sha512 cache ---"
	if [[ "$KEY" = "YES" ]] ; then
		scp -i "${KEY_FILE}" "${SHA512_FILE}" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}${SHA512_FILE}" > /dev/null
		ssh -i "${KEY_FILE}" "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; sha512sum -c ${SHA512_FILE} > /dev/null"
		CHECKSUM_RESULT=$?
	else
		scp "${SHA512_FILE}" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}/${SHA512_FILE}" > /dev/null
		ssh "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; sha512sum -c ${SHA512_FILE} > /dev/null"
		CHECKSUM_RESULT=$?
	fi
fi
if [[ "$MD5" = "NO" ]] && [[ "$SHA512" = "NO" ]] ; then
	echo "--- run rsync again to check ---"
	rsync ${RSYNC_OPTION} "${SRC_DIR}" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}"
fi

# CHECKSUM RESULT CHECK
if [ ${CHECKSUM_RESULT} = 0 ] ; then
  echo "SRC DIR and DEST DIR checksum is same"
  exit 0
else
  if [[ "$MD5" = "YES" ]] ; then
    echo "Output checksum difference."
      if [[ "$KEY" = "YES" ]] ; then
        ssh -i "${KEY_FILE}" "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; cd .. ; md5sum -c ${DEST_DIR}${MD5_FILE} | grep -i failed"
      else
        ssh "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; cd .. ; md5sum -c ${DEST_DIR}${MD5_FILE} | grep -i failed"
      fi
  elif [[ "$SHA512" = "YES" ]] ; then
    echo "Output checksum difference."
      if [[ "$KEY" = "YES" ]] ; then
	ssh -i "${KEY_FILE}" "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; cd .. ; sha512sum -c ${DEST_DIR}${SHA512_FILE} | grep -i failed"
      else
   	ssh "${DEST_USER}@${DEST_HOST}" "cd ${DEST_DIR} ; cd .. ; sha512sum -c ${DEST_DIR}${SHA512_FILE} | grep -i failed"
      fi
  else
    :
  fi
fi
