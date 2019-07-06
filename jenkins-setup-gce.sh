#!/bin/bash
#
# Script to set up Jenkins on an Ubuntu 16.04+ GCE instance
# on port 80 (HTTP port)
#
# Usage:
#	  ./jenkins-setup-gce.sh
#

echo -e "\n=========== INSTALLING JENKINS AND FIREWALLD ===========\n"
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins firewalld
sudo service jenkins start

echo -e "\n========= CONFIGURING JENKINS ON PORT 80 =========\n"
sudo firewall-cmd --zone=public --change-interface=ens4 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --reload
sudo systemctl mask ebtables
sudo systemctl restart firewalld
sudo systemctl disable ebtables

echo -e "\nALL DONE. Jenkins now available at port 80\n"
