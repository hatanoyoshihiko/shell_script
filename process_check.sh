#!/bin/bash

SERVICE="httpd.service"

while true; do
  HTTPD_CHECK=`ps aux | grep httpd | grep -v grep -c`

  if [ ${HTTPD_CHECK} = 0 ]; then
    systemctl start httpd.service && echo "${SERVICE} is started"
    HTTPD_STATUS=$?

    case ${HTTPD_STATUS} in
      "0")
        :
        ;;
      "1")
        { /sbin/httpd -t 2>&1 | grep -i "syntax error"; } > /dev/null 2>&1
        CONFIG_STATUS=$?

        if [ ${CONFIG_STATUS} = 0 ]; then
          echo "Please Check httpd.conf"
          exit 0
        elif [ ${CONFIG_STATUS} = 1 ]; then
          systemctl start httpd.service > /dev/null 2>&1
          echo "${SERVICE} is alived."
          sleep 5
        else
          echo "Please Check error_log."
          exit 0
        fi
        ;;
    esac
  elif [ ${HTTPD_CHECK} > 0 ]; then
    echo "${SERVICE} is alived"
    sleep 5
  else
    :
  fi
done
