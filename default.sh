#!/bin/bash

# env
VAR="123"
DAY=`date "+%Y%m%d_%H%M%S"`
DAY=$(date "+%Y%m%d_%H%M%S")

# FUNCTION. return code is result of last list.
test () {
	echo test
}
test

# SUB SHELL. return code is result of this shell.
( cat /etc/os-release | grep -i "PATTERN")

(
	cat /etc/os-release | grep -i "PATTERN"
)

# GROUP COMMAND. retrun code is result of command.
{ cat /etc/os-release | grep -i "PATTERN" }

{
	cat /etc/os-release | grep -i "PATTERN"
}

# IF
## General condition
if [ $1 -eq 1 ]; then
  echo 1
elif [ $1 -eq 2]; then
  echo 2
else
  echo "not 1 and 2"
fi

## OR
if [[ $i -e 1 ]] || [[ $i -e 2 ]]; then
  echo "i is not 1 and 2"
fi

## AND
if [[ $i = test ]] && [[ $i = message ]]; then
  echo "i includes test and message"
fi

if [[ $i =~ test ]] && [[ $i =~ message ]]; then
  echo "i includes test and message"
fi

case $1 in
  start)
    echo 'start'
    ;;
  stop)
    echo 'stop'
    ;;
  *)
    echo 'etc'
    ;;
esac
















