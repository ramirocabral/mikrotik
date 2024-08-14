# Basic wireguard road-warrior config.

# Assign random UDP Port.
/interface wireguard
add listen-port=XXXXX name=wireguard-rw

/ip pool
add name=vpn-pool ranges=192.168.10.2-192.168.10.254

/ip address
add address=192.168.10.1/24 interface=wireguard-rw

# add wireguard interface to LAN list, so it can access LAN devices and MK DNS server.
/interface list member
add interface=wireguard-rw list=LAN

# add one peer, assign an ip address.
/interface wireguard peers
add allowed-address=192.168.10.2/32 comment=MY_PEER interface=wireguard-rw \
    public-key="PEER_PUBLIC_KEY"

# accept incoming traffic from wireguard interface.
/ip firewall filter
add action=accept chain=input comment="INPUT: allow WIREGUARD" \
    dst-port=XXXXX protocol=udp \
    place-before=[find comment="defconf: drop all not coming from LAN"]