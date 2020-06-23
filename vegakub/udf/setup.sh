#!/bin/bash
clear
echo "Good morning, WebScale user.  Lets Do this !!!"

mkdir -p -- ~/playbooks
mkdir -p -- ~/extra

echo "Install the required libraries for UDF"
echo ""
echo "Updating machine"
echo ""
sudo dnf upgrade -y
echo ""
echo "Installing python3"
echo ""
sudo dnf -y install python3
echo ""
echo "Installing ansible"
echo ""
pip3 install ansible --user
echo ""
echo "Installing git"
echo ""
sudo dnf -y install git
echo ""
echo "Cloning Vega Repo"
echo ""

git clone https://github.com/luckymuk/vagrant.git ~/playbooks

ansible-playbook ~/playbooks/vegakub/ansible/f5.yml --tags add-libraries -c local --extra-vars host=localhost --extra-vars env=dev
