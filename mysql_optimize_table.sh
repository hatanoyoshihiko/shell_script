#!/bin/bash

# MySQL接続情報
DB_HOST="localhost"
DB_USER="root"
DB_PASS="root"
DB_NAME="zabbix"
TAG="zabbix-maintenance"

log_info() {
  logger -t "$TAG" "$1"
}

log_info "Started maintenance on database: $DB_NAME"

# 全テーブル名の取得
tables=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -Bse "SHOW TABLES;")

# 各テーブルに対してOPTIMIZE TABLEを実行
for table in $tables; do
  log_info "Analyzing table: $table"
  result=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "ANALYZE TABLE \`$table\`;")
  log_info "$result"
done

log_info "Maintenance completed on database: $DB_NAME"