# SRL-

This lab shows an example of the Centralized Routing architecture deployed with EVPN IFL IP Aliasing for MPLS tunnels. The lab is depicted in the following diagram:

![](srl-uecmp-sticky-mpls.drawio.png)

And consists of the following nodes:



## Configurations



<pre>
# interface configuration

--{ candidate shared default }--[  ]--
A:server1# info flat interface *

</pre>

server1 advertises the following prefixes to the anchor nodes. As an example, to anchor5:

```bash
--{ candidate shared default }--[  ]--
A:server1# show network-instance IP-VRF-2 protocols bgp neighbor 5.5.5.5 advertised-routes ipv4
-----------------------------------------------------------------------------------------------------------------------------------------------
Peer        : 5.5.5.5, remote AS: 64500, local AS: 64501
Type        : static
Description : None
Group       : pe-ce
----------------------------------------------------------------------------------------------------
```













