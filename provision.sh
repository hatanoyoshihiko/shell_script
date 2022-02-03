#/bin/bash

packages="vim bash-completion langpacks-ja chrony vim glibc-langpack-ja"
os_dist=`cat /etc/os-release`

echo "alias nocomment=\"grep -v '^\s*\(#\|$\)'\"" >> ~/.bashrc
echo "alias vi=vim" >> ~/.bashrc
source ~/.bashrc

if [[ "$os_dist" =~ "CentOS" ]] || [[ "$os_dist" =~ "AlmaLinux" ]] ; then
	dnf install -y $packages
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
elif [[ "$os_dist" =~ "Ubuntu" ]] ; then
	apt install -y $packages
else
	:
fi

localectl set-locale LANG=ja_JP.utf8
timedatectl set-local-rtc 0
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
locale

chronyc online && chronyc sources

if [[ "$os_dist" =~ "CentOS" ]] || [[ "$os_dist" =~ "AlmaLinux" ]] ; then
	dnf -y upgrade && reboot
elif [[ "$os_dist" =~ "Ubuntu" ]] ; then
	apt update && apt upgrade && reboot
else
	:
fi
