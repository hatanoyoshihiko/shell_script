#/bin/bash

# env
rhel_packages="vim-enhanced bash-completion chrony langpacks-ja"
debian_packages="vim bash-completion chrony language-pack-ja"
os_dist=`cat /etc/os-release`

# .bashrc
echo "alias nocomment=\"grep -v '^\s*\(#\|$\)'\"" >> ~/.bashrc
echo "alias vi=vim" >> ~/.bashrc
source ~/.bashrc

# service control and packages install
if [[ "$os_dist" =~ "CentOS" ]] || [[ "$os_dist" =~ "AlmaLinux" ]] ; then
	dnf install -y $rhel_packages
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
elif [[ "$os_dist" =~ "Ubuntu" ]] ; then
	apt install -y $packages
	systemctl stop {ufw,apparmor}.service
	systemctl disable {ufw,apparmor}.service
else
	:
fi

# set locale and time sync
localectl set-locale LANG=ja_JP.utf8
timedatectl set-local-rtc 0
timedatectl set-timezone Asia/Tokyo
chronyc online && chronyc sources

# os update
if [[ "$os_dist" =~ "CentOS" ]] || [[ "$os_dist" =~ "AlmaLinux" ]] ; then
	dnf -y upgrade && reboot
elif [[ "$os_dist" =~ "Ubuntu" ]] ; then
	apt update && apt upgrade && reboot
else
	:
fi
