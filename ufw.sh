#!/bin/bash

# VARIABLES
#set -eu

func_ufw (){
	ufw allow from 192.168.11.0/24		to any port	22		proto tcp
	ufw allow from 127.0.0.1/32		to any port	25		proto tcp
	ufw allow from 192.168.11.0/24		to any port	53		proto udp
	ufw allow from 192.168.11.0/24		to any port	53		proto tcp
	ufw allow from 192.168.11.0/24		to any port	80		proto tcp
	ufw allow from 192.168.11.0/24		to any port	123		proto udp
	ufw allow from 127.0.0.1/32		to any port	161		proto udp
	ufw allow from 192.168.11.0/24		to any port	161		proto udp
	ufw allow from 127.0.0.1/32		to any port	162		proto udp
	ufw allow from 192.168.11.0/24		to any port	162		proto udp
	ufw allow from 192.168.11.0/24		to any port	389		proto tcp
	ufw allow from 192.168.11.0/24		to any port	443		proto tcp
	ufw allow from 192.168.11.0/24		to any port	514		proto udp
	ufw allow from 192.168.11.0/24		to any port	514		proto tcp
	ufw allow from 127.0.0.1/32		to any port	953		proto tcp
	ufw allow from 192.168.11.0/24		to any port	1812		proto udp
	ufw allow from 192.168.11.0/24		to any port	1813		proto udp
	ufw allow from 127.0.0.1/32		to any port	3306		proto tcp
	ufw allow from 127.0.0.1/32		to any port	8080		proto tcp
	ufw allow from 192.168.11.0/24		to any port	8080		proto tcp
	ufw allow from 192.168.11.0/24		to any port	10050		proto tcp
	ufw allow from 192.168.11.0/24		to any port	10051		proto tcp
	ufw allow from 127.0.0.1/32		to any port	10051		proto udp
	ufw allow from 127.0.0.1/32		to any port	18120		proto udp
	ufw allow from 192.168.11.0/24		to any port	34935		proto udp
	ufw default deny incoming
	ufw default allow outgoing
	ufw enable
	ufw reload
	ufw logging medium
	ufw status verbose
}

func_ufw
