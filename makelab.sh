#!/bin/bash

cat /root/.config/kathara.conf | grep update_policy
if [ $? == 1 ]; then
  sed -i '/"hosthome_mount"/a\ "image_update_policy": "Never",' /home/iut/.config/kathara.conf
  sed -i '/"hosthome_mount"/a\ "image_pull_policy": "Never",' /home/iut/.config/kathara.conf
fi

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
PCA2="pca2.startup"
PCE2="pce2.startup"
PCD2="pcd2.startup"
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
 
SHARED="$PWD/shared"
mkdir "$SHARED"
cp nettest.sh "$SHARED/nettest.sh"

create_config_file "$LAB_CONF_PATH" "
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
s[0]=net7
pca1[0]=net5
pcd1[0]=net6
pce1[0]=net4
pca2[0]=net5
pcd2[0]=net6
pce2[0]=net4
"

create_config_file "$R0" "
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
ip route add 172.12.150.0/24 via 10.0.1.2
iptables -t nat -A POSTROUTING -o eth4 -j MASQUERADE
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A FORWARD -s 172.12.150.1 -p icmp -j ACCEPT
iptables -A FORWARD -s 192.168.16.0/20 -p icmp -j ACCEPT
iptables -A FORWARD -s 192.168.32.0/20 -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -s 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p icmp -d 172.12.150.1 -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
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
iptables -A FORWARD -p tcp --dport 1234 -s 192.168.16.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --dport 1234 -s 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -d 192.168.16.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -d 172.12.150.1 -j ACCEPT
iptables -A INPUT -p icmp -s 192.168.16.0/20 -j ACCEPT
iptables -A OUTPUT -p icmp -s 192.168.16.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -s 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -s 192.168.16.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
"

create_config_file "$R2" "
ip addr add 10.0.3.2/24 dev eth0
ip link set eth0 up
ip addr add 192.168.47.254/20 dev eth1
ip link set eth1 up
ip route add default via 10.0.3.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -p icmp -s 192.168.32.0/20 -j ACCEPT
iptables -A OUTPUT -p icmp -s 192.168.32.0/20 -j ACCEPT
iptables -A FORWARD -s 172.12.150.1 -p tcp --sport 1234 -j ACCEPT
iptables -A FORWARD -s 192.168.32.0/20 -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -s 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -s 192.168.32.0/20 -j ACCEPT
"

create_config_file "$R3" "
ip addr add 10.0.2.2/24 dev eth0
ip link set eth0 up
ip addr add 11.0.0.1/26 dev eth1
ip link set eth1 up
ip route add default via 10.0.2.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A FORWARD -p tcp --dport 587 -s 11.0.0.0/26 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -s 192.168.16.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -s 192.168.32.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -d 11.0.0.0/26 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -d 192.168.16.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -d 192.168.32.0/20 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -s 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -d 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
iptables -A INPUT -s 11.0.0.0/26 -p icmp -j ACCEPT
iptables -A OUTPUT -d 11.0.0.0/26 -p icmp -j ACCEPT
iptables -A FORWARD -s 172.12.150.1 -p tcp --sport 22 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -s 11.0.0.0/26 -j ACCEPT

"

create_config_file "$R4" "
ip addr add 10.0.1.2/24 dev eth0
ip link set eth0 up
ip addr add 172.12.150.254/24 dev eth1
ip link set eth1 up
ip route add default via 10.0.1.1 dev eth0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -p icmp -s 172.12.150.1 -j ACCEPT
iptables -A OUTPUT -p icmp -d 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p icmp -s 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p icmp -d 172.12.150.1 -j ACCEPT
iptables -A FORWARD -p tcp --dport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --sport 1234 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT
iptables -A FORWARD -s 192.168.32.0/20 -p icmp -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 587 -s 11.0.0.0/26 -j ACCEPT
iptables -A FORWARD -p tcp --dport 587 -s 172.12.150.1 -j ACCEPT
"

create_config_file "$SHARED/pcetest.conf" "tcp 80 192.168.32.1 true
tcp 443 192.168.32.1 true
tcp 53 192.168.32.1 true
udp 53 192.168.32.1 true
tcp 80 192.168.32.2 true
tcp 443 192.168.32.2 true
tcp 53 192.168.32.2 true
udp 53 192.168.32.2 true
tcp 22 192.168.32.1 false
tcp 23 192.168.32.1 false
tcp 25565 192.168.32.1 false
udp 22 192.168.32.1 false
tcp 443 172.12.150.1 true
tcp 53 172.12.150.1 true
udp 53 172.12.150.1 true
tcp 80 172.12.150.1 false"

create_config_file "$PCE1" "
ip address add 192.168.16.1/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.31.254 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt-get update -y
apt-get install nmap -y
cp ./shared/pcetest.conf ./script.conf
cp ./shared/nettest.sh ./nettest.sh
chmod a+rwx ./nettest.sh
bash ./nettest.sh
"

create_config_file "$PCE2" "
ip address add 192.168.16.2/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.31.254 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt-get update -y
apt-get install nmap -y
cp ./shared/pcetest.conf ./script.conf
cp ./shared/nettest.sh ./nettest.sh
chmod a+rwx ./nettest.sh
bash ./nettest.sh
"

create_config_file "$SHARED/pcatest.conf" "tcp 80 192.168.16.2 true
tcp 443 192.168.16.2 true
tcp 53 192.168.16.2 true
udp 53 192.168.16.2 true
tcp 80 192.168.16.1 true
tcp 443 192.168.16.1 true
tcp 53 192.168.16.1 true
udp 53 192.168.16.1 true
tcp 22 192.168.16.1 false
tcp 23 192.168.16.1 false
tcp 25565 192.168.16.1 false
udp 22 192.168.16.1 false
tcp 80 11.0.0.2 true
tcp 443 11.0.0.2 true
tcp 53 11.0.0.2 true
udp 53 11.0.0.2 true
tcp 443 172.12.150.1 true
tcp 53 172.12.150.1 true
udp 53 172.12.150.1 true
tcp 80 172.12.150.1 false"

create_config_file "$PCA1" "
ip address add 192.168.32.1/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.47.254 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt-get update -y
apt-get install nmap -y
cp ./shared/pcatest.conf ./script.conf
cp ./shared/nettest.sh ./nettest.sh
chmod a+rwx ./nettest.sh
bash ./nettest.sh
"

create_config_file "$PCA2" "
ip address add 192.168.32.2/20 dev eth0
ip link set eth0 up
ip route add default via 192.168.47.254 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt-get update -y
apt-get install nmap -y
cp ./shared/pcatest.conf ./script.conf
cp ./shared/nettest.sh ./nettest.sh
chmod a+rwx ./nettest.sh
bash ./nettest.sh
"

create_config_file "$SHARED/pcdtest.conf" "tcp 22 192.168.32.1 false
tcp 23 192.168.32.1 false
tcp 25565 192.168.32.1 false
udp 22 192.168.32.1 false
tcp 80 192.168.16.1 true
tcp 443 192.168.16.1 true
tcp 53 192.168.16.1 true
udp 53 192.168.16.1 true
tcp 443 172.12.150.1 true
tcp 53 172.12.150.1 true
udp 53 172.12.150.1 true
tcp 80 172.12.150.1 false"

create_config_file "$PCD1" "
ip address add 11.0.0.2/26 dev eth0
ip link set eth0 up
ip route add default via  11.0.0.1 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt-get update -y
apt-get install nmap -y
cp ./shared/pcdtest.conf ./script.conf
cp ./shared/nettest.sh ./nettest.sh
chmod a+rwx ./nettest.sh
bash ./nettest.sh
"

create_config_file "$PCD2" "
ip address add 11.0.0.3/26 dev eth0
ip link set eth0 up
ip route add default via  11.0.0.1 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
apt-get update -y
apt-get install nmap -y
cp ./shared/pcdtest.conf ./script.conf
cp ./shared/nettest.sh ./nettest.sh
chmod a+rwx ./nettest.sh
bash ./nettest.sh
"

create_config_file "$S" "
ip addr add 172.12.150.1/24 dev eth0
ip link set eth0 up
ip route add default via 172.12.150.254 dev eth0
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"
deb http://archive.debian.org/debian stretch main
deb http://security.debian.org/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-updates main
\" > /etc/apt/sources.list
"

echo "Lab successfully created in $LAB"

if [ "$START_LAB" = true ]; then
  echo "Lab is starting ..."
  kathara lstart || exit_with_error "Error starting the lab."
else
  echo "Lab not started. Use -s option to start the lab."
fi

exit 0
