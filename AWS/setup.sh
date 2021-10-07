#!/bin/bash -x
cd $HOME

export DEBIAN_FRONTEND=noninteractive
sudo dpkg-reconfigure debconf --default-priority

sudo apt-get update
sudo apt upgrade --assume-yes


debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local Only'"
sudo apt-get install --assume-yes postfix


DEBIAN_FRONTEND=noninteractive sudo apt-get install unattended-upgrades fail2ban curl wget debsecan auditd --assume-yes
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo chmod o-x /usr/bin/curl /usr/bin/wget

sudo timedatectl set-timezone America/Sao_Paulo


PART_DEFAULT="p1"

if [ -e /tmp/lista-particao.conf ]; then
    rm -f /tmp/lista-particao.conf
fi

for DEVICE_NAME in `sudo lsblk -l -o NAME|grep nvme[0-9]n[0-9]$`; do

    if [ ! -b /dev/$DEVICE_NAME$PART_DEFAULT ]; then


        if [ $(grep var /tmp/lista-particao.conf|wc -l) -gt 0 ]; then
            echo "/dev/$DEVICE_NAME:tmp" >> /tmp/lista-particao.conf
        else
            echo "/dev/$DEVICE_NAME:var" > /tmp/lista-particao.conf
        fi

    else

        echo "/dev/$DEVICE_NAME$PART_DEFAULT partição exisite e nenhum ação será feita"

    fi

done


DEVICE_TO_VAR=$(grep var /tmp/lista-particao.conf|cut -d\: -f1)
DEVICE_TO_TMP=$(grep tmp /tmp/lista-particao.conf|cut -d\: -f1)

sudo parted -a optimal $DEVICE_TO_VAR mklabel msdos -- 'mkpart primary ext4 1 -1'
sudo parted -a optimal $DEVICE_TO_TMP mklabel msdos -- 'mkpart primary ext4 1 -1'

sudo mkfs.ext4 -L particao-var $DEVICE_TO_VAR$PART_DEFAULT
sudo mkfs.ext4 -L particao-temp $DEVICE_TO_TMP$PART_DEFAULT

sudo cp /etc/fstab /etc/fstab.bck
sudo chmod ugo+rw /etc/fstab
sudo echo "LABEL=particao-var     /var/log    ext4   defaults 0 0" >> /etc/fstab
sudo echo "LABEL=pariticao-tmp     /tmp    ext4   defaults,nosuid,noexec,rw 0 0" >> /etc/fstab
sudo chmod go-w /etc/fstab

sudo rm -f /etc/apt/apt.conf.d/50unattended-upgrades

cat <<-EOF > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
        "${distro_id}ESMApps:${distro_codename}-apps-security";
        "${distro_id}ESM:${distro_codename}-infra-security";
};

// Python regular expressions, matching packages to exclude from upgrading
Unattended-Upgrade::Package-Blacklist {
  "nginx";
   "tomcat9-";
//  "libc6$";

    // Special characters need escaping
//  "libstdc\+\+6$";
};
EOF