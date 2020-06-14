#!/bin/bash

## ENVIRONMENT VARIABLES
TARGET_DIR="/data/"

## ARG CHECK
if [ $# -ne 1 ]; then
  echo "ARGUMENT ERROR"
  exit
fi

## ATTENTION ARGUMENTS
## example ARG.txt
## username,OLDID,NEWID
## alessi,2000,3000

## UID CHANGE
read -p "##### Do you change UID? input \"y\" or \"n\" #####" yn
if [ $yn = y ]; then
  for i in `cat $1`
  do
    USERNAME=`echo $i | cut -d "," -f 1`
    OLD_UID=`echo $i | cut -d "," -f 2`
    NEW_UID=`echo $i | cut -d "," -f 3`
    mkdir -p ${USERNAME}
    find -P ${TARGET_DIR} -uid ${OLD_UID} -exec chown -h ${NEW_UID} {} \; -print | tee ${USERNAME}/${USERNAME}_change_uid.list &
    wait
  done
  echo "changed uid" && echo ""
elif [ $yn = n ]; then
  echo "NO CHANGE UID."
else
  echo "input y or n"
fi

## GID CHANGE
read -p "##### Do you change GID? input \"y\" or \"n\" #####" yn
if [ $yn = y ]; then
  for i in `cat $1`
  do
    USERNAME=`echo $i | cut -d "," -f 1`
    OLD_GID=`echo $i | cut -d "," -f 2`
    NEW_GID=`echo $i | cut -d "," -f 3`
    mkdir -p ${USERNAME}
    find -P ${TARGET_DIR} -gid ${OLD_GID} -exec chgrp -h ${NEW_GID} {} \; -print | tee ${USERNAME}/${USERNAME}_change_gid.list &
    wait
  done
  echo "changed uid" && echo ""
elif [ $yn = n ]; then
  echo "NO CHANGE GID."
else
  echo "input y or n"
fi
