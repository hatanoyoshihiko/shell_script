#/bin/bash

DB_USER=zabbix
DB_PASSWORD=zabbix

mysql -u $DB_USER -p$DB_PASSWORD -N -e 'USE zabbix; SHOW TABLES;' | xargs -I {} mysql -u $DB_USER -p$DB_PASSWORD -e 'use zabbix; ALTER TABLE {} ENGINE=INNODB;'


