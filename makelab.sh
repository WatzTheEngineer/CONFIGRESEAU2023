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
  exit_with_error "Please specify the lab location using -l <path>."
fi

if [ ! -d "$LAB" ]; then
  mkdir "$LAB" || exit_with_error "Can't create directory $LAB"
fi

cd "$LAB" || exit_with_error "Can't enter directory $LAB"

LAB_CONF_PATH="$PWD/$LAB_CONF"

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
pca1[0]=net5
pcd1[0]=net6
pce1[0]=net4
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
"

echo "Lab successfully created"

if [ "$START_LAB" = true ]; then
  echo "Lab is starting ..."
  kathara lstart || exit_with_error "Error starting the lab."
else
  echo "Lab not started. Use -s option to start the lab."
fi

exit 0
