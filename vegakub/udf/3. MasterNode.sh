#!/bin/bash

#sudo yum update -y
#sudo reboot

#sudo dnf install -y libvirt qemu-kvm mkisofs python3-devel jq ipmitool tmux tar bind-utils dnsmasq virt-install nginx telnet
#sudo reboot

sudo curl -O -L -J http://10.1.1.4/installations/rhcos-4.4.3-x86_64-installer-kernel-x86_64
sudo curl -O -L -J http://10.1.1.4/installations/rhcos-4.4.3-x86_64-installer-initramfs.x86_64.img
sudo mv rhcos-4.4.3-x86_64-installer-kernel-x86_64 /boot/vmlinuz-rhcos
sudo mv rhcos-4.4.3-x86_64-installer-initramfs.x86_64.img /boot/initramfs-rhcos.img

Change the below line to reflect the IP of the VM you are working on.
hostname -i
sudo grubby --add-kernel=/boot/vmlinuz-rhcos --args="ip=10.1.1.6::10.1.1.1:255.255.255.0:master.dc1.example.com:ens5:none nameserver=10.1.1.6 rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://10.1.1.4/installations/rhcos-4.4.3-x86_64-metal.x86_64.raw.gz coreos.inst.ignition_url=http://10.1.1.4:/installations/master.ign console=ttyS0" --initrd=/boot/initramfs-rhcos.img --make-default --title=rhcos
sudo reboot
Watch the console to see if it worked
add core user to UDF to each of the VM's you did the above provedure to.

ssh into it once it is up as core user.
