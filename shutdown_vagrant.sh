#!/bin/bash

## environment variable
VAGRANT_DIR=~/Vagrant/

## all VMs shutdown
read -p "Do you want to shutdown all VMs? input \"y\" or \"n\"" yn

if [ ${yn} = y ]; then
  for VM in `ls ${VAGRANT_DIR}`;
  do
    cd ${VAGRANT_DIR}${VM}/
    vagrant status | grep running > /dev/null
    VM_STATE=$?
    case ${VM_STATE} in
      0)
        vagrant halt > /dev/null && echo "##### VM \"${VM}\" is shutdowned. #####" ;;
      1)
        echo "##### VM \"${VM}\" is already shutdowned. #####" ;;
    esac
  done
elif [ ${yn} = n ]; then
  echo "select VM to be shutdowned."
  for VM in `ls ${VAGRANT_DIR}`;
  do
    read -p "Do you want to shutdown VM \"${VM}\"? input \"y\" or \"n\"" yn
    if [ ${yn} = y ]; then
      cd ${VAGRANT_DIR}${VM}/
      vagrant status | grep running > /dev/null
      VMSTATE=$?
      case ${VMSTATE} in
        0)
          vagrant halt > /dev/null && echo "##### VM \"${VM}\" is shutdowned. #####" ;;
        1)
          echo "##### VM \"${VM}\" is already shutdowned. #####" ;;
      esac
    elif [ ${yn} = n ]; then
      echo "##### Shutdown VM \"${VM}\" was canceled. #####"
    else
      echo "input \"y\" or \"n\""
    fi
  done
else
    echo "input \"y\" or \"n\""
fi

## Processing after startup
echo "##### Display VM's state. #####"
vagrant global-status
