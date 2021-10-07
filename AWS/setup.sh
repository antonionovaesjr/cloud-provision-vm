#!/bin/bash -x
cd /home/ubuntu
sudo apt-get update
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo apt-get install -y 

export DEBIAN_FRONTEND=noninteractive

DEBIAN_FRONTEND=noninteractive sudo apt install dialog apt-utils --assume-yes
DEBIAN_FRONTEND=noninteractive sudo apt-get install --assume-yes postfix

sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt upgrade --assume-yes


DEBIAN_FRONTEND=noninteractive sudo apt-get install unattended-upgrades fail2ban curl debsecan wget auditd ntp rkhunter --assume-yes
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
DEBIAN_FRONTEND=noninteractive sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo chmod o-x /usr/bin/curl /usr/bin/wget /usr/bin/nc /usr/bin/dd /usr/bin/telnet

sudo timedatectl set-timezone America/Sao_Paulo


PART_DEFAULT="p1"

if [ -e /tmp/lista-particao.conf ]; then
    rm -f /tmp/lista-particao.conf
fi

for DEVICE_NAME in `sudo lsblk -l -o NAME|grep nvme[0-9]n[0-9]$`; do

    if [ ! -b /dev/$DEVICE_NAME$PART_DEFAULT ]; then

        touch /tmp/lista-particao.conf
        if [ $(grep var /tmp/lista-particao.conf|wc -l) -gt 0 ]; then
            echo "/dev/$DEVICE_NAME:tmp" >> /tmp/lista-particao.conf
        else
            echo "/dev/$DEVICE_NAME:var" >> /tmp/lista-particao.conf
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
sudo echo "LABEL=particao-temp     /tmp    ext4   defaults,nosuid,noexec,rw 0 0" >> /etc/fstab
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
   "tomcat8-";
   "tomcat7-";
//  "libc6$";

    // Special characters need escaping
//  "libstdc\+\+6$";
};
EOF

if [ -e /etc/fail2ban/jail.local ]; then
    sudo rm -f /etc/fail2ban/jail.local
fi

touch /etc/fail2ban/jail.local

cat <<-EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 5m
ignoreip = 127.0.0.1/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
ignoreself = true

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 10
EOF

sudo systemctl restart fail2ban

cat <<-EOF > /etc/apt/apt.conf.d/00-apt-invoke-apt.conf
DPkg::Pre-Invoke {
        "mount -o remount,defaults /tmp";
};
DPkg::Post-Invoke {
        "mount -o remount,defaults,nosuid,noexec,rw /tmp";
};
EOF


    sudo cp /home/ubuntu/setup-ami/AWS/audit-rules/*.rules /etc/audit/rules.d/
    sudo chown root:root -R /etc/audit/rules.d
    sudo chmod 640 -R /etc/audit/rules.d
    sudo systemctl restart auditd

fi