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

sudo mkdir -p /var/swap/
sudo dd if=/dev/zero of=/var/swap/mem01.swap bs=4k count=512000
sudo chmod 600 /var/swap/mem01.swap
sudo mkdswap -L swap-mem01 /var/swap/mem01.swap
sudo swapon /var/swap/mem01.swap

sudo cp /etc/fstab /etc/fstab.bck
sudo chmod ugo+rw /etc/fstab
sudo echo "LABEL=particao-var     /var/log    ext4   defaults 0 0" >> /etc/fstab
sudo echo "LABEL=particao-temp     /tmp    ext4   defaults,nosuid,noexec,rw 0 0" >> /etc/fstab
sudo echo "LABEL=swap-mem01     swap    swap   defaults 0 0" >> /etc/fstab
sudo chmod go-w /etc/fstab

sudo rm -f /etc/apt/apt.conf.d/50unattended-upgrades

sudo cat <<-EOF > /etc/apt/apt.conf.d/50unattended-upgrades
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

sudo cat <<-EOF > /etc/fail2ban/jail.local
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

sudo cat <<-EOF > /etc/apt/apt.conf.d/00-apt-invoke-apt.conf
DPkg::Pre-Invoke {
        "mount -o remount,defaults /tmp";
};
DPkg::Post-Invoke {
        "mount -o remount,defaults,nosuid,noexec,rw /tmp";
};
EOF

sudo cat <<-EOF >> /etc/sysctl.conf
#Conexões que foram encerrados e já não têm um identificador de arquivo anexado a eles
net.ipv4.tcp_max_orphans = 262144
# Aumentando range de portas do IP local e de conexões
net.ipv4.ip_local_port_range = 10000 65000 
# Aumentar o número de conexões
net.core.somaxconn = 65000
# Aumentando buffer de rede TCP
# Defina o máximo de 16M (16777216) para redes de 1GB and 32M (33554432) ou 54M (56623104) para redes de 10GB
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
# Aumentar a alocação para tamanho maximo
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
# Aumentando tamanho de pacotes de backlog e buckets
net.core.netdev_max_backlog = 50000
net.ipv4.tcp_max_syn_backlog = 30000
net.ipv4.tcp_max_tw_buckets = 2000000
# Habilitando reuso de sockets TCP
net.ipv4.tcp_tw_reuse = 1
# Aumentando timeout do TCP para reuso de sockets
net.ipv4.tcp_fin_timeout = 10
# Destabilitando início lento de em conexões IDLE
net.ipv4.tcp_slow_start_after_idle = 0
# Aumentando buffer de conexões UDP
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
#Desabilitar o ipv6
#net.ipv6.conf.all.disable_ipv6 = 1
#net.ipv6.conf.default.disable_ipv6 = 1
#net.ipv6.conf.lo.disable_ipv6 = 1
fs.file-max = 2097152
vm.swappiness = 5
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
EOF

sudo cat <<-EOF >> /etc/security/limits.conf
root        hard    nproc           65535
root        soft    nproc           65535
root        hard    nofile          65535
root        soft    nofile          65535
*           hard    nproc           10000
*           soft    nproc           10000
*           hard    nofile          10000
*           soft    nofile          10000
*           soft    stack           10240
*           hard    stack           10240
EOF

sudo cp /home/ubuntu/setup-ami/AWS/audit-rules/*.rules /etc/audit/rules.d/
sudo chown root:root -R /etc/audit/rules.d
sudo chmod 640 -R /etc/audit/rules.d
sudo systemctl restart auditd