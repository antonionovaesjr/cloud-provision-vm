#!/bin/bash
cd $HOME

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo debconf-set-selections <<< "postfix postfix/mailname string localhost.localhost"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
sudo dpkg-reconfigure debconf --default-priority

sudo apt-get install apt-transport-https ca-certificates curl wget software-properties-common debsecan auditd -y
sudo apt upgrade -y
wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo chmod o-x /usr/bin/curl /usr/bin/wget

sudo timedatectl set-timezone America/Sao_Paulo


PART_DEFAULT="p1"
rm -f $HOME/lista-particao.conf
for DEVICE_NAME in `sudo lsblk -l -o NAME|grep nvme[0-9]n[0-9]$`; do

    if [ ! -b /dev/$DEVICE_NAME$PART_DEFAULT ]; then


        if [ $(grep var $HOME/lista-particao.conf|wc -l) -gt 0 ]; then
            echo "/dev/$DEVICE_NAME$PART_DEFAULT:tmp" >> $HOME/lista-particao.conf
        else
            echo "/dev/$DEVICE_NAME$PART_DEFAULT:var" > $HOME/lista-particao.conf
        fi

    else

        echo "/dev/$DEVICE_NAME$VAR_TEMP partição exisite e nenhum ação será feita"

    fi

done


DEVICE_TO_VAR=$(grep var $HOME/lista-particao.conf|cut -d\: -f1)
DEVICE_TO_TMP=$(grep tmp $HOME/lista-particao.conf|cut -d\: -f1)
sudo parted -a optimal $DEVICE_TO_VAR mklabel msdos -- 'mkpart primary ext4 1 -1'
sudo parted -a optimal $DEVICE_TO_TMP mklabel msdos -- 'mkpart primary ext4 1 -1'

sudo mkfs.ext4 -L particao-var $DEVICE_TO_VAR$PART_DEFAULT
sudo mkfs.ext4 -L particao-temp $DEVICE_TO_TMP$PART_DEFAULT
sudo cp /etc/fstab /etc/fstab.bck
sudo chmod ugo+rw /etc/fstab
sudo echo "LABEL=particao-var     /var/log    ext4   defaults 0 0" >> /etc/fstab
sudo echo "LABEL=pariticao-tmp     /tmp    ext4   defaults 0 0" >> /etc/fstab
sudo chmod go-w /etc/fstab
