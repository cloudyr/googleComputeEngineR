#! /bin/bash
echo "Installing docker on Debian 9 (Stretch)"

# https://docs.docker.com/engine/installation/linux/debian/
## install docker dependencies
sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common     
## docker gpg key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

## add stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get update

## install docker
sudo apt-get install -y docker-ce

## start docker
sudo service docker start
