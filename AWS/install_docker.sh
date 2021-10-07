#!/bin/bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common debsecan auditd -y
sudo apt upgrade
wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
chmod o-x /usr/bin/curl /usr/bin/wget 

sudo timedatectl set-timezone America/Sao_Paulo


