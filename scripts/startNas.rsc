:local macAddress [/ip arp get [ find where address=[/ip dns static get [find where name="nas.lan"] address]] mac-address]

/tool wol mac="$macAddress" interface="LAN-BRIDGE"
