ip link add link eth1 name eth1.1 type vlan id 1
ip link set dev eth1.1 up
ip link add link eth1 name eth1.2 type vlan id 2
ip link set dev eth1.2 up