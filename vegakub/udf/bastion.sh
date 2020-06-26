#!/bin/bash

sudo yum update -y
reboot

sudo dnf install -y libvirt qemu-kvm mkisofs python3-devel jq ipmitool tmux tar bind-utils dnsmasq virt-install nginx telnet
reboot

sudo systemctl enable libvirtd
sudo systemctl start libvirtd
curl -O -L -J http://10.1.1.4/installations/rhcos-4.4.3-x86_64-installer-kernel-x86_64
curl -O -L -J http://10.1.1.4/installations/rhcos-4.4.3-x86_64-installer-initramfs.x86_64.img
sudo mv rhcos-4.4.3-x86_64-installer-kernel-x86_64 /boot/vmlinuz-rhcos
sudo mv rhcos-4.4.3-x86_64-installer-initramfs.x86_64.img /boot/initramfs-rhcos.img
sudo grubby --add-kernel=/boot/vmlinuz-rhcos --args="ip=10.1.1.7::10.1.1.1:255.255.255.0:bootstrap.dc1.example.com:ens5:none nameserver=10.1.1.7 rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://10.1.1.4/installations/rhcos-4.4.3-x86_64-metal.x86_64.raw.gz coreos.inst.ignition_url=http://10.1.1.4:/installations/bootstrap.ign console=ttyS0" --initrd=/boot/initramfs-rhcos.img --make-default --title=Tester-rhcos
