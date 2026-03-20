/interface ethernet
set [ find default-name=ether1 ] l2mtu=1500
set [ find default-name=ether2 ] l2mtu=1500
set [ find default-name=ether3 ] l2mtu=1500
set [ find default-name=ether4 ] l2mtu=1500
set [ find default-name=ether5 ] l2mtu=1500
/interface lte apn
set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/ip pool
add name=dhcp_pool5 ranges=192.168.0.2-192.168.0.254
add name=hs-pool-3 ranges=172.17.0.1-172.17.0.253
add name=dhcp_pool8 ranges=192.168.50.2-192.168.50.14
add name=dhcp_pool9 ranges=10.0.50.1-10.0.50.253
/ip dhcp-server
add address-pool=dhcp_pool8 interface=ether4 lease-time=10m name=dhcp1
add address-pool=dhcp_pool9 interface=ether3 lease-time=1d name=dhcp2
/ip smb users
set [ find default=yes ] disabled=yes
/port
set 0 name=serial0
/queue type
add kind=pcq name=ping-dl pcq-classifier=src-address pcq-dst-address6-mask=64 \
    pcq-limit=10000KiB pcq-rate=32k pcq-src-address6-mask=64 pcq-total-limit=\
    5KiB
add kind=pcq name=ping-up pcq-classifier=src-address pcq-dst-address6-mask=64 \
    pcq-limit=10000KiB pcq-rate=32k pcq-src-address6-mask=64 pcq-total-limit=\
    5KiB
add kind=pcq name=hotspot-dl pcq-burst-rate=2200k pcq-burst-threshold=1500k \
    pcq-classifier=dst-address pcq-dst-address6-mask=64 pcq-limit=51000KiB \
    pcq-rate=2M pcq-src-address6-mask=64 pcq-total-limit=384KiB
add kind=sfq name=ping
add kind=pcq name=hotspot-ul pcq-burst-rate=2200k pcq-burst-threshold=1500k \
    pcq-classifier=src-address pcq-dst-address6-mask=64 pcq-limit=51000KiB \
    pcq-rate=2M pcq-src-address6-mask=64 pcq-total-limit=384KiB
add kind=sfq name=sfq-default sfq-perturb=10
add kind=pcq name=Ping_in_32K pcq-classifier=dst-address,dst-port \
    pcq-dst-address6-mask=64 pcq-rate=32k pcq-src-address6-mask=64
add kind=pcq name=Ping_out_32K pcq-classifier=src-address,src-port \
    pcq-dst-address6-mask=64 pcq-rate=32k pcq-src-address6-mask=64
add kind=pcq name=ping_pkts_i_64K pcq-classifier=dst-address,dst-port \
    pcq-dst-address6-mask=64 pcq-rate=64k pcq-src-address6-mask=64
add kind=pcq name=ping_pkts_o_64K pcq-classifier=src-address,src-port \
    pcq-dst-address6-mask=64 pcq-rate=64k pcq-src-address6-mask=64
add fq-codel-limit=1000 fq-codel-quantum=300 fq-codel-target=12ms kind=\
    fq-codel name=fq-codel_short
add kind=fq-codel name=fq_codel
add cake-flowmode=dual-srchost cake-nat=yes kind=cake name=cake-WAN-tx
add cake-diffserv=besteffort cake-flowmode=dual-dsthost cake-nat=yes kind=\
    cake name=cake-WAN-rx
add cake-diffserv=besteffort cake-flowmode=hosts cake-rtt=5ms kind=cake name=\
    cake-icmp
add kind=pcq name=DL pcq-classifier=dst-address,dst-port pcq-rate=150M
add kind=pcq name=UL pcq-classifier=src-address,src-port pcq-rate=75M
/queue simple
add dst=10.0.50.0/24 max-limit=800M/800M name="LOCAL 1" target=\
    10.0.50.0/24,192.168.50.0/28 total-queue=default
add dst=192.168.50.0/28 max-limit=800M/800M name="LOCAL 2" target=\
    10.0.50.0/24,192.168.50.0/28 total-queue=default
add bucket-size=0.001/0.001 max-limit=150M/360M name="speed stabilizer" \
    queue=cake-WAN-rx/cake-WAN-tx target=ether3 total-queue=fq_codel
add max-limit=75M/150M name=equal parent="speed stabilizer" queue=UL/DL \
    target=10.0.50.0/24 total-queue=fq_codel
/queue tree
add bucket-size=0.001 name=ping_pkts_i packet-mark=ping_pkts_i parent=global \
    queue=ping_pkts_i_64K
add bucket-size=0.001 name=ping_pkts_o packet-mark=ping_pkts_o parent=global \
    queue=ping_pkts_o_64K
/routing bgp template
set default disabled=no output.network=bgp-networks
/routing ospf instance
add disabled=no name=default-v2
/routing ospf area
add disabled=yes instance=default-v2 name=backbone-v2
/routing table
add fib name=raptor_route
add fib name=to-isp1
add fib name=to-isp2
/snmp community
set [ find default=yes ] name=snmp-home
/system logging action
set 3 remote=192.168.0.2
/user group
add name=hotspot policy="local,telnet,ssh,reboot,read,write,test,winbox,passwo\
    rd,web,sniff,sensitive,api,romon,rest-api,!ftp,!policy"
add name=api policy="telnet,ssh,sniff,api,!local,!ftp,!reboot,!read,!write,!po\
    licy,!test,!winbox,!password,!web,!sensitive,!romon,!rest-api"
add name=api1 policy="local,telnet,ssh,reboot,read,write,policy,test,winbox,pa\
    ssword,web,sniff,sensitive,api,romon,rest-api,!ftp"
/ip firewall connection tracking
set loose-tcp-tracking=no udp-timeout=10s
/ip neighbor discovery-settings
set discover-interface-list=!dynamic
/ipv6 settings
set max-neighbor-entries=8192
/interface ovpn-server server
add auth=sha1,md5 mac-address=FE:83:2E:A1:8F:8A name=ovpn-server1
/ip address
add address=192.168.50.1/28 interface=ether4 network=192.168.50.0
add address=10.0.50.254/24 interface=ether3 network=10.0.50.0
add address=10.0.0.1/29 interface=ether5 network=10.0.0.0
add address=192.168.1.3/24 interface=ether1 network=192.168.1.0
add address=192.168.1.2/24 interface=ether2 network=192.168.1.0
/ip cloud
set update-time=no
/ip dhcp-server lease
add address=10.0.50.14 client-id=1:ac:d5:64:74:83:8b mac-address=\
    AC:D5:64:74:83:8B server=dhcp2
/ip dhcp-server network
add address=10.0.50.0/24 dns-server=192.168.50.4,192.168.50.5 gateway=\
    10.0.50.254
add address=192.168.50.0/28 dns-server=8.8.8.8,8.8.4.4,208.67.220.220 \
    gateway=192.168.50.1
/ip dns
set allow-remote-requests=yes cache-max-ttl=1d servers=\
    192.168.50.4,192.168.50.5
/ip firewall address-list
add address=10.0.50.2-192.168.0.16 list=clients
add address=192.168.0.18-192.168.0.254 list=clients
add address=10.0.50.0/24 list="ip ranges"
add address=192.168.0.0/24 list="ip ranges"
add address=192.168.50.0/28 list="ip ranges"
add address=172.17.0.0/24 list="ip ranges"
add address=10.0.0.0/8 list=LAN
add address=172.16.0.0/12 list=LAN
add address=192.168.0.0/16 list=LAN
add address=0.0.0.0/8 comment="RFC 1122 \"This host on this network\"" list=\
    Bogons
add address=10.0.0.0/8 comment="RFC 1918 (Private Use IP Space)" disabled=yes \
    list=Bogons
add address=100.64.0.0/10 comment="RFC 6598 (Shared Address Space)" list=\
    Bogons
add address=127.0.0.0/8 comment="RFC 1122 (Loopback)" list=Bogons
add address=169.254.0.0/16 comment=\
    "RFC 3927 (Dynamic Configuration of IPv4 Link-Local Addresses)" list=\
    Bogons
add address=172.16.0.0/12 comment="RFC 1918 (Private Use IP Space)" disabled=\
    yes list=Bogons
add address=192.0.0.0/24 comment="RFC 6890 (IETF Protocol Assingments)" list=\
    Bogons
add address=192.0.2.0/24 comment="RFC 5737 (Test-Net-1)" list=Bogons
add address=192.168.0.0/16 comment="RFC 1918 (Private Use IP Space)" \
    disabled=yes list=Bogons
add address=198.18.0.0/15 comment="RFC 2544 (Benchmarking)" list=Bogons
add address=198.51.100.0/24 comment="RFC 5737 (Test-Net-2)" list=Bogons
add address=203.0.113.0/24 comment="RFC 5737 (Test-Net-3)" list=Bogons
add address=224.0.0.0/4 comment="RFC 5771 (Multicast Addresses) - Will affect \
    OSPF, RIP, PIM, VRRP, IS-IS, and others. Use with caution.)" disabled=yes \
    list=Bogons
add address=240.0.0.0/4 comment="RFC 1112 (Reserved)" list=Bogons
add address=192.31.196.0/24 comment="RFC 7535 (AS112-v4)" list=Bogons
add address=192.52.193.0/24 comment="RFC 7450 (AMT)" list=Bogons
add address=192.88.99.0/24 comment=\
    "RFC 7526 (Deprecated (6to4 Relay Anycast))" list=Bogons
add address=192.175.48.0/24 comment=\
    "RFC 7534 (Direct Delegation AS112 Service)" list=Bogons
add address=255.255.255.255 comment="RFC 919 (Limited Broadcast)" disabled=\
    yes list=Bogons
add address=10.0.0.0/8 comment=ROUTING-GAME-BY-BNT list=LOCAL-IP
add address=172.16.0.0/12 comment=ROUTING-GAME-BY-BNT list=LOCAL-IP
add address=192.168.0.0/16 comment=ROUTING-GAME-BY-BNT list=LOCAL-IP
/ip firewall filter
add action=accept chain=forward comment=\
    "Allow established and related connections" connection-state=\
    established,related
add action=drop chain=input comment="BLOCK DDOS" dst-port=53 in-interface=\
    ether2 protocol=udp
add action=drop chain=input dst-port=53 in-interface=ether2 protocol=tcp
add action=drop chain=input comment="BLOCK DDOS" dst-port=53 in-interface=\
    ether1 protocol=udp
add action=drop chain=input dst-port=53 in-interface=ether1 protocol=tcp
add action=jump chain=input comment="Jump to RFC Bogon Chain" jump-target=\
    "RFC Bogon Chain"
add action=jump chain=forward comment="Jump to RFC Bogon Chain" jump-target=\
    "RFC Bogon Chain"
add action=drop chain="RFC Bogon Chain" comment=\
    "Drop all packets soured from Bogons" src-address-list=Bogons
add action=drop chain="RFC Bogon Chain" comment=\
    "Drop all packets destined to Bogons" dst-address-list=Bogons
add action=return chain="RFC Bogon Chain" comment=\
    "Return from RFC Bogon Chain"
add action=drop chain=forward comment="drop invalid connections" \
    connection-state=invalid protocol=tcp
add action=accept chain=forward comment="Accept Cache" src-address=\
    192.168.50.8
add action=jump chain=input comment="Jump to RFC ICMP Protection Chain" \
    jump-target="RFC ICMP Protection" protocol=icmp
add action=jump chain=forward comment="Jump to RFC ICMP Protection Chain" \
    jump-target="RFC ICMP Protection" protocol=icmp
add action=add-dst-to-address-list address-list="Suspected SMURF Attacks" \
    address-list-timeout=none-dynamic chain="RFC ICMP Protection" comment=\
    "Detect Suspected SMURF Attacks" dst-address-type=broadcast log=yes \
    log-prefix="FW-SMURF Attacks" protocol=icmp
add action=drop chain="RFC ICMP Protection" comment=\
    "Drop Suspected SMURF Attacks" dst-address-list="Suspected SMURF Attacks" \
    protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Accept Echo Requests" \
    icmp-options=8:0 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Accept Echo Replys" \
    icmp-options=0:0 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment=\
    "Accept Destination Network Unreachable" icmp-options=3:0 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment=\
    "Accept Destination Host Unreachable" icmp-options=3:1 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment=\
    "Accept Destination Port Unreachable" icmp-options=3:3 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment=\
    "Fragmentation Messages" icmp-options=3:4 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Source Route Failed" \
    icmp-options=3:5 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment=\
    "Network Admin Prohibited" icmp-options=3:9 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Host Admin Prohibited" \
    icmp-options=3:10 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Router Advertisemnet" \
    icmp-options=9:0 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Router Solicitation" \
    icmp-options=9:10 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment="Time Exceeded" \
    icmp-options=11:0-1 protocol=icmp
add action=accept chain="RFC ICMP Protection" comment=Traceroute \
    icmp-options=30:0 protocol=icmp
add action=drop chain="RFC ICMP Protection" comment=\
    "Drop ALL other ICMP Messages" log=yes log-prefix="FW-ICMP Protection" \
    protocol=icmp
add action=jump chain=input comment="Jump to RFC Port Scans" jump-target=\
    "RFC Port Scans" protocol=tcp
add action=jump chain=input comment="Jump to RFC Port Scans" jump-target=\
    "RFC Port Scans" protocol=udp
add action=jump chain=forward comment="Jump to RFC Port Scans" jump-target=\
    "RFC Port Scans" protocol=tcp
add action=jump chain=forward comment="Jump to RFC Port Scans" jump-target=\
    "RFC Port Scans" protocol=udp
add action=drop chain="RFC Port Scans" comment=\
    "Drop anyone in the WAN Port Scanner List" src-address-list=\
    "WAN Port Scanners"
add action=drop chain="RFC Port Scans" comment=\
    "Drop anyone in the WAN Port Scanner List" dst-address-list=\
    "WAN Port Scanners"
add action=drop chain="RFC Port Scans" comment=\
    "Drop anyone in the LAN Port Scanner List" src-address-list=\
    "LAN Port Scanners"
add action=drop chain="RFC Port Scans" comment=\
    "Drop anyone in the LAN Port Scanner List" dst-address-list=\
    "LAN Port Scanners"
add action=return chain="RFC Port Scans" comment="Return from RFC Port Scans"
add action=drop chain=input comment="Block bad actors" src-address-list=\
    Blocked
add action=drop chain=forward comment="Drop any traffic going to bad actors" \
    disabled=yes dst-address-list=Blocked
/ip firewall mangle
add action=mark-routing chain=output comment="PCC ROS7" new-routing-mark=\
    to-isp1 out-interface=ether1
add action=mark-routing chain=output new-routing-mark=to-isp2 out-interface=\
    ether2
add action=mark-connection chain=prerouting connection-mark=no-mark \
    dst-address-type=!local in-interface=ether3 new-connection-mark=isp1 \
    per-connection-classifier=both-addresses-and-ports:2/0
add action=mark-connection chain=prerouting connection-mark=no-mark \
    dst-address-type=!local in-interface=ether3 new-connection-mark=isp2 \
    per-connection-classifier=both-addresses-and-ports:2/1
add action=mark-connection chain=prerouting connection-mark=no-mark \
    dst-address-type=!local in-interface=ether4 new-connection-mark=isp1 \
    per-connection-classifier=both-addresses-and-ports:2/0
add action=mark-connection chain=prerouting connection-mark=no-mark \
    dst-address-type=!local in-interface=ether4 new-connection-mark=isp2 \
    per-connection-classifier=both-addresses-and-ports:2/1
add action=mark-connection chain=prerouting connection-mark=no-mark \
    dst-address-type=!local in-interface=ether5 new-connection-mark=isp1 \
    per-connection-classifier=both-addresses-and-ports:2/0
add action=mark-connection chain=prerouting connection-mark=no-mark \
    dst-address-type=!local in-interface=ether5 new-connection-mark=isp2 \
    per-connection-classifier=both-addresses-and-ports:2/1
add action=mark-routing chain=prerouting connection-mark=isp1 \
    new-routing-mark=to-isp1
add action=mark-routing chain=prerouting connection-mark=isp2 \
    new-routing-mark=to-isp2
add action=mark-packet chain=prerouting comment="PING QOS" dscp=0 \
    new-packet-mark=ping_pkts_i packet-size=64 passthrough=no protocol=icmp
add action=mark-packet chain=postrouting dscp=0 new-packet-mark=ping_pkts_o \
    packet-size=64 passthrough=no protocol=icmp
add action=change-dscp chain=forward comment=\
    "Assign DSCP values for registered ports" dst-port=1024-65535 new-dscp=32 \
    passthrough=no protocol=tcp
add action=change-dscp chain=forward dst-port=1024-65535 new-dscp=32 \
    passthrough=no protocol=udp
add action=change-dscp chain=forward comment="Voice RTP / VoIP" new-dscp=46 \
    packet-size=60-200 protocol=udp
add action=change-dscp chain=forward comment="Video Calls" new-dscp=34 \
    packet-size=200-1500 protocol=udp
add action=change-dscp chain=forward comment="Gaming / Interactive" new-dscp=\
    26 packet-size=60-500 protocol=udp
add action=change-dscp chain=forward comment="DNS UDP" new-dscp=40 port=53 \
    protocol=udp
add action=change-dscp chain=forward comment="DNS TCP" new-dscp=40 port=53 \
    protocol=tcp
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether2
add action=masquerade chain=srcnat out-interface=ether1
/ip firewall raw
add action=jump chain=prerouting comment="Jump to Game Chain" jump-target=\
    ports protocol=tcp
add action=jump chain=prerouting comment="Jump to Game Chain" jump-target=\
    ports protocol=udp
add action=add-dst-to-address-list address-list=List-IP-Ports \
    address-list-timeout=1h chain=ports comment="Port Corresponding IP/s" \
    dst-address-list=!LOCAL-IP dst-port=0-65535 protocol=tcp
add action=add-dst-to-address-list address-list=List-IP-Ports \
    address-list-timeout=1h chain=ports dst-address-list=!LOCAL-IP dst-port=\
    0-65535 protocol=udp
add action=return chain=ports comment="Return From Game Chain"
add action=jump chain=prerouting comment="Jump to Virus Chain" jump-target=\
    Virus protocol=tcp
add action=jump chain=prerouting comment="Jump to Virus Chain" jump-target=\
    Virus protocol=udp
add action=drop chain=Virus comment=Conficker dst-port=593 protocol=tcp
add action=drop chain=Virus comment=Worm dst-port=1024-1030 protocol=tcp
add action=drop chain=Virus comment="ndm requester" dst-port=1363 protocol=\
    tcp
add action=drop chain=Virus comment="ndm server" dst-port=1364 protocol=tcp
add action=drop chain=Virus comment="screen cast" dst-port=1368 protocol=tcp
add action=drop chain=Virus comment=hromgrafx dst-port=1373 protocol=tcp
add action=drop chain=Virus comment="Drop MyDoom" dst-port=1080 protocol=tcp
add action=drop chain=Virus comment=cichlid dst-port=1377 protocol=tcp
add action=drop chain=Virus comment=Worm dst-port=1433-1434 protocol=tcp
add action=drop chain=Virus comment="Drop Dumaru.Y" dst-port=2283 protocol=\
    tcp
add action=drop chain=Virus comment="Drop Beagle" dst-port=2535 protocol=tcp
add action=drop chain=Virus comment="Drop Beagle.C-K" dst-port=2745 protocol=\
    tcp
add action=drop chain=Virus comment="Drop Backdoor OptixPro" dst-port=3410 \
    protocol=tcp
add action=drop chain=Virus comment="Drop Sasser" dst-port=5554 protocol=tcp
add action=drop chain=Virus comment=Worm dst-port=4444 protocol=tcp
add action=drop chain=Virus comment=Worm dst-port=4444 protocol=udp
add action=drop chain=Virus comment="Drop Beagle.B" dst-port=8866 protocol=\
    tcp
add action=drop chain=Virus comment="Drop Dabber.A-B" dst-port=9898 protocol=\
    tcp
add action=drop chain=Virus comment="Drop SubSeven" dst-port=27374 protocol=\
    tcp
add action=drop chain=Virus comment="Drop PhatBot, Agobot, Gaobot" dst-port=\
    65506 protocol=tcp
add action=return chain=Virus comment="Return From Virus Chain"
/ip ipsec profile
set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip proxy
set parent-proxy=0.0.0.0
/ip route
add disabled=no distance=1 dst-address=192.168.0.0/24 gateway=10.0.0.2 \
    pref-src="" routing-table=main scope=30 suppress-hw-offload=no \
    target-scope=10
add disabled=no distance=1 dst-address=172.17.0.0/24 gateway=10.0.0.2 \
    pref-src="" routing-table=main scope=30 suppress-hw-offload=no \
    target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=0.0.0.0/0 gateway=\
    192.168.50.8 pref-src="" routing-table=raptor_route scope=30 \
    suppress-hw-offload=no target-scope=10
add disabled=no distance=2 dst-address=0.0.0.0/0 gateway=192.168.1.1%ether2 \
    routing-table=raptor_route scope=30 suppress-hw-offload=no target-scope=\
    10
add check-gateway=ping disabled=no distance=1 dst-address=1.1.1.1/32 gateway=\
    192.168.1.1%ether2 routing-table=to-isp2 scope=30 suppress-hw-offload=no \
    target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=8.8.8.8/32 gateway=\
    192.168.1.1%ether1 routing-table=to-isp1 scope=30 suppress-hw-offload=no \
    target-scope=10
add disabled=no distance=3 dst-address=0.0.0.0/0 gateway=192.168.1.1%ether1 \
    routing-table=raptor_route scope=30 suppress-hw-offload=no target-scope=\
    10
add check-gateway=ping disabled=no distance=1 dst-address=0.0.0.0/0 gateway=\
    8.8.8.8 routing-table=main scope=30 suppress-hw-offload=no target-scope=\
    11
add disabled=no distance=1 dst-address=8.8.8.8/32 gateway=192.168.1.1%ether1 \
    routing-table=main scope=10 suppress-hw-offload=no target-scope=10
add disabled=no distance=2 dst-address=1.1.1.1/32 gateway=192.168.1.1%ether2 \
    routing-table=main scope=10 suppress-hw-offload=no target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=0.0.0.0/0 gateway=\
    1.1.1.1 routing-table=main scope=30 suppress-hw-offload=no target-scope=\
    11
/ip service
set ftp disabled=yes
set ssh address=192.168.50.0/28,10.0.50.0/24
set telnet disabled=yes
set www disabled=yes
set winbox address=10.0.50.0/24,192.168.50.0/28
set api address=192.168.50.0/28,10.0.50.0/24
set api-ssl disabled=yes
/ip smb shares
set [ find default=yes ] directory=/flash/pub
/ip ssh
set ciphers=aes-gcm,aes-ctr,aes-cbc,3des-cbc,null forwarding-enabled=remote
/routing bfd configuration
add disabled=no
/snmp
set enabled=yes location=home trap-target=192.168.50.11 trap-version=2
/system clock
set time-zone-name=Asia/Manila
/system identity
set name=JERIC-DOMAIN
/system logging
set 0 action=echo disabled=yes
set 1 action=echo
set 2 action=echo
add action=echo prefix=-> topics=info,debug
add action=echo prefix=-> topics=info,debug
/system ntp client
set enabled=yes
/system ntp client servers
add address=pool.ntp.org
add address=asia.pool.ntp.org
/system package update
set channel=long-term
/tool sniffer
set filter-cpu=3 filter-interface=ether1,ether2 streaming-enabled=yes \
    streaming-server=192.168.50.7
