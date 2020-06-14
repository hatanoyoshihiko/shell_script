#!/bin/bash

## environment variable
VAGRANT_DIR=~/Vagrant/
VM_NAME=`ls ${VAGRANT_DIR}`
VM_DIR=/Users/alessi/Vagrant

## Functions
ALL_VM_STARTUP()
{
  cd ${VAGRANT_DIR}${VM}
  VM_STATUS=`vagrant status | grep default | awk '{ print $2 }'`
  if [ ${VM_STATUS} = "poweroff" ]; then
    vagrant up > /dev/null && echo "##### VM \"${VM}\" is started. #####"
  elif [ ${VM_STATUS} = "running" ]; then
    echo "##### VM \"${VM}\" is already running. #####"
  elif [ ${VM_STATUS} = "saved" ]; then
    vagrant resume > /dev/null && echo "##### VM \"${VM}\" resumed from suspend. #####"
  else
    vagrant up > /dev/null && echo "##### VM \"${VM}\" is started from aborted. #####"
  fi
}

SELECT_VM_STARTUP()
{
  case $VM in
    "${VM%quit}")
	    cd ${VM_DIR}/${VM}
      VM_STATUS=`vagrant status | grep default | awk '{ print $2 }'`
      if [[ ${VM_STATUS} = "poweroff" ]]; then
        vagrant up > /dev/null && echo "##### VM \"${VM}\" is started. #####"
      elif [[ ${VM_STATUS} = "running" ]]; then
        echo "##### VM \"${VM}\" is already running. #####"
      elif [[ ${VM_STATUS} = "saved" ]]; then
        vagrant resume > /dev/null && echo "##### VM \"${VM}\" resumed from suspend. #####"
      else
        echo "##### UNKNOWN STATUS #####"
        exit 1
      fi
			;;
    "quit")
      echo "Processing end."
      exit 0
			;;
    "*")
      echo ${REPLY} is not exist.
  esac
}

## VMs startup process
read -p "Do you want to start all VMs? input \"y\" or \"n\"" yn

### All VMs startup
if [ ${yn} = y ]; then
  for VM in ${VM_NAME};
  do
  ALL_VM_STARTUP
  done

### select VMs startup.
elif [ ${yn} = n ]; then
  echo "Select VM."
  select VM in quit ${VM_NAME}
  do
  SELECT_VM_STARTUP
  done
else
  echo "input \"y\" or \"n\"" && exit 0
fi

## Processing after startup
echo "##### Display VM's state. #####"
vagrant global-status
