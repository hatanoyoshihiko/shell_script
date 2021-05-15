#
# select tables you use
#
FILTER="yes"
NAT="no"
MANGLE="no"
RAW="no"
SECURITY="no"

apply_filter_table(){

  local IPTABLES="/sbin/iptables -t filter"

  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -Z

  $IPTABLES -P INPUT   DROP
  $IPTABLES -P FORWARD DROP
  $IPTABLES -P OUTPUT  DROP

  $IPTABLES -A INPUT  -m state --state RELATED,ESTABLISHED  -j ACCEPT
  $IPTABLES -A INPUT  -i lo    -j ACCEPT
  $IPTABLES -A INPUT  -p icmp  -s 192.168.11.0/24                    -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p tcp   -s 192.168.11.0/24 --dport 22     -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p udp   -s 192.168.11.0/24 --dport 53     -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p tcp   -s 192.168.11.0/24 --dport 53     -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p tcp   -s 192.168.11.0/24 --dport 80     -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p udp   -s 192.168.11.0/24 --dport 161    -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p tcp   -s 192.168.11.0/24 --dport 443    -m state --state NEW -j ACCEPT
  $IPTABLES -A INPUT  -p tcp   -s 192.168.11.0/24 --dport 2049   -m state --state NEW -j ACCEPT

  $IPTABLES -A OUTPUT -m state --state RELATED,ESTABLISHED    -j ACCEPT
  $IPTABLES -A OUTPUT -p icmp  -d 0.0.0.0/0                   -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p tcp   -d 0.0.0.0/0 --dport 22        -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p tcp   -d 0.0.0.0/0 --dport 25        -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p udp   -d 0.0.0.0/0 --dport 53        -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p tcp   -d 0.0.0.0/0 --dport 53        -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p udp   -d 0.0.0.0/0 --dport 67        -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p tcp   -d 0.0.0.0/0 --dport 80        -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p udp   -d 0.0.0.0/0 --dport 123       -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p tcp   -d 0.0.0.0/0 --dport 123       -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p tcp   -d 0.0.0.0/0 --dport 443       -m state --state NEW -j ACCEPT
  $IPTABLES -A OUTPUT -p udp   -d 0.0.0.0/0 --dport 33434:33534       -m state --state NEW -j ACCEPT

}

apply_nat_table(){

  local IPTABLES="/sbin/iptables -t nat"

  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -Z

  $IPTABLES -P PREROUTING   ACCEPT
  $IPTABLES -P POSTROUTING  ACCEPT
  $IPTABLES -P OUTPUT       ACCEPT
}

apply_mangle_table(){

  local IPTABLES="/sbin/iptables -t mangle"

  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -Z

  $IPTABLES -P PREROUTING   ACCEPT
  $IPTABLES -P INPUT        ACCEPT
  $IPTABLES -P FORWARD      ACCEPT
  $IPTABLES -P OUTPUT       ACCEPT
  $IPTABLES -P POSTROUTING  ACCEPT

}

apply_raw_table(){

  local IPTABLES="/sbin/iptables -t raw"

  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -Z

  $IPTABLES -P PREROUTING   ACCEPT
  $IPTABLES -P OUTPUT       ACCEPT

}

apply_security_table(){

  local IPTABLES="/sbin/iptables -t security"

  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -Z

  $IPTABLES -P INPUT        ACCEPT
  $IPTABLES -P PREROUTING   ACCEPT
  $IPTABLES -P OUTPUT       ACCEPT

}

#
# main
#
[ "x${FILTER}" == "xyes" ]   && apply_filter_table
[ "x${NAT}" == "xyes" ]      && apply_nat_table
[ "x${MANGLE}" == "xyes" ]   && apply_mangle_table
[ "x${RAW}" == "xyes" ]      && apply_raw_table
[ "x${SECURITY}" == "xyes" ] && apply_security_table

/usr/libexec/iptables/iptables.init save
