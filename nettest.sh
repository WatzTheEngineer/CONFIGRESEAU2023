#!/bin/bash

clear

# Vérifie si le fichier script.conf existe
if [ ! -f "script.conf" ]; then
    echo "\e[31mErreur: Le fichier script.conf est introuvable."
    exit 1
fi

apt update -y 
apt install nmap -y

# Vérifie la disponibilité de nping
nping 1>/dev/null 2>&1
if [ $? == 127 ]; then
    echo "\e[31mErreur: Nmap n'est pas installé correctement. Essayez d'installer nmap et de relancer le script de test."
    exit 1
fi

# Lecture du fichier script.conf ligne par ligne
while IFS= read -r line; do
    # Exécute les tests en séparant chaque ligne en utilisant le point-virgule comme délimiteur
    IFS=' ' read -ra test <<< "$line"
    
    # Vérifie que le test a au moins trois éléments (protocole, port, adresse IP)
    if [ "${#test[@]}" -lt 4 ]; then
        echo "\e[33mErreur: Le format de la ligne est incorrect. Ligne ignorée: $line"
        continue
    fi
    
    protocol="${test[0]}"
    port="${test[1]}"
    ip="${test[2]}"
    ping_required="${test[3]}"

    # Effectue le test en fonction du protocole
    case "$protocol" in
        tcp)
            nping -c 1 --tcp -p "$port" "$ip" | grep "RCVD" > /dev/null 2>&1
            if [ "$ping_required" == "true" ]; then
                if [ $? -eq 0 ]; then
                    echo -e "\e[32mTest validé pour TCP port $port vers $ip (passe)\e[0m"
                else
                    echo -e "\e[31mTest invalidé pour TCP port $port vers $ip (devrait passer)\e[0m"
                fi
            else
                if [ $? -eq 1 ]; then
                    echo -e "\e[32mTest validé pour TCP port $port vers $ip (ne passe pas)\e[0m"
                else
                    echo -e "\e[31mTest invalidé pour TCP port $port vers $ip (ne devrait pas passer)\e[0m"
                fi
            fi
            ;;
        udp)
            nping -c 1 --udp -p "$port" "$ip" | grep "RCVD" > /dev/null 2>&1
            if [ "$ping_required" == "true" ]; then
                if [ $? -eq 0 ]; then
                    echo -e "\e[32mTest validé pour UDP port $port vers $ip (passe)\e[0m"
                else
                    echo -e "\e[31mTest invalidé pour UDP port $port vers $ip (devrait passer)\e[0m"
                fi
            else
                if [ $? -eq 1 ]; then
                    echo -e "\e[32mTest validé pour UDP port $port vers $ip (ne passe pas)\e[0m"
                else
                    echo -e "\e[31mTest invalidé pour UDP port $port vers $ip (ne devrait pas passer)\e[0m"
                fi
            fi

            
            ;;
        *)
            echo "\e[31mErreur: Protocole non pris en charge: $protocol"
            ;;
    esac
done < "script.conf"
