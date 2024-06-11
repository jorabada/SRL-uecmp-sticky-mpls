# SRL-ip-aliasing-centralized-routing-mpls

This lab shows an example of the Centralized Routing architecture deployed with EVPN IFL IP Aliasing for MPLS tunnels. The lab is depicted in the following diagram:

![](srl-ip-aliasing-centralized-routing-mpls.drawio.png)

And consists of the following nodes:

- server1..server2
- leaf1..leaf4
- anchor5..anchor6
- borderleaf1..borderleaf2
- client1..client2

## Configurations

### Server Nodes

The server nodes are SRLinux IXR D2 routers and simulate servers that are dual-homed to a pair of leaf routers in a layer-2 all-active multi-homing Ethernet Segment. The servers are configured with IP-VRF-2, where a loopback with multiple prefixes is configured. The servers also have two EBGP PE-CE sessions to the anchor nodes. This example shows the configuration of server1 (the configuratino of server2 is equivalent).

<pre>
# interface configuration

--{ candidate shared default }--[  ]--
A:server1# info flat interface *
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 ethernet aggregate-id lag1
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/2 ethernet aggregate-id lag1
set / interface lag1 vlan-tagging true
set / interface lag1 subinterface 1 type routed
set / interface lag1 subinterface 1 ipv4 admin-state enable
set / interface lag1 subinterface 1 ipv4 address 10.10.10.1/24
set / interface lag1 subinterface 1 vlan encap single-tagged vlan-id 1
set / interface lo1 subinterface 1 ipv4 admin-state enable
set / interface lo1 subinterface 1 ipv4 address 192.168.1.1/24
set / interface lo1 subinterface 1 ipv4 address 192.168.2.1/24
set / interface lo1 subinterface 1 ipv4 address 192.168.3.1/24
set / interface mgmt0 admin-state enable
set / interface mgmt0 subinterface 0 admin-state enable
set / interface mgmt0 subinterface 0 ip-mtu 1500
set / interface mgmt0 subinterface 0 ipv4 admin-state enable
set / interface mgmt0 subinterface 0 ipv4 dhcp-client
set / interface mgmt0 subinterface 0 ipv6 admin-state enable
set / interface mgmt0 subinterface 0 ipv6 dhcp-client

# IP-VRF-2 configuration

--{ candidate shared default }--[  ]--
A:server1# info flat network-instance IP-VRF-2
set / network-instance IP-VRF-2 type ip-vrf
set / network-instance IP-VRF-2 interface lag1.1
set / network-instance IP-VRF-2 interface lo1.1
set / network-instance IP-VRF-2 protocols bgp autonomous-system 64501
set / network-instance IP-VRF-2 protocols bgp router-id 10.10.10.1
set / network-instance IP-VRF-2 protocols bgp ebgp-default-policy import-reject-all false
set / network-instance IP-VRF-2 protocols bgp ebgp-default-policy export-reject-all false
set / network-instance IP-VRF-2 protocols bgp afi-safi ipv4-unicast admin-state enable
set / network-instance IP-VRF-2 protocols bgp trace-options flag packets modifier detail
set / network-instance IP-VRF-2 protocols bgp trace-options flag update modifier detail
set / network-instance IP-VRF-2 protocols bgp group pe-ce peer-as 64500
set / network-instance IP-VRF-2 protocols bgp group pe-ce export-policy [ export-local-prefixes ]
set / network-instance IP-VRF-2 protocols bgp group pe-ce multihop admin-state enable
set / network-instance IP-VRF-2 protocols bgp group pe-ce multihop maximum-hops 10
set / network-instance IP-VRF-2 protocols bgp group pe-ce afi-safi ipv4-unicast
set / network-instance IP-VRF-2 protocols bgp group pe-ce timers connect-retry 1
set / network-instance IP-VRF-2 protocols bgp group pe-ce timers minimum-advertisement-interval 1
set / network-instance IP-VRF-2 protocols bgp group pe-ce trace-options flag update modifier detail
set / network-instance IP-VRF-2 protocols bgp neighbor 5.5.5.5 peer-group pe-ce
set / network-instance IP-VRF-2 protocols bgp neighbor 6.6.6.6 peer-group pe-ce
set / network-instance IP-VRF-2 static-routes route 0.0.0.0/0 admin-state enable
set / network-instance IP-VRF-2 static-routes route 0.0.0.0/0 next-hop-group 1
set / network-instance IP-VRF-2 next-hop-groups group 1 admin-state enable
set / network-instance IP-VRF-2 next-hop-groups group 1 nexthop 1 ip-address 10.10.10.254
set / network-instance IP-VRF-2 next-hop-groups group 1 nexthop 1 admin-state enable
--{ candidate shared default }--[  ]--

# policy config

--{ candidate shared default }--[  ]--
A:server1# info flat routing-policy
set / routing-policy prefix-set 192.168-prefixes prefix 192.168.0.0/16 mask-length-range 16..24
set / routing-policy policy export-local-prefixes statement 10 match prefix-set 192.168-prefixes
set / routing-policy policy export-local-prefixes statement 10 match protocol local
set / routing-policy policy export-local-prefixes statement 10 action policy-result accept
--{ candidate shared default }--[  ]--

</pre>

### Leaf Nodes

The leaf nodes are attached to a MAC-VRF (MAC-VRF-1 on Leaf1 and Leaf2, and MAC-VRF-3 in Leaf3 and Leaf4). The MAC-VRF has an IRB interface linked to IP-VRF-2 in the core. The network-instances use EVPN MPLS. In addition, a layer-3 Ethernet Segment per server is configured on the leaf routers.

Example of config in Leaf1 (same in Leaf2) and Leaf3 (same config in Leaf4).

#### Leaf1

<pre>
# interfaces

A:leaf1#
--{ candidate shared default }--[  ]--
A:leaf1# info flat interface *
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 vlan-tagging true
set / interface ethernet-1/1 subinterface 1 type bridged
set / interface ethernet-1/1 subinterface 1 admin-state enable
set / interface ethernet-1/1 subinterface 1 vlan encap single-tagged vlan-id 1
set / interface ethernet-1/39 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv4 address 10.1.11.1/30
set / interface ethernet-1/39 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv6 address 2001:db8:10:1:11::1/80
set / interface ethernet-1/40 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv4 address 10.1.12.1/30
set / interface ethernet-1/40 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv6 address 2001:db8:10:1:12::2/80
set / interface irb0 subinterface 1 ipv4 admin-state enable
set / interface irb0 subinterface 1 ipv4 address 10.10.10.254/24 anycast-gw true
set / interface irb0 subinterface 1 ipv4 arp learn-unsolicited true
set / interface irb0 subinterface 1 ipv4 arp host-route populate dynamic
set / interface irb0 subinterface 1 ipv4 arp evpn advertise dynamic
set / interface irb0 subinterface 1 anycast-gw
set / interface lo0 subinterface 1 ipv4 admin-state enable
set / interface lo0 subinterface 1 ipv4 address 1.1.1.1/32
set / interface mgmt0 admin-state enable
set / interface mgmt0 subinterface 0 admin-state enable
set / interface mgmt0 subinterface 0 ip-mtu 1500
set / interface mgmt0 subinterface 0 ipv4 admin-state enable
set / interface mgmt0 subinterface 0 ipv4 dhcp-client
set / interface mgmt0 subinterface 0 ipv6 admin-state enable
set / interface mgmt0 subinterface 0 ipv6 dhcp-client
set / interface system0 subinterface 0 ipv4 admin-state enable
set / interface system0 subinterface 0 ipv4 address 100.0.0.1/32
set / interface system0 subinterface 0 ipv6 admin-state enable
set / interface system0 subinterface 0 ipv6 address 2001:db8::1/128
--{ candidate shared default }--[  ]--

# network-instances

--{ candidate shared default }--[  ]--
A:leaf1# info flat network-instance *
set / network-instance IP-VRF-2 type ip-vrf
set / network-instance IP-VRF-2 description "IP-VRF-2 EVPN-MPLS and MH with IRB"
set / network-instance IP-VRF-2 interface irb0.1
set / network-instance IP-VRF-2 interface lo0.1
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 evi 2
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 ecmp 4
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [ ldp sr-isis ]
set / network-instance IP-VRF-2 protocols bgp-vpn bgp-instance 1
set / network-instance MAC-VRF-1 type mac-vrf
set / network-instance MAC-VRF-1 description "MAC-VRF-1 EVPN-MPLS and MH"
set / network-instance MAC-VRF-1 interface ethernet-1/1.1
set / network-instance MAC-VRF-1 interface irb0.1
set / network-instance MAC-VRF-1 protocols bgp-evpn bgp-instance 1 admin-state enable
set / network-instance MAC-VRF-1 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
set / network-instance MAC-VRF-1 protocols bgp-evpn bgp-instance 1 evi 1
set / network-instance MAC-VRF-1 protocols bgp-evpn bgp-instance 1 ecmp 4
set / network-instance MAC-VRF-1 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [ ldp sr-isis ]
set / network-instance MAC-VRF-1 protocols bgp-vpn bgp-instance 1
set / network-instance default type default
set / network-instance default interface ethernet-1/39.0
set / network-instance default interface ethernet-1/40.0
set / network-instance default interface system0.0
set / network-instance default protocols bgp autonomous-system 64500
set / network-instance default protocols bgp router-id 100.0.0.1
set / network-instance default protocols bgp ebgp-default-policy import-reject-all false
set / network-instance default protocols bgp ebgp-default-policy export-reject-all false
set / network-instance default protocols bgp afi-safi evpn admin-state enable
set / network-instance default protocols bgp afi-safi evpn evpn keep-all-routes true
set / network-instance default protocols bgp afi-safi evpn evpn rapid-update true
set / network-instance default protocols bgp trace-options flag update modifier detail
set / network-instance default protocols bgp group overlay peer-as 64500
set / network-instance default protocols bgp group overlay afi-safi evpn
set / network-instance default protocols bgp group overlay timers connect-retry 1
set / network-instance default protocols bgp group overlay timers minimum-advertisement-interval 1
set / network-instance default protocols bgp group overlay trace-options flag update modifier detail
set / network-instance default protocols bgp neighbor 100.0.0.11 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.12 peer-group overlay
set / network-instance default protocols ldp admin-state enable
set / network-instance default protocols ldp dynamic-label-block range-1-ldp
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/39.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/39.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/40.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/40.0 ipv6 admin-state enable
set / network-instance default protocols ldp peers trace-options trace [ messages-initialization-detail messages-label-detail ]
set / network-instance default protocols isis dynamic-label-block range-3-srgb
set / network-instance default protocols isis instance i1 admin-state enable
set / network-instance default protocols isis instance i1 level-capability L2
set / network-instance default protocols isis instance i1 net [ 49.0001.0000.0000.0001.00 ]
set / network-instance default protocols isis instance i1 segment-routing mpls dynamic-adjacency-sids all-interfaces true
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 passive true
set / network-instance default protocols isis instance i1 interface system0.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 ipv6-unicast admin-state enable
set / network-instance default segment-routing mpls global-block label-range range-2-srgb
set / network-instance default segment-routing mpls local-prefix-sid 1 interface system0.0
set / network-instance default segment-routing mpls local-prefix-sid 1 ipv4-label-index 1

# Ethernet Segments

--{ candidate shared default }--[  ]--
A:leaf1# info flat system network-instance
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 type virtual
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 admin-state enable
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 esi 01:10:10:10:01:00:00:00:00:00
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 next-hop 10.10.10.1 evi 2
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-Server-1 admin-state enable
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-Server-1 esi 01:01:00:00:00:00:00:00:00:00
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-Server-1 interface ethernet-1/1
set / system network-instance protocols bgp-vpn bgp-instance 1
--{ candidate shared default }--[  ]--

</pre>

#### Leaf3

<pre>
# Interfaces

--{ + candidate shared default }--[  ]--
A:leaf3# info flat interface *
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 vlan-tagging true
set / interface ethernet-1/1 subinterface 1 type bridged
set / interface ethernet-1/1 subinterface 1 admin-state enable
set / interface ethernet-1/1 subinterface 1 vlan encap single-tagged vlan-id 1
set / interface ethernet-1/39 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv4 address 10.3.11.1/30
set / interface ethernet-1/39 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv6 address 2001:db8:10:3:11::1/80
set / interface ethernet-1/40 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv4 address 10.3.12.1/30
set / interface ethernet-1/40 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv6 address 2001:db8:10:3:12::2/80
set / interface irb0 subinterface 1 ipv4 admin-state enable
set / interface irb0 subinterface 1 ipv4 address 20.20.20.254/24 anycast-gw true
set / interface irb0 subinterface 1 ipv4 arp learn-unsolicited true
set / interface irb0 subinterface 1 ipv4 arp host-route populate dynamic
set / interface irb0 subinterface 1 ipv4 arp evpn advertise dynamic
set / interface irb0 subinterface 1 anycast-gw
set / interface lo0 subinterface 1 ipv4 admin-state enable
set / interface lo0 subinterface 1 ipv4 address 3.3.3.3/32
set / interface mgmt0 admin-state enable
set / interface mgmt0 subinterface 0 admin-state enable
set / interface mgmt0 subinterface 0 ip-mtu 1500
set / interface mgmt0 subinterface 0 ipv4 admin-state enable
set / interface mgmt0 subinterface 0 ipv4 dhcp-client
set / interface mgmt0 subinterface 0 ipv6 admin-state enable
set / interface mgmt0 subinterface 0 ipv6 dhcp-client
set / interface system0 subinterface 0 ipv4 admin-state enable
set / interface system0 subinterface 0 ipv4 address 100.0.0.3/32
set / interface system0 subinterface 0 ipv6 admin-state enable
set / interface system0 subinterface 0 ipv6 address 2001:db8::3/128

# network instances

A:leaf3#
--{ + candidate shared default }--[  ]--
A:leaf3# info flat network-instance *
set / network-instance IP-VRF-2 type ip-vrf
set / network-instance IP-VRF-2 description "IP-VRF-2 EVPN-MPLS and MH with IRB"
set / network-instance IP-VRF-2 interface irb0.1
set / network-instance IP-VRF-2 interface lo0.1
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 evi 2
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 ecmp 4
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [ ldp sr-isis ]
set / network-instance IP-VRF-2 protocols bgp-vpn bgp-instance 1
set / network-instance MAC-VRF-3 type mac-vrf
set / network-instance MAC-VRF-3 description "MAC-VRF-3 EVPN-MPLS and MH"
set / network-instance MAC-VRF-3 interface ethernet-1/1.1
set / network-instance MAC-VRF-3 interface irb0.1
set / network-instance MAC-VRF-3 protocols bgp-evpn bgp-instance 1 admin-state enable
set / network-instance MAC-VRF-3 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
set / network-instance MAC-VRF-3 protocols bgp-evpn bgp-instance 1 evi 3
set / network-instance MAC-VRF-3 protocols bgp-evpn bgp-instance 1 ecmp 4
set / network-instance MAC-VRF-3 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [ ldp sr-isis ]
set / network-instance MAC-VRF-3 protocols bgp-vpn bgp-instance 1
set / network-instance default type default
set / network-instance default interface ethernet-1/39.0
set / network-instance default interface ethernet-1/40.0
set / network-instance default interface system0.0
set / network-instance default protocols bgp autonomous-system 64500
set / network-instance default protocols bgp router-id 100.0.0.3
set / network-instance default protocols bgp ebgp-default-policy import-reject-all false
set / network-instance default protocols bgp ebgp-default-policy export-reject-all false
set / network-instance default protocols bgp afi-safi evpn admin-state enable
set / network-instance default protocols bgp afi-safi evpn evpn keep-all-routes true
set / network-instance default protocols bgp afi-safi evpn evpn rapid-update true
set / network-instance default protocols bgp trace-options flag update modifier detail
set / network-instance default protocols bgp group overlay peer-as 64500
set / network-instance default protocols bgp group overlay afi-safi evpn
set / network-instance default protocols bgp group overlay timers connect-retry 1
set / network-instance default protocols bgp group overlay timers minimum-advertisement-interval 1
set / network-instance default protocols bgp group overlay trace-options flag update modifier detail
set / network-instance default protocols bgp neighbor 100.0.0.11 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.12 peer-group overlay
set / network-instance default protocols ldp admin-state enable
set / network-instance default protocols ldp dynamic-label-block range-1-ldp
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/39.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/39.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/40.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/40.0 ipv6 admin-state enable
set / network-instance default protocols ldp peers trace-options trace [ messages-initialization-detail messages-label-detail ]
set / network-instance default protocols isis dynamic-label-block range-3-srgb
set / network-instance default protocols isis instance i1 admin-state enable
set / network-instance default protocols isis instance i1 level-capability L2
set / network-instance default protocols isis instance i1 net [ 49.0001.0000.0000.0003.00 ]
set / network-instance default protocols isis instance i1 segment-routing mpls dynamic-adjacency-sids all-interfaces true
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 passive true
set / network-instance default protocols isis instance i1 interface system0.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 ipv6-unicast admin-state enable
set / network-instance default segment-routing mpls global-block label-range range-2-srgb
set / network-instance default segment-routing mpls local-prefix-sid 1 interface system0.0
set / network-instance default segment-routing mpls local-prefix-sid 1 ipv4-label-index 3

# Ethernet Segments

A:leaf3#
--{ + candidate shared default }--[  ]--
A:leaf3# info flat system network-instance
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 type virtual
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 admin-state enable
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 esi 01:20:20:20:01:00:00:00:00:00
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 next-hop 20.20.20.1 evi 2
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-Server-2 admin-state enable
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-Server-2 esi 01:02:00:00:00:00:00:00:00:00
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-Server-2 interface ethernet-1/1
set / system network-instance protocols bgp-vpn bgp-instance 1
--{ + candidate shared default }--[  ]--

</pre>

### Anchor Nodes

The anchor nodes centralize the PE-CE BGP sessions from all the servers. And because they are also attached to the layer-3 Ethernet Segments of the servers, they readvertise the server prefixes with the proper ESI (in the EVPN IFL routes). Since the anchor nodes resolve the layer-3 ES next-hops to an EVPN route, they will not advertise AD per-ES/EVI routes for the Ethernet Segments, and therefore will not attract traffic to the servers.

The benefit of the centralized architecture is that:
a) The configuration of the servers is cookie-cutter - the BGP sessions are configured to the redundant anchor leaf routers on all servers, instead of to each individual leaf.
b) The leaf routers do not need a PE-CE session, hence its configuration is much more cleaner.
c) A failure or recovery on the Leaf routers will not mean bringing down and up any PE-CE BGP sessions.
d) and all the above without any traffic tromboning - since the downstream traffic from the borderleaf routers is forwarded directly to the leaf routers.

The following excerpt shows the config in anchor5 (the config in anchor6 is equivalent).

<pre>

# interfaces

A:anchor5#
--{ candidate shared default }--[  ]--
A:anchor5# info flat interface *
set / interface ethernet-1/39 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv4 address 10.5.11.1/30
set / interface ethernet-1/39 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/39 subinterface 0 ipv6 address 2001:db8:10:5:11::1/80
set / interface ethernet-1/40 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv4 address 10.5.12.1/30
set / interface ethernet-1/40 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/40 subinterface 0 ipv6 address 2001:db8:10:5:12::2/80
set / interface lo0 subinterface 1 ipv4 admin-state enable
set / interface lo0 subinterface 1 ipv4 address 5.5.5.5/32
set / interface mgmt0 admin-state enable
set / interface mgmt0 subinterface 0 admin-state enable
set / interface mgmt0 subinterface 0 ip-mtu 1500
set / interface mgmt0 subinterface 0 ipv4 admin-state enable
set / interface mgmt0 subinterface 0 ipv4 dhcp-client
set / interface mgmt0 subinterface 0 ipv6 admin-state enable
set / interface mgmt0 subinterface 0 ipv6 dhcp-client
set / interface system0 subinterface 0 ipv4 admin-state enable
set / interface system0 subinterface 0 ipv4 address 100.0.0.5/32
set / interface system0 subinterface 0 ipv6 admin-state enable
set / interface system0 subinterface 0 ipv6 address 2001:db8::5/128
--{ candidate shared default }--[  ]--

# network instances

--{ candidate shared default }--[  ]--
A:anchor5# info flat network-instance *
set / network-instance IP-VRF-2 type ip-vrf
set / network-instance IP-VRF-2 admin-state enable
set / network-instance IP-VRF-2 description "IP-VRF-2 EVPN-MPLS"
set / network-instance IP-VRF-2 interface lo0.1
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 evi 2
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 ecmp 4
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [ ldp sr-isis ]
set / network-instance IP-VRF-2 protocols bgp autonomous-system 64500
set / network-instance IP-VRF-2 protocols bgp router-id 5.5.5.5
set / network-instance IP-VRF-2 protocols bgp ebgp-default-policy import-reject-all false
set / network-instance IP-VRF-2 protocols bgp ebgp-default-policy export-reject-all false
set / network-instance IP-VRF-2 protocols bgp afi-safi ipv4-unicast admin-state enable
set / network-instance IP-VRF-2 protocols bgp trace-options flag packets modifier detail
set / network-instance IP-VRF-2 protocols bgp trace-options flag update modifier detail
set / network-instance IP-VRF-2 protocols bgp group pe-ce multihop admin-state enable
set / network-instance IP-VRF-2 protocols bgp group pe-ce multihop maximum-hops 10
set / network-instance IP-VRF-2 protocols bgp group pe-ce afi-safi ipv4-unicast
set / network-instance IP-VRF-2 protocols bgp group pe-ce timers connect-retry 1
set / network-instance IP-VRF-2 protocols bgp group pe-ce timers minimum-advertisement-interval 1
set / network-instance IP-VRF-2 protocols bgp group pe-ce trace-options flag update modifier detail
set / network-instance IP-VRF-2 protocols bgp group pe-ce transport local-address 5.5.5.5
set / network-instance IP-VRF-2 protocols bgp neighbor 10.10.10.1 peer-as 64501
set / network-instance IP-VRF-2 protocols bgp neighbor 10.10.10.1 peer-group pe-ce
set / network-instance IP-VRF-2 protocols bgp neighbor 20.20.20.1 peer-as 64502
set / network-instance IP-VRF-2 protocols bgp neighbor 20.20.20.1 peer-group pe-ce
set / network-instance IP-VRF-2 protocols bgp-vpn bgp-instance 1
set / network-instance default type default
set / network-instance default interface ethernet-1/39.0
set / network-instance default interface ethernet-1/40.0
set / network-instance default interface system0.0
set / network-instance default protocols bgp autonomous-system 64500
set / network-instance default protocols bgp router-id 100.0.0.5
set / network-instance default protocols bgp ebgp-default-policy import-reject-all false
set / network-instance default protocols bgp ebgp-default-policy export-reject-all false
set / network-instance default protocols bgp afi-safi evpn admin-state enable
set / network-instance default protocols bgp afi-safi evpn evpn keep-all-routes true
set / network-instance default protocols bgp afi-safi evpn evpn rapid-update true
set / network-instance default protocols bgp trace-options flag update modifier detail
set / network-instance default protocols bgp group overlay peer-as 64500
set / network-instance default protocols bgp group overlay afi-safi evpn
set / network-instance default protocols bgp group overlay timers connect-retry 1
set / network-instance default protocols bgp group overlay timers minimum-advertisement-interval 1
set / network-instance default protocols bgp group overlay trace-options flag update modifier detail
set / network-instance default protocols bgp neighbor 100.0.0.11 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.12 peer-group overlay
set / network-instance default protocols ldp admin-state enable
set / network-instance default protocols ldp dynamic-label-block range-1-ldp
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/39.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/39.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/40.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/40.0 ipv6 admin-state enable
set / network-instance default protocols ldp peers trace-options trace [ messages-initialization-detail messages-label-detail ]
set / network-instance default protocols isis dynamic-label-block range-3-srgb
set / network-instance default protocols isis instance i1 admin-state enable
set / network-instance default protocols isis instance i1 level-capability L2
set / network-instance default protocols isis instance i1 net [ 49.0001.0000.0000.0005.00 ]
set / network-instance default protocols isis instance i1 segment-routing mpls dynamic-adjacency-sids all-interfaces true
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/39.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/40.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 passive true
set / network-instance default protocols isis instance i1 interface system0.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 ipv6-unicast admin-state enable
set / network-instance default segment-routing mpls global-block label-range range-2-srgb
set / network-instance default segment-routing mpls local-prefix-sid 1 interface system0.0
set / network-instance default segment-routing mpls local-prefix-sid 1 ipv4-label-index 5

# Ethernet Segments

A:anchor5#
--{ candidate shared default }--[  ]--
A:anchor5# info flat system network-instance
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 type virtual
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 admin-state enable
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 esi 01:10:10:10:01:00:00:00:00:00
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-1 next-hop 10.10.10.1 evi 2
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 type virtual
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 admin-state enable
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 esi 01:20:20:20:01:00:00:00:00:00
set / system network-instance protocols evpn ethernet-segments bgp-instance 1 ethernet-segment ES-L3-Server-2 next-hop 20.20.20.1 evi 2
set / system network-instance protocols bgp-vpn bgp-instance 1
--{ candidate shared default }--[  ]--

</pre>

### Border Leaf routers

The config on the borderleaf routers is a normal EVPN IFL config. The borderleaf routers act as RRs for the EVPN sessions.

<pre>

# interfaces

A:borderleaf2#
--{ candidate shared default }--[  ]--
A:borderleaf2# info flat interface *
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 vlan-tagging true
set / interface ethernet-1/1 subinterface 1 type routed
set / interface ethernet-1/1 subinterface 1 admin-state enable
set / interface ethernet-1/1 subinterface 1 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 1 ipv4 address 200.0.0.1/24
set / interface ethernet-1/1 subinterface 1 vlan encap single-tagged vlan-id 1
set / interface ethernet-1/21 admin-state enable
set / interface ethernet-1/21 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/21 subinterface 0 ipv4 address 10.1.12.2/30
set / interface ethernet-1/21 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/21 subinterface 0 ipv6 address 2001:db8:10:1:12::2/80
set / interface ethernet-1/22 admin-state enable
set / interface ethernet-1/22 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/22 subinterface 0 ipv4 address 10.2.12.2/30
set / interface ethernet-1/22 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/22 subinterface 0 ipv6 address 2001:db8:10:2:12::2/80
set / interface ethernet-1/23 admin-state enable
set / interface ethernet-1/23 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/23 subinterface 0 ipv4 address 10.3.12.2/30
set / interface ethernet-1/23 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/23 subinterface 0 ipv6 address 2001:db8:10:3:12::2/80
set / interface ethernet-1/24 admin-state enable
set / interface ethernet-1/24 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/24 subinterface 0 ipv4 address 10.4.12.2/30
set / interface ethernet-1/24 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/24 subinterface 0 ipv6 address 2001:db8:10:4:12::2/80
set / interface ethernet-1/25 admin-state enable
set / interface ethernet-1/25 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/25 subinterface 0 ipv4 address 10.5.12.2/30
set / interface ethernet-1/25 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/25 subinterface 0 ipv6 address 2001:db8:10:5:12::2/80
set / interface ethernet-1/26 admin-state enable
set / interface ethernet-1/26 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/26 subinterface 0 ipv4 address 10.6.12.2/30
set / interface ethernet-1/26 subinterface 0 ipv6 admin-state enable
set / interface ethernet-1/26 subinterface 0 ipv6 address 2001:db8:10:6:12::2/80
set / interface lo0 subinterface 1 ipv4 admin-state enable
set / interface lo0 subinterface 1 ipv4 address 12.12.12.12/32
set / interface system0 subinterface 0 ipv4 admin-state enable
set / interface system0 subinterface 0 ipv4 address 100.0.0.12/32
set / interface system0 subinterface 0 ipv6 admin-state enable
set / interface system0 subinterface 0 ipv6 address 2001:db8::12/128

# network instances

--{ candidate shared default }--[  ]--
A:borderleaf2#
--{ candidate shared default }--[  ]--
A:borderleaf2# info flat network-instance *
set / network-instance IP-VRF-2 type ip-vrf
set / network-instance IP-VRF-2 description "IP-VRF-2 EVPN-MPLS"
set / network-instance IP-VRF-2 interface ethernet-1/1.1
set / network-instance IP-VRF-2 interface lo0.1
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 encapsulation-type mpls
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 evi 2
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 ecmp 4
set / network-instance IP-VRF-2 protocols bgp-evpn bgp-instance 1 mpls next-hop-resolution allowed-tunnel-types [ ldp sr-isis ]
set / network-instance IP-VRF-2 protocols bgp-vpn bgp-instance 1
set / network-instance default type default
set / network-instance default interface ethernet-1/21.0
set / network-instance default interface ethernet-1/22.0
set / network-instance default interface ethernet-1/23.0
set / network-instance default interface ethernet-1/24.0
set / network-instance default interface ethernet-1/25.0
set / network-instance default interface ethernet-1/26.0
set / network-instance default interface system0.0
set / network-instance default protocols bgp autonomous-system 64500
set / network-instance default protocols bgp router-id 100.0.0.12
set / network-instance default protocols bgp ebgp-default-policy import-reject-all false
set / network-instance default protocols bgp ebgp-default-policy export-reject-all false
set / network-instance default protocols bgp afi-safi evpn admin-state enable
set / network-instance default protocols bgp afi-safi evpn evpn keep-all-routes true
set / network-instance default protocols bgp afi-safi evpn evpn rapid-update true
set / network-instance default protocols bgp route-reflector client true
set / network-instance default protocols bgp route-reflector cluster-id 12.12.12.12
set / network-instance default protocols bgp trace-options flag update modifier detail
set / network-instance default protocols bgp group overlay peer-as 64500
set / network-instance default protocols bgp group overlay afi-safi evpn
set / network-instance default protocols bgp group overlay timers connect-retry 1
set / network-instance default protocols bgp group overlay timers minimum-advertisement-interval 1
set / network-instance default protocols bgp group overlay trace-options flag update modifier detail
set / network-instance default protocols bgp neighbor 100.0.0.1 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.2 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.3 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.4 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.5 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.6 peer-group overlay
set / network-instance default protocols bgp neighbor 100.0.0.11 peer-group overlay
set / network-instance default protocols ldp admin-state enable
set / network-instance default protocols ldp dynamic-label-block range-1-ldp
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/21.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/21.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/22.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/22.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/23.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/23.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/24.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/24.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/25.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/25.0 ipv6 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/26.0 ipv4 admin-state enable
set / network-instance default protocols ldp discovery interfaces interface ethernet-1/26.0 ipv6 admin-state enable
set / network-instance default protocols ldp peers trace-options trace [ messages-initialization-detail messages-label-detail ]
set / network-instance default protocols isis dynamic-label-block range-3-srgb
set / network-instance default protocols isis instance i1 admin-state enable
set / network-instance default protocols isis instance i1 level-capability L2
set / network-instance default protocols isis instance i1 net [ 49.0001.0000.0000.0012.00 ]
set / network-instance default protocols isis instance i1 segment-routing mpls dynamic-adjacency-sids all-interfaces true
set / network-instance default protocols isis instance i1 interface ethernet-1/21.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/21.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/21.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/22.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/22.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/22.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/23.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/23.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/23.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/24.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/24.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/24.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/25.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/25.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/25.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/26.0 circuit-type point-to-point
set / network-instance default protocols isis instance i1 interface ethernet-1/26.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface ethernet-1/26.0 ipv6-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 passive true
set / network-instance default protocols isis instance i1 interface system0.0 ipv4-unicast admin-state enable
set / network-instance default protocols isis instance i1 interface system0.0 ipv6-unicast admin-state enable
set / network-instance default segment-routing mpls global-block label-range range-2-srgb
set / network-instance default segment-routing mpls local-prefix-sid 1 interface system0.0
set / network-instance default segment-routing mpls local-prefix-sid 1 ipv4-label-index 12
</pre>

## State and Show commands

The following commands illustrate how the routing happens.

server1 advertises the following prefixes to the anchor nodes. As an example, to anchor5:

```bash
--{ candidate shared default }--[  ]--
A:server1# show network-instance IP-VRF-2 protocols bgp neighbor 5.5.5.5 advertised-routes ipv4
-----------------------------------------------------------------------------------------------------------------------------------------------
Peer        : 5.5.5.5, remote AS: 64500, local AS: 64501
Type        : static
Description : None
Group       : pe-ce
-----------------------------------------------------------------------------------------------------------------------------------------------
Origin codes: i=IGP, e=EGP, ?=incomplete
+-------------------------------------------------------------------------------------------------------------------------------------------+
|      Network             Path-id            Next Hop               MED               LocPref             AsPath              Origin       |
+===========================================================================================================================================+
| 192.168.1.0/24      0                   10.10.10.1                  -                  100          [64501]                     i         |
| 192.168.2.0/24      0                   10.10.10.1                  -                  100          [64501]                     i         |
| 192.168.3.0/24      0                   10.10.10.1                  -                  100          [64501]                     i         |
+-------------------------------------------------------------------------------------------------------------------------------------------+
-----------------------------------------------------------------------------------------------------------------------------------------------
3 advertised BGP routes
-----------------------------------------------------------------------------------------------------------------------------------------------
--{ candidate shared default }--[  ]--
```
The node anchor6 receives the routes and readvertises the routes with the ESI corresponding to the BGP PE-CE routes next hop. The route-table shows all the prefixes in anchor5.

```bash
--{ + candidate shared default }--[  ]--
A:anchor6# show network-instance IP-VRF-2 route-table ipv4-unicast summary
-------------------------------------------------------------------------------------------------------------------------
IPv4 unicast route table of network instance IP-VRF-2
-------------------------------------------------------------------------------------------------------------------------
+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
| Prefix  |   ID    |  Route  |  Route  | Active  | Origin  | Metric  |  Pref   |  Next-  |  Next-  | Backup  | Backup  |
|         |         |  Type   |  Owner  |         | Network |         |         |   hop   | hop Int |  Next-  |  Next-  |
|         |         |         |         |         | Instanc |         |         | (Type)  | erface  |   hop   | hop Int |
|         |         |         |         |         |    e    |         |         |         |         | (Type)  | erface  |
+=========+=========+=========+=========+=========+=========+=========+=========+=========+=========+=========+=========+
| 1.1.1.1 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| /32     |         | evpn    | n_mgr   |         | VRF-2   |         |         | .1/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 2.2.2.2 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| /32     |         | evpn    | n_mgr   |         | VRF-2   |         |         | .2/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 3.3.3.3 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| /32     |         | evpn    | n_mgr   |         | VRF-2   |         |         | .3/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 4.4.4.4 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| /32     |         | evpn    | n_mgr   |         | VRF-2   |         |         | .4/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 5.5.5.5 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| /32     |         | evpn    | n_mgr   |         | VRF-2   |         |         | .5/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 6.6.6.6 | 4       | host    | net_ins | True    | IP-     | 0       | 0       | None (e | None    |         |         |
| /32     |         |         | t_mgr   |         | VRF-2   |         |         | xtract) |         |         |         |
| 10.10.1 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| 0.0/24  |         | evpn    | n_mgr   |         | VRF-2   |         |         | .1/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
|         |         |         |         |         |         |         |         | 100.0.0 |         |         |         |
|         |         |         |         |         |         |         |         | .2/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 10.10.1 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| 0.1/32  |         | evpn    | n_mgr   |         | VRF-2   |         |         | .1/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 11.11.1 | 0       | bgp-    | bgp_evp | True    | IP-     | 10      | 170     | 100.0.0 |         |         |         |
| 1.11/32 |         | evpn    | n_mgr   |         | VRF-2   |         |         | .11/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/ldp) |         |         |         |
| 12.12.1 | 0       | bgp-    | bgp_evp | True    | IP-     | 10      | 170     | 100.0.0 |         |         |         |
| 2.12/32 |         | evpn    | n_mgr   |         | VRF-2   |         |         | .12/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/ldp) |         |         |         |
| 20.20.2 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| 0.0/24  |         | evpn    | n_mgr   |         | VRF-2   |         |         | .3/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
|         |         |         |         |         |         |         |         | 100.0.0 |         |         |         |
|         |         |         |         |         |         |         |         | .4/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 20.20.2 | 0       | bgp-    | bgp_evp | True    | IP-     | 20      | 170     | 100.0.0 |         |         |         |
| 0.1/32  |         | evpn    | n_mgr   |         | VRF-2   |         |         | .3/32 ( |         |         |         |
|         |         |         |         |         |         |         |         | indirec |         |         |         |
|         |         |         |         |         |         |         |         | t/ldp)  |         |         |         |
| 100.0.0 | 0       | bgp-    | bgp_evp | True    | IP-     | 10      | 170     | 100.0.0 |         |         |         |
| .0/24   |         | evpn    | n_mgr   |         | VRF-2   |         |         | .11/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/ldp) |         |         |         |
| 192.168 | 0       | bgp     | bgp_mgr | True    | IP-     | 20      | 170     | 10.10.1 |         |         |         |
| .1.0/24 |         |         |         |         | VRF-2   |         |         | 0.1/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/bgp- |         |         |         |
|         |         |         |         |         |         |         |         | evpn)   |         |         |         |
| 192.168 | 0       | bgp     | bgp_mgr | True    | IP-     | 20      | 170     | 10.10.1 |         |         |         |
| .2.0/24 |         |         |         |         | VRF-2   |         |         | 0.1/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/bgp- |         |         |         |
|         |         |         |         |         |         |         |         | evpn)   |         |         |         |
| 192.168 | 0       | bgp     | bgp_mgr | True    | IP-     | 20      | 170     | 10.10.1 |         |         |         |
| .3.0/24 |         |         |         |         | VRF-2   |         |         | 0.1/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/bgp- |         |         |         |
|         |         |         |         |         |         |         |         | evpn)   |         |         |         |
| 192.168 | 0       | bgp     | bgp_mgr | True    | IP-     | 20      | 170     | 20.20.2 |         |         |         |
| .10.0/2 |         |         |         |         | VRF-2   |         |         | 0.1/32  |         |         |         |
| 4       |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/bgp- |         |         |         |
|         |         |         |         |         |         |         |         | evpn)   |         |         |         |
| 192.168 | 0       | bgp     | bgp_mgr | True    | IP-     | 20      | 170     | 20.20.2 |         |         |         |
| .20.0/2 |         |         |         |         | VRF-2   |         |         | 0.1/32  |         |         |         |
| 4       |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/bgp- |         |         |         |
|         |         |         |         |         |         |         |         | evpn)   |         |         |         |
| 192.168 | 0       | bgp     | bgp_mgr | True    | IP-     | 20      | 170     | 20.20.2 |         |         |         |
| .30.0/2 |         |         |         |         | VRF-2   |         |         | 0.1/32  |         |         |         |
| 4       |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/bgp- |         |         |         |
|         |         |         |         |         |         |         |         | evpn)   |         |         |         |
| 200.0.0 | 0       | bgp-    | bgp_evp | True    | IP-     | 10      | 170     | 100.0.0 |         |         |         |
| .0/24   |         | evpn    | n_mgr   |         | VRF-2   |         |         | .12/32  |         |         |         |
|         |         |         |         |         |         |         |         | (indire |         |         |         |
|         |         |         |         |         |         |         |         | ct/ldp) |         |         |         |
+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
-------------------------------------------------------------------------------------------------------------------------
IPv4 routes total                    : 20
IPv4 prefixes with active routes     : 20
IPv4 prefixes with active ECMP routes: 2
---------------------------------------------

# Advertised routes in EVPN IFL, example for 192.168.1.0/24

A:anchor6# info from state network-instance default bgp-rib evpn rib-in-out rib-out-post ip-prefix-routes 100.0.0.6:2 eth
ernet-tag-id 0 ip-prefix-length 24 ip-prefix 192.168.1.0/24 neighbor 100.0.0.11
    network-instance default {
        bgp-rib {
            evpn {
                rib-in-out {
                    rib-out-post {
                        ip-prefix-routes 100.0.0.6:2 ethernet-tag-id 0 ip-prefix-length 24 ip-prefix 192.168.1.0/24 neighbor 100.0.0.11 {
                            esi 01:10:10:10:01:00:00:00:00:00
                            gateway-ip 0.0.0.0
                            attr-id 592
                            next-hop 100.0.0.6
                            label {
                                value 1000
                                value-type mpls-label
                            }
                        }
                    }
                }
            }
        }
    }

--{ + candidate shared default }--[  ]--
A:anchor6# show network-instance IP-VRF-2 protocols bgp routes ipv4 prefix 192.168.1.0/24
-------------------------------------------------------------------------------------------------------------------------
Show report for the BGP routes to network "192.168.1.0/24" network-instance  "IP-VRF-2"
-------------------------------------------------------------------------------------------------------------------------
Network: 192.168.1.0/24
Received Paths: 2
  Path 1: <Best,Valid,Used,>
    Route source    : neighbor 10.10.10.1
    Route Preference: MED is -, LocalPref is 100
    BGP next-hop    : 10.10.10.1
    Path            :  i [64501]
    Communities     : None
  Path 2: <>
    Route source    : neighbor 20.20.20.1
    Route Preference: MED is -, LocalPref is 100
    BGP next-hop    : 20.20.20.1
    Path            :  i [64502, 64500, 64501]
    Communities     : None
Path 1 was advertised to:
[ 20.20.20.1 ]
-------------------------------------------------------------------------------------------------------------------------
--{ + candidate shared default }--[  ]--

# note that the ESI is the one associated with 10.10.10.1
```

Borderleaf1 resolves the received EVPN IFL, recursively, to the owner of the AD per EVI routes for the ESI, instead of the next hop, and therefore pointing directly at the leaf routers attached to the destination prefixes as expected.

```bash
A:borderleaf1#
--{ candidate shared default }--[  ]--
A:borderleaf1# show network-instance IP-VRF-2 route-table ipv4-unicast prefix 192.168.1.0/24
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IPv4 unicast route table of network instance IP-VRF-2
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
+-------------------------+-------+------------+----------------------+----------+----------+---------+------------+---------------+---------------+---------------+-------------------+
|         Prefix          |  ID   | Route Type |     Route Owner      |  Active  |  Origin  | Metric  |    Pref    |   Next-hop    |   Next-hop    | Backup Next-  |  Backup Next-hop  |
|                         |       |            |                      |          | Network  |         |            |    (Type)     |   Interface   |  hop (Type)   |     Interface     |
|                         |       |            |                      |          | Instance |         |            |               |               |               |                   |
+=========================+=======+============+======================+==========+==========+=========+============+===============+===============+===============+===================+
| 192.168.1.0/24          | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | IP-VRF-2 | 10      | 170        | 100.0.0.1/32  |               |               |                   |
|                         |       |            |                      |          |          |         |            | (indirect/ldp |               |               |                   |
|                         |       |            |                      |          |          |         |            | )             |               |               |                   |
|                         |       |            |                      |          |          |         |            | 100.0.0.2/32  |               |               |                   |
|                         |       |            |                      |          |          |         |            | (indirect/ldp |               |               |                   |
|                         |       |            |                      |          |          |         |            | )             |               |               |                   |
+-------------------------+-------+------------+----------------------+----------+----------+---------+------------+---------------+---------------+---------------+-------------------+
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--{ candidate shared default }--[  ]--
A:borderleaf1# show network-instance IP-VRF-2 route-table ipv4-unicast prefix 192.168.1.0/24 detail
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IPv4 unicast route table of network instance IP-VRF-2
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Destination            : 192.168.1.0/24
ID                     : 0
Route Type             : bgp-evpn
Route Owner            : bgp_evpn_mgr
Origin Network Instance: IP-VRF-2
Metric                 : 10
Preference             : 170
Active                 : true
Last change            : 2024-05-17T23:18:38.591Z
Resilient hash         : false
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Next hops: 2 entries
100.0.0.1 (indirect) resolved by tunnel to 100.0.0.1/32 (ldp)
100.0.0.2 (indirect) resolved by tunnel to 100.0.0.2/32 (ldp)
Backup Next hops: 0 entries

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Route Programming Status
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Last successful FIB operation time: -
Current FIB operation pending     : -
Last failed FIB operation         : -
Last failed FIB complexes         : -
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Primary NHG
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Backup NHG
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--{ candidate shared default }--[  ]--
```
The following show commands illustrate how the next hop of the EVPN IFL is the anchor node, however the AD per EVI routes for the corresponding ESI have next hops 100.0.0.1 and 100.0.0.2, and therefore the borderleaf installs the prefix with the next hops 100.0.0.1 and 100.0.0.2.

```bash
--{ candidate shared default }--[  ]--
A:borderleaf1# show network-instance default protocols bgp routes evpn route-type 5 prefix 192.168.1.0/24 neighbor 100.0.0.6 detail
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Show report for the EVPN routes in network-instance  "default"
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Route Distinguisher: 100.0.0.6:2
Tag-ID             : 0
ip-prefix-len      : 24
ip-prefix          : 192.168.1.0/24
neighbor           : 100.0.0.6
Gateway IP         : 0.0.0.0
Received paths     : 1
  Path 1: <Best,Valid,Used,>
    ESI               : 01:10:10:10:01:00:00:00:00:00
    Label             : 1000
    Route source      : neighbor 100.0.0.6 (last modified 1h30m36s ago)
    Route preference  : No MED, LocalPref is 100
    Atomic Aggr       : false
    BGP next-hop      : 100.0.0.6
    AS Path           :  i [64501]
    Communities       : [target:64500:2, mac-nh:00:00:00:00:00:00, bgp-tunnel-encap:MPLS]
    RR Attributes     : No Originator-ID, Cluster-List is []
    Aggregation       : None
    Unknown Attr      : None
    Invalid Reason    : None
    Tie Break Reason  : none
    Route Flap Damping: None
  Path 1 was advertised to (Modified Attributes):
  [ 100.0.0.1, 100.0.0.2, 100.0.0.3, 100.0.0.4, 100.0.0.5, 100.0.0.12 ]
    Route preference  : No MED, LocalPref is 100
    Atomic Aggr       : false
    BGP next-hop      : 100.0.0.6
    AS Path           :  i [64501]
    Communities       : [target:64500:2, mac-nh:00:00:00:00:00:00, bgp-tunnel-encap:MPLS]
    RR Attributes     : Originator-ID 100.0.0.6, Cluster-List is [11.11.11.11]
    Aggregation       : None
    Unknown Attr      : None
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--{ candidate shared default }--[  ]--

--{ candidate shared default }--[  ]--
A:borderleaf1# show network-instance default protocols bgp routes evpn route-type 1 esi 01:10:10:10:01:00:00:00:00:00 neighbor 100.0.0.1 ethernet-tag-id 0 detail
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Show report for the EVPN routes in network-instance  "default"
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Route Distinguisher: 100.0.0.1:2
Tag-ID             : 0
ESI                : 01:10:10:10:01:00:00:00:00:00
neighbor           : 100.0.0.1
Received paths     : 1
  Path 1: <Best,Valid,Used,>
    ESI               : 01:10:10:10:01:00:00:00:00:00
    Label             : 1002
    Route source      : neighbor 100.0.0.1 (last modified 1h31m8s ago)
    Route preference  : No MED, LocalPref is 100
    Atomic Aggr       : false
    BGP next-hop      : 100.0.0.1
    AS Path           :  i
    Communities       : [target:64500:2, l2-attribute:MTU: 0 V: 0 M: 0 F: 0 C: 0 P: 1 B: 0, bgp-tunnel-encap:MPLS]
    RR Attributes     : No Originator-ID, Cluster-List is []
    Aggregation       : None
    Unknown Attr      : None
    Invalid Reason    : None
    Tie Break Reason  : none
    Route Flap Damping: None
  Path 1 was advertised to (Modified Attributes):
  [ 100.0.0.2, 100.0.0.3, 100.0.0.4, 100.0.0.5, 100.0.0.6, 100.0.0.12 ]
    Route preference  : No MED, LocalPref is 100
    Atomic Aggr       : false
    BGP next-hop      : 100.0.0.1
    AS Path           :  i
    Communities       : [target:64500:2, l2-attribute:MTU: 0 V: 0 M: 0 F: 0 C: 0 P: 1 B: 0, bgp-tunnel-encap:MPLS]
    RR Attributes     : Originator-ID 100.0.0.1, Cluster-List is [11.11.11.11]
    Aggregation       : None
    Unknown Attr      : None
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--{ candidate shared default }--[  ]--
```

Finally, the data path is tested with ICMP traffic from Client1 to the prefix behind the server:

```bash
bash-5.0# ip add | grep eth1.1
2: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default qlen 1000
    inet 100.0.0.2/24 scope global eth1.1
bash-5.0#
bash-5.0# ping 192.168.1.1
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=62 time=8.91 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=62 time=8.05 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=62 time=6.07 ms
^C
--- 192.168.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 6.074/7.678/8.913/1.188 ms
```













