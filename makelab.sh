#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

lab="lab_$(date +%F)"
labconf="lab.conf"
r0="r0.startup"
r1="r1.startup"
r2="r2.startup"
r3="r3.startup"
r4="r4.startup"
pca1="pca1.startup"
pce1="pce1.startup"
pcd1="pcd1.startup"

create_config_file() {
  local path=$1
  local content=$2

  touch "$path" || { echo "Can't create $path file"; exit 1; }

  cat <<EOF > "$path"
$content
EOF

  echo "$path creation done"
}

if [ ! -d "$lab" ]; then
  mkdir "$lab" || { echo "Can't create directory $lab"; exit 1; }
fi

cd "$lab" || { echo "Can't enter directory $lab"; exit 1; }

labconf_path="$PWD/$labconf"
create_config_file "$labconf_path" "
r0[0]=net0
r0[1]=net1
r0[2]=net2
r0[3]=net3
r0[bridged]=true
r1[0]=net0
r1[1]=net4
r2[0]=net3
r2[1]=net5
r3[0]=net2
r3[1]=net6
r4[0]=net1
r4[1]=net7
pca1[0]=net5
pcd1[0]=net6
pce1[0]=net4
"

create_config_file "$r0" "
ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up
ip addr add 10.0.1.1/24 dev eth1
ip link set eth1 up
ip addr add 10.0.2.1/24 dev eth2
ip link set eth2 up
ip addr add 10.0.3.1/24 dev eth3
ip link set eth3 up
ip route add 192.168.16.0/20 via 10.0.0.2
ip route add 192.168.32.0/20 via 10.0.3.2
ip route add 11.0.0.0/26 via 10.0.2.2
"

create_config_file "$r1" "
ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up
ip addr add 192.168.31.254/20 dev eth1
ip link set eth1 up
ip route add 10.0.3.1/24 via 10.0.0.1
echo 1 > /proc/sys/net/ipv4/ip_forward
"

create_config_file "$r2" "
ip addr add 10.0.3.2/24 dev eth0
ip link set eth0 up
ip addr add 192.168.47.254/20 dev eth1
ip link set eth1 up
ip route add 10.0.0.1/24 via 10.0.3.1
echo 1 > /proc/sys/net/ipv4/ip_forward
"

create_config_file "$r3" "
ip addr add 10.0.2.2/24 dev eth0
ip link set eth0 up
ip addr add 11.0.0.1/26 dev eth1
ip link set eth1 up
echo 1 > /proc/sys/net/ipv4/ip_forward
"

create_config_file "$r4" "
ip addr add 10.0.1.2/24 dev eth0
ip link set eth0 up
echo 1 > /proc/sys/net/ipv4/ip_forward
"

create_config_file "$pce1" "
ip address add 192.168.16.1/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.31.254 dev eth0
"

create_config_file "$pca1" "
ip address add 192.168.32.1 dev eth1
ip link set eth1 up
ip route add default via 192.168.47.254 dev eth0
"

create_config_file "$pcd1" "
ip address add 11.0.0.2/26 dev eth0
ip link set eth0 up
ip route add default 11.0.0.1 dev eth0
"

echo "Lab successfully created"
exit 0