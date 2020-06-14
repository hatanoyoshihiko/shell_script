#!/bin/bash

if [ $# -ne 1 ]; then
  echo "ARGUMENT ERROR"
  exit
fi

CNT=0
cat $1 | \
while read LINE
do
  CNT=`expr $CNT + 1`
  echo "${CNT} :${LINE}"
done
