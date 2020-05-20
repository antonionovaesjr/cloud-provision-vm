#!/bin/bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt-get update 
sudo apt-get install docker-ce -y
sudo gpasswd -a ubuntu docker
sudo systemctl restart docker
sudo systemctl enable docker
sudo systemctl status docker
sudo gpasswd -a ubuntu docker
sudo docker pull alpine
sudo docker pull httpd
sudo docker pull mysql
