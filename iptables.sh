# This file is interpreted as shell script.
# Put your custom iptables rules here, they will
# be executed with each firewall (re-)start.
# ?lock null packets (DoS)

apt -y install iptables-persistent
systemctl enable netfilter-persistent

# Flush/Delete firewall rules
iptables -F
iptables -X
iptables -Z
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Block-flood attacks syn (DoS)                                                                         
iptables -P INPUT DROP                                                                                     
iptables -P FORWARD DROP                                                                                   
iptables -P OUTPUT DROP 

# Log dropped packets           
#ip6tables -N DROP           
#ip6tables -A INPUT -j LOG --log-prefix '[ip6tables DROP]:'
#ip6tables -A DROP_LOG -j REJECT --reject-with icmp6-port-unreachable

# Doing statistics on icmp
iptables -A OUTPUT -p 58 -j ICMP6_STATS
iptables -A FORWARD -p 58 -j ICMP6_STATS

# drop packets with routing header type 0 and any remaining segments (more than 0)               
# deprecating RFC: http://www.ietf.org/rfc/rfc5095.txt                           
# amplification attack: http://www.secdev.org/conf/IPv6_RH_security-csw07.pdf     
iptables -A INPUT -m rt --rt-type 0 -j DROP                                                 
iptables -A OUTPUT -m rt --rt-type 0 -j DROP                                                 
iptables -A FORWARD -m rt --rt-type 0 -j DROP

# Stealth Scans etc. DROPen
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP

# Allow anything on the local link
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow anything out on the internet
iptables -A OUTPUT -o eth0.2 -j ACCEPT

# Allow Link-Local addresses
iptables -A INPUT -s fe80::/10 -j ACCEPT
iptables -A OUTPUT -s fe80::/10 -j ACCEPT

# Allow multicast
iptables -A INPUT -s ff00::/8 -j ACCEPT
iptables -A OUTPUT -s ff00::/8 -j ACCEPT

# Allow DNS
iptables -I OUTPUT -o br-lan -p udp -m set --match-set dns6 dst --dport 53 -j ACCEPT
iptables -I INPUT -i br-lan -p udp -m set --match-set dns6 src --sport 53 -j ACCEPT

#ip6tables -I INPUT -i br-lan -m set --match-set dns src -j ACCEPT
#ip6tables -I OUTPUT -o br-lan -m set --match-set dns dst -j ACCEPT

# Allow ICMP (and thus SLAAC, etc) 
iptables -A INPUT -p icmpv6 -m limit --limit 30/min -j ACCEPT

# Allow DHCPv6 configuration
iptables -A INPUT -p udp --sport 547 --dport 546 -j ACCEPT
iptables -A FORWARD -s fe80::/10 -p udp --sport 547 --dport 546 -j ACCEPT

# Allow ICMPv6
iptables -A INPUT -p icmpv6 --icmpv6-type echo-request --match limit --limit 30/minute -j ACCEPT
iptables -A FORWARD -p icmpv6 -m physdev ! --physdev-in eth0.2 -j ACCEPT
iptables -A FORWARD -p icmpv6 --icmpv6-type echo-request -m physdev --physdev-in eth0.2 -j ACCEPT
iptables -A FORWARD -p icmpv6 --icmpv6-type echo-reply -m physdev --physdev-in eth0.2 -j ACCEPT
iptables -A FORWARD -p icmpv6 --icmpv6-type neighbor-solicitation -m physdev --physdev-in eth0.2 -j ACCEPT
iptables -A FORWARD -p icmpv6 --icmpv6-type neighbor-advertisement -m physdev --physdev-in eth0.2 -j ACCEPT
iptables -A FORWARD -p icmpv6 --icmpv6-type router-advertisement -m physdev --physdev-in eth0.2 -j ACCEPT

# Allow forwarding
iptables -A FORWARD -m state --state NEW -m physdev ! --physdev-in eth0.2 -j ACCEPT
#ip6tables -A FORWARD -m state --state NEW -p tcp --dport 22 -m physdev --physdev-in eth0.2 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
ipables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

# Block XMAS packets (DoS)
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Allow internal traffic on the loopback device
iptables -A INPUT -i lo -j ACCEPT

# Allow ssh access
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT

# Allow established connections
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  
# Allow outgoing connections
iptables -P OUTPUT ACCEPT
  
# Set default deny firewall policy
iptables -P INPUT DROP

# Set default deny firewall policy
iptables -P FORWARD DROP
# Internal uci firewall chains are flushed and recreated on reload, so
# put custom rules into the root chains e.g. INPUT or FORWARD or into the
#eplace the ips-v4 with v6 if needed
wget -qO- http://www.cloudflare.com/ips-v4
iptables -I INPUT -p tcp -m multiport --dports 80,443,8080,8443,2052,2053,2082,2083,2086,2087,2095,2096,8880,8118 -s $ip -j ACCEPT
