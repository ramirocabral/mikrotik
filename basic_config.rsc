# Default config for internet+voip+iptv. Running on an rb760gr3.

#setting up bridge, no VLAN filtering, just IGMP snooping (HW ACC = OFF)
/interface bridge
add admin-mac=XXXXXXXX auto-mac=no comment=defconf igmp-snooping=yes \
    name=LAN-BRIDGE protocol-mode=none

/interface bridge port
add bridge=LAN-BRIDGE comment=defconf interface=ether2
add bridge=LAN-BRIDGE comment=defconf interface=ether3
add bridge=LAN-BRIDGE comment=defconf interface=ether4
add bridge=LAN-BRIDGE comment=defconf interface=ether5

/interface vlan
add interface=ether1 name=vlan10-internet vlan-id=10
add interface=ether1 name=vlan11-iptv vlan-id=11
add interface=ether1 name=vlan12-voip vlan-id=12

# PPP secrets on HGU config.
/interface pppoe-client
add add-default-route=yes disabled=no interface=vlan10-internet name=internet \
    use-peer-dns=yes user=XXXXXXXX@speedy

/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
add name=VLANS-voip-iptv

/interface list member
add comment=defconf interface=LAN-BRIDGE list=LAN
add comment=defconf interface=internet list=WAN
add interface=vlan11-iptv list=VLANS-voip-iptv
add interface=vlan12-voip list=VLANS-voip-iptv

# Reserved pool for IPTV boxes.
/ip pool
add name=general-pool ranges=192.168.9.10-192.168.9.239
add name=iptv-pool ranges=192.168.9.241-192.168.9.254

/ip address
add address=192.168.9.1/24 comment=defconf interface=LAN-BRIDGE network=\
    192.168.9.0

# DHCP server.
/ip dhcp-server
add address-pool=general-pool interface=LAN-BRIDGE lease-time=1h name=dhcp1

# We use the router as a DNS server for caching, and for the IPTV boxes we use the ISP DNS.
/ip dhcp-server network
add address=192.168.9.0/24 comment=general-network dns-server=192.168.9.1 \
    gateway=192.168.9.1 netmask=24
add address=192.168.9.240/28 comment=iptv-network dns-server=\
    172.29.224.84,172.29.224.85 gateway=192.168.9.1 netmask=24

# Take the ID_VENDOR substring from the DHCP Options in the request from the IPTV boxes, and assign them an ip from the iptv pool.
# See: https://www.incognito.com/tutorials/dhcp-options-in-plain-english/
/ip dhcp-server matcher
add address-pool=iptv-pool code=60 name=iptv-matcher server=dhcp1 value=\
    TEF_IPTV

# DHCP client for IPTV and VOIP interfaces.
/ip dhcp-client
add interface=vlan11-iptv
add add-default-route=no interface=vlan12-voip

# This allows request coming from WAN, so it must be blocked on firewall rules.   
# Google and Cloudflare DNS.
/ip dns
set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1
/ip dns static
add address=192.168.9.1 comment=ROUTER name=router.lan
add address=192.168.9.5 comment=NAS name=nas.lan

# Firewall basic config + accept voip and iptv traffic.
/ip firewall filter
add action=accept chain=input comment=\
    "INPUT: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="INPUT: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="INPUT: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "INPUT : accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=accept chain=input comment="INPUT: accept voip and iptv vlans" \
    in-interface-list=VLANS-voip-iptv
add action=drop chain=input comment="INPUT: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related hw-offload=yes
add action=accept chain=forward comment=\
    "FORWARD: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="FORWARD: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "FORWARD: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN

# NAT for internet and VLANs traffic.
/ip firewall nat
add action=masquerade chain=srcnat comment="WAN masquerade" ipsec-policy=\
    out,none out-interface-list=WAN
add action=masquerade chain=srcnat comment="VLANS iptv&voip masquerade" \
    out-interface-list=VLANS-voip-iptv

# Required for Movistar VOD.
/ip firewall service-port
set rtsp disabled=no

/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" \
    dst-port=33434-33534 protocol=udp
add action=accept chain=input comment=\
    "defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=\
    udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 \
    protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=input comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment=\
    "defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" \
    hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=forward comment="defconf: accept HIP" protocol=139
add action=accept chain=forward comment="defconf: accept IKE" dst-port=\
    500,4500 protocol=udp
add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=forward comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN

# Necessary to download movies legally
/ip upnp
set enabled=yes

/ip neighbor discovery-settings
set discover-interface-list=LAN

# Allow services only for LAN.
/ip service
set telnet address=192.168.9.0/24
set ftp disabled=yes
set www address=192.168.9.0/24
set ssh disabled=yes
set api disabled=yes
set winbox address=192.168.9.0/24
set api-ssl disabled=yes

# Required for IPTV Multicast.
/routing igmp-proxy
set query-interval=2m15s query-response-interval=30s quick-leave=yes
/routing igmp-proxy interface
add alternative-subnets=0.0.0.0/0 interface=vlan11-iptv upstream=yes
add interface=LAN-BRIDGE

# Get dynamic routes from ISP.
/routing rip instance
add afi=ipv4 disabled=no name=rip
/routing rip interface-template
add disabled=no instance=rip interfaces=vlan11-iptv,vlan12-voip mode=passive

/system clock
set time-zone-name=America/Argentina/Buenos_Aires
/system note
set show-at-login=no
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN

/disk settings
set auto-media-interface=LAN-BRIDGE auto-media-sharing=yes auto-smb-sharing=\
    yes