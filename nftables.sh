#/bin/bash

# ENVIRONMENT VARS
NFT='/usr/sbin/nft'
NFT_STATUS=$(/usr/bin/systemctl is-active nftables.service)
FWD_STATUS=$(/usr/bin/systemctl is-active firewalld.service)
IP_FAMILY=${IP_FAMILY=inet}
IF_0='ens160'
IF_1='ens192'

# SETTING FLAGS
## if you would like to configure, change 'no' to 'yes'
FILTER='yes'
NAT='no'

# FUNCTIONS
log_supress()
{
        # SUPPRESS CONSOLE LOG
        /usr/sbin/sysctl -w kernel.printk="3 4 1 7" > /dev/null
}

apply_filter() {
	# CREATE TABLE and CHAINS
	$NFT add table ${IP_FAMILY} filter
	$NFT add chain ${IP_FAMILY} filter input_tcp_helper \{ type filter hook prerouting priority 0\; \}
	$NFT add chain ${IP_FAMILY} filter input \{ type filter hook input priority 0\; policy drop\; \}
	$NFT add chain ${IP_FAMILY} filter input_tcp
	$NFT add chain ${IP_FAMILY} filter input_udp 
	$NFT add chain ${IP_FAMILY} filter input_icmp
	$NFT add chain ${IP_FAMILY} filter output \{ type filter hook output priority 0\; policy drop\; \}
	$NFT add chain ${IP_FAMILY} filter forward \{ type filter hook forward priority 0\; policy drop\; \}

	# INPUT TCP HELPER
	$NFT add ct helper ${IP_FAMILY} filter input_tcp_helper '{ type "ftp" protocol tcp; }'
	$NFT add rule ${IP_FAMILY} filter input_tcp_helper tcp dport 21 ct helper set "input_tcp_helper" accept

	# INPUT BLOCK SET 
	$NFT add set     ${IP_FAMILY} filter input_block_ip_list \{ type ipv4_addr\; size 0\; flags interval\; \}
	$NFT add element ${IP_FAMILY} filter input_block_ip_list \{ 10.0.0.0/24, 172.16.0.0/24, 192.168.0.0/24 \}
	
	# INPUT LIMIT SET
	$NFT add set  ${IP_FAMILY} filter input_limit_tcp_flood_list \{ type ipv4_addr\; size 0\; flags timeout\; timeout 1h\; \}
	$NFT add set  ${IP_FAMILY} filter input_limit_icmp_list \{ type ipv4_addr\; size 0\; flags timeout\; timeout 1h\; \}

	# INPUT BASE CHAIN RULE
	$NFT add rule ${IP_FAMILY} filter input ip saddr @input_block_ip_list counter log prefix \"NFTABLES_DROP_IP:\" drop
	$NFT add rule ${IP_FAMILY} filter input iif lo accept
	$NFT add rule ${IP_FAMILY} filter input ip protocol tcp ct state new jump input_tcp
	$NFT add rule ${IP_FAMILY} filter input ip protocol udp ct state new jump input_udp
	$NFT add rule ${IP_FAMILY} filter input ip protocol icmp ct state new goto input_icmp
	$NFT add rule ${IP_FAMILY} filter input ct state \{ established, related \} accept
	$NFT add rule ${IP_FAMILY} filter input ip protocol tcp counter log prefix \"NFTABLES_DROP_TCP: \" drop
	$NFT add rule ${IP_FAMILY} filter input ip protocol udp counter log prefix \"NFTABLES_DROP_UDP: \" drop
	$NFT add rule ${IP_FAMILY} filter input ct state invalid counter log prefix \"NFTABLES_DROP_INVALID: \" drop
	$NFT add rule ${IP_FAMILY} filter input counter limit rate 500/second accept

	# INPUT TCP REGULAR CHAIN RULE
	$NFT add rule ${IP_FAMILY} filter input_tcp tcp flags \{ syn, ack, rst, fin \} tcp dport 1-65535 \
	     meter flood size 0 \{ ip saddr limit rate over 1/minute burst 4 packets \} \
	     add @input_limit_tcp_flood_list \{ ip saddr timeout 24h \} counter log prefix \"NFTABLES_DROP_TCP_FLOOD: \" drop
	$NFT add rule ${IP_FAMILY} filter input_tcp ip saddr 0.0.0.0/0 tcp dport \{ 20, 21 \} accept
	$NFT add rule ${IP_FAMILY} filter input_tcp ip saddr 0.0.0.0/0 tcp dport 22 accept
	$NFT add rule ${IP_FAMILY} filter input_tcp ip saddr 0.0.0.0/0 tcp dport \{ 53, 80, 443 \} accept
	
	# INPUT UDP REGULAR CHAIN RULE
	$NFT add rule ${IP_FAMILY} filter input_udp ip saddr 0.0.0.0/0 udp dport \{ 53, 123 \} accept
	
	# INPUT ICMP REGULAR CHAIN RULE
	$NFT add rule ${IP_FAMILY} filter input_icmp ip protocol icmp icmp type echo-request \
	     meter input_icmp_list size 0 \{ ip saddr limit rate 1/minute burst 4 packets \} \
	     add @input_limit_icmp_list \{ ip saddr timeout 24h \} counter log prefix \"NFTABLES_DROP_ICMP: \" drop
	$NFT add rule ${IP_FAMILY} filter input_icmp ip protocol icmp icmp type echo-request \
	     limit rate over 85 bytes/second counter log prefix \"NFTABLES_DROP_ICMP_SIZE \" drop
	$NFT add rule ${IP_FAMILY} filter input_icmp ip protocol icmp icmp type echo-request limit rate 1/minute accept
	
	# OUTPUT BASE CHAIN RULE
	$NFT add rule ${IP_FAMILY} filter output ip daddr 0.0.0.0/0 tcp dport \{ 20, 21, 22, 25, 53, 80, 123, 443, 24220, 24224, 24230 \} accept
	$NFT add rule ${IP_FAMILY} filter output ip daddr 0.0.0.0/0 udp dport \{ 53, 123, 161, 162 \} accept
	$NFT add rule ${IP_FAMILY} filter output ip daddr 0.0.0.0/0 ip protocol icmp accept
	$NFT add rule ${IP_FAMILY} filter output ct state \{ established, related, \} accept
}

apply_nat() {
	/usr/sbin/sysctl -w net.ipv4.ip_forward=1 > /dev/null
	$NFT add table ip nat 
	
	# POST ROUTING(SNAT)
	$NFT add chain ip nat postrouting \{ type nat hook postrouting priority 0\; \}
	$NFT add rule nat postrouting ip saddr 172.16.0.0/24 oif ${IF_1} snat 10.0.0.1
	
	# MASQUERADE
	$NFT add rule nat postrouting ip saddr 172.16.0.0/24 oif ${IF_1} masquerade
	
	# PRE ROUTING(DNAT)
	$NFT add chain ip nat prerouting \{ type nat hook prerouting priority 0\; \}
	$NFT add rule nat prerouting iif ${IF_0} tcp dport \{ 80, 443 \} dnat 10.0.0.1:80
}

# START SETTINGS
if [[ ${NFT_STATUS} = active ]] && [[ ${FWD_STATUS} = inactive ]]; then
        log_supress
	$NFT flush ruleset 
	[[ ${FILTER} = 'yes' ]]  && apply_filter
	[[ ${NAT} = 'yes' ]]  && apply_nat
	$NFT list ruleset > /etc/sysconfig/nftables.conf
else
	echo Check nftables,firewalld service or '# lsmod | grep nf_tables'
	exit 1
fi
