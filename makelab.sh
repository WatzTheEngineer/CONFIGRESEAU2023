#!/bin/bash

LAB=""
LAB_CONF="lab.conf"
R0="r0.startup"
R1="r1.startup"
R2="r2.startup"
R3="r3.startup"
R4="r4.startup"
PCA1="pca1.startup"
PCE1="pce1.startup"
PCD1="pcd1.startup"
S="s.startup"
START_LAB=false

create_config_file() {
  local path=$1
  local content=$2

  touch "$path" || { echo "Error: Can't create $path file"; exit 1; }

  cat <<EOF > "$path"
$content
EOF

  echo "$path creation done"
}

exit_with_error() {
  local message=$1
  echo "Error: $message" >&2
  exit 1
}

while getopts ":l:s" opt; do
  case $opt in
    l)
      LAB="$OPTARG"
      ;;
    s)
      START_LAB=true
      ;;
    \?)
      exit_with_error "Invalid option: -$OPTARG"
      ;;
    :)
      exit_with_error "Option -$OPTARG requires an argument."
      ;;
  esac
done

if [ -z "$LAB" ]; then
  LAB="$PWD"
fi

if [ ! -d "$LAB" ]; then
  mkdir "$LAB" || exit_with_error "Can't create directory $LAB"
fi

cd "$LAB" || exit_with_error "Can't enter directory $LAB"

LAB_CONF_PATH="$PWD/$LAB_CONF"

create_config_file "$LAB_CONF_PATH" "
r0[0]=net0
r0[bridged]=true
r1[0]=net0
r2[0]=net0
r3[0]=net0
r4[0]=net0
r1[1]=net1
r2[1]=net2
r3[1]=net3
r4[1]=net4
s[0]=net4
pca1[0]=net2
pcd1[0]=net3
pce1[0]=net1
"

create_config_file "$R0" "
ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up
iptables -t nat -A POSTROUTING -j MASQUERADE
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
ip route add 192.168.16.0/20 via 10.0.0.2
ip route add 192.168.32.0/20 via 10.0.0.3
ip route add 11.0.0.0/26 via 10.0.0.4
ip route add 172.12.150.0/24 via 10.0.0.5
iptables -P INPUT DROP
iptables -P FORWARD DROP 
iptables -P OUTPUT DROP
#mail
iptables -A FORWARD -p tcp --dport 25 -j ACCEPT
iptables -A FORWARD -p tcp --sport 25 -j ACCEPT
#tcp 1234
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
#SSH/SFTP
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT
#HTTPS/HTTP
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
#DNS
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
#PING
iptables -A FORWARD -p icmp -j ACCEPT
"

create_config_file "$R1" "
ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up
ip addr add 192.168.31.254/20 dev eth1
ip link set eth1 up
ip route add default via 10.0.0.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP 
iptables -P OUTPUT DROP
#mail
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
#tcp 1234
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
#HTTPS/HTTP
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
#DNS
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
"

create_config_file "$R2" "
ip addr add 10.0.0.3/24 dev eth0
ip link set eth0 up
ip addr add 192.168.47.254/20 dev eth1
ip link set eth1 up
ip route add default via 10.0.0.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP 
iptables -P OUTPUT DROP
#mail
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
#tcp 1234
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
#SSH/SFTP
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT
#HTTPS/HTTP
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
#DNS
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
"

create_config_file "$R3" "
ip addr add 10.0.0.4/24 dev eth0
ip link set eth0 up
ip addr add 11.0.0.1/26 dev eth1
ip link set eth1 up
ip route add default via 10.0.0.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP 
iptables -P OUTPUT DROP
#mail
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
#tcp 1234
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
#SSH/SFTP
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT
#HTTPS/HTTP
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
#DNS
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
"

create_config_file "$R4" "
ip addr add 10.0.0.5/24 dev eth0
ip link set eth0 up
ip addr add 172.12.150.254/24 dev eth1
ip link set eth1 up
ip route add default via 10.0.0.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP 
iptables -P OUTPUT DROP
#mail
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
#tcp 1234
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
#SSH/SFTP
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT
#HTTPS/HTTP
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
#DNS
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
#PING
iptables -A FORWARD -p icmp -j ACCEPT
"

create_config_file "$PCE1" "
ip address add 192.168.16.1/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.31.254 
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt update
apt install nmap -y
"

create_config_file "$PCA1" "
ip address add 192.168.32.1/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.47.254 
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt update
apt install nmap -y
"

create_config_file "$PCD1" "
ip address add 11.0.0.2/26 dev eth0
ip link set eth0 up
ip route add default via  11.0.0.1 
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt update
apt install nmap -y
"

create_config_file "$S" "
ip addr add 172.12.150.1/24 dev eth0
ip link set eth0 up
ip route add default via 172.12.150.254 
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt update
apt install nmap -y
"

echo "Lab successfully created in $LAB"

if [ "$START_LAB" = true ]; then
  echo "Lab is starting ..."
  kathara lstart || exit_with_error "Error starting the lab."
  echo "n" | kathara
else
  echo "Lab not started. Use -s option to start the lab."
fi

exit 0