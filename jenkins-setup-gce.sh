#!/bin/bash
#
# Script to set up Jenkins on an Ubuntu 16.04/above GCE 
# instance, on port 80 (http port) using firewalld
#
# Make sure you edit the firewall rules to allow port 80
# traffic (i.e. add the default-allow-http tag)
#
# Usage:
#	  ./jenkins-setup-gce.sh
#

echo -e "Installing OpenJDK 8 dependency..."
sudo apt update &>/dev/null
sudo apt install -y openjdk-8-jdk &>/dev/null
echo "Done."

echo -e "\nInstalling Jenkins and firewalld..."
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add - &>/dev/null
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update &>/dev/null
sudo apt install -y jenkins firewalld &>/dev/null
sudo service jenkins start
echo "Done."

echo -e "\nSetting up jenkins on port 80..."
sudo systemctl mask ebtables &>/dev/null
sudo systemctl disable ebtables &>/dev/null
sudo firewall-cmd --permanent --add-port=8080/tcp &>/dev/null
sudo firewall-cmd --permanent --add-port=80/tcp &>/dev/null
sudo firewall-cmd --zone=public --change-interface=ens4 --permanent &>/dev/null
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent &>/dev/null
sudo firewall-cmd --reload &>/dev/null
echo "Done."

echo -e "\nSUCCESS! Jenkins is now available at port 80\n"

