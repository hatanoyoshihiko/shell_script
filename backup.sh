#!/bin/bash

# VARIABLES
DAY=`date +%Y-%m-%d`
BK_DIR="/data/backup/pi/${DAY}"
COUNT_DIR=/data/backup/pi
LOG_DIR=/var/log/backup
LOG_OUT="${LOG_DIR}/stdout.log"
LOG_ERR="${LOG_DIR}/stderr.log"
DIR_COUNT=`ls /data/backup/pi | wc -l`
MAIL_FROM="pi@zabbix01.alessiareya.local"
MAIL_TO="hatanoyoshihiko@gmail.com"
SCRIPT_FILES="backup.sh ufw.sh zabbix_defrag.sh"
LDAP_HOST="localhost"
LDAP_PASSWD=""
LDAP_BIND="dc=alessiareya,dc=local"
LDAP_DN="cn=admin,dc=alessiareya,dc=local"
DB_HOST="localhost"
DB_USER="root"
DB_PASSWD=""
ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf"
ZABBIX_HOST=127.0.0.1
ZABBIX_PORT=10051
ZABBIX_URL="https://zabbix01.alessiareya.local/zabbix"
#set -eu

# FUNCTION DEFENITION
func_notice_success() {
        echo -e "BACKUP SUCCEEDED" "\n" \
	"$ZABBIX_URL" | \
	mail -r $MAIL_FROM -s "BACKUP SUCCESS" $MAIL_TO
}

func_notice_fail() {
        echo -e "BACKUP ERROR OCCURED" "\n" \
	"$ZABBIX_URL" | \
	mail -r $MAIL_FROM -s "BACKUP ERROR" $MAIL_TO
}

func_log() {
	truncate $LOG_OUT --size 0
	truncate $LOG_ERR --size 0
	echo $DAY >> $LOG_OUT
	echo $DAY >> $LOG_ERR
	exec 1>>$LOG_OUT
	exec 2>>$LOG_ERR
}

func_mk_bkdir() {
	mkdir -p $BK_DIR
	mkdir -p $LOG_DIR
	if
		[[ -f "${LOG_DIR}/{stdout.log,stderr.log}" ]] ; then
		:
	else
		touch "${LOG_DIR}/{stdout.log,stderr.log}"
	fi
}

func_db_buckup() {
	mysqldump -u$DB_USER -p$DB_PASSWD -h $DB_HOST -A \
		--single-transaction
		--default-character-set=utf8mb4
		--skip-dump-date -r | \
	gzip > "${BK_DIR}/mysqldump.sql.gz"
}

func_ldap_backup() {
	ldapsearch -x -LLL -H ldap://$LDAP_HOST \
	-b $LDAP_BIND \
	-D $LDAP_DN \
	-w $LDAP_PASSWD > "${BK_DIR}/dit.ldif"
}

func_conf_buckup() {
	tar -zcf "${BK_DIR}/postfix.tar.gz" -C /etc postfix
	tar -zcf "${BK_DIR}/zabbix.tar.gz" -C /etc zabbix
	tar -zcf "${BK_DIR}/script.tar.gz" -C /usr/local/sbin/ $SCRIPT_FILES
	tar -zcf "${BK_DIR}/rsyslog.tar.gz" -C /etc rsyslog.conf rsyslog.d
	tar -zcf "${BK_DIR}/named.tar.gz" -C /etc bind
	tar -zcf "${BK_DIR}/freeradius.tar.gz" -C /etc freeradius
	tar -zcf "${BK_DIR}/easy-rsa.tar.gz" -C /root easy-rsa
	tar -zcf "${BK_DIR}/ssl.tar.gz" -C /root ssl
	tar -zcf "${BK_DIR}/eap.tar.gz" -C /root eap
	tar -zcf "${BK_DIR}/openldap.tar.gz" -C /root openldap
	tar -zcf "${BK_DIR}/squid.tar.gz" -C /etc squid
	tar -zcf "${BK_DIR}/mysql.tar.gz" -C /etc mysql
	tar -zcf "${BK_DIR}/logrotate.conf.tar.gz" /etc/logrotate.conf
	tar -zcf "${BK_DIR}/sysctl.tar.gz" -C /etc sysctl.d
	cp -p /etc/netplan/50-cloud-init.yaml "${BK_DIR}"/
}

func_archive_rotation() {
	if [ $DIR_COUNT -ge 30 ] ; then
	        find $COUNT_DIR -type d -daystart -mtime +29 | xargs rm -rf
	elif [ $DIR_COUNT -lt 30 ] ; then
		:
	fi
}

func_zabbix_sender() {
	count=$(ps aux | grep -c [z]abbix_agentd)
	if [ $count -gt 0 ] ; then
		zabbix_sender -vv -c $ZABBIX_CONF -s $ZABBIX_HOST -p $ZABBIX_PORT -k script.result -o $FUNC_MAIN_RC
	else
		:
	fi
}

func_main() {
	func_log
	func_mk_bkdir
	func_db_buckup
	func_ldap_backup
	func_conf_buckup
	func_archive_rotation
}

# MAIN PROCESSING
func_main
FUNC_MAIN_RC=$?

if [ $FUNC_MAIN_RC == 0 ] ; then
	func_zabbix_sender
#	func_zabbix_sender && func_notice_success
else
	func_zabbix_sender && func_notice_fail
fi
