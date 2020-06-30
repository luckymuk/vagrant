#!/bin/bash

sudo rm -f -R /usr/share/nginx/html/installations/

sudo rm -f /var/lib/vm/disks/*

sudo rm -f /var/lib/vm/images/rhcos-installer-bootstrap.iso
sudo rm -f /var/lib/vm/images/rhcos-installer-master.iso
sudo rm -f /var/lib/vm/images/rhcos-installer-worker.iso

rm -f $HOME/.ssh/known_hosts
rm -f $HOME/source.rc

sudo rm -rf $HOME/iso-copy

sudo systemctl stop nginx
sudo systemctl start nginx
