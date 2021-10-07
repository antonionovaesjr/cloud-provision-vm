#!/bin/bash
cd $HOME
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl wget software-properties-common debsecan auditd -y
sudo apt upgrade
wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
chmod o-x /usr/bin/curl /usr/bin/wget 

sudo timedatectl set-timezone America/Sao_Paulo

PART_DEFAULT="p1"

for DEVICE_NAME in `sudo lsblk -l -o NAME|grep nvme[0-9]n[0-9]$`; do 
 
    if [ ! -b /dev/$DEVICE_NAME$PART_DEFAULT ]; then
    
        echo "/dev/$DEVICE_NAME$PART_DEFAULT:var" > $HOME/lista-particao.conf

        if [ $(grep var /tmp/lista-particao.conf) -gt 0 ]; then
            echo "/dev/$DEVICE_NAME$PART_DEFAULT:tmp" >> $HOME/lista-particao.conf
        fi

    else
    
        echo "/dev/$DEVICE_NAME$VAR_TEMP partição exisite e nenhum ação será feita"
    
    fi

done

cat $HOME/lista-particao.conf