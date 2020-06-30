#!/bin/bash
Assuming this is a CentOs 8 UDF VM - the following applies
Update the VM
sudo yum update -y
sudo reboot
sudo dnf install -y python3-devel jq ipmitool tmux tar bind-utils dnsmasq nginx telnet wget
vi /etc/selinux/config
    change the line to:
    SELINUX=disabled
sudo reboot

systemctl enable chronyd.service
systemctl restart chronyd.service

sudo vi /etc/hosts
copy in the hosts file contents - dG to delete all in vi

sudo vi /etc/resolv.conf
copy inthe resolv.conf file contents

Make a directory for NGINX and get your secrets file.
sudo mkdir /usr/share/nginx/html/installations
sudo chmod -R g+srwx /usr/share/nginx/html/

Open a browser to https://cloud.redhat.com/openshift/install/metal/user-provisioned -- download the following file and store it on the Web node in the following directory /usr/share/nginx/html/installations
Download pull secret > pull-secret.txt

Download some installation files
cd /usr/share/nginx/html/installations
sudo wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.3/openshift-install-linux-4.4.3.tar.gz
sudo wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.3/openshift-client-linux-4.4.3.tar.gz
sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-4.4.3-x86_64-metal.x86_64.raw.gz
sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-4.4.3-x86_64-installer-kernel-x86_64
sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-4.4.3-x86_64-installer-initramfs.x86_64.img

sudo tar xvf /usr/share/nginx/html/installations/openshift-client-linux-4.4.3.tar.gz
sudo tar xvf /usr/share/nginx/html/installations/openshift-install-linux-4.4.3.tar.gz

NGINX Installation
sudo systemctl enable nginx
sudo systemctl start nginx
sudo vi /etc/nginx/nginx.conf
Replace the existing listen directives under server { within the http context with the following
    listen       10.1.10.150:8080 default_server;

sudo nginx -s reload
sudo systemctl status nginx

Create the OpenShift installation configuration file.  Once created the certificate inside this file is only good for 24 Hours.
If you do not complete the OpenShift cluster installation within that time you will need to start over beginning at Preparing for OpenShift Installation

sudo vi /usr/share/nginx/html/installations/install-config.yaml
    Add the following lines in it: where the pullSecret is from https://cloud.redhat.com/openshift/install/metal/user-provisioned
    and the rest from the install-config.yaml file contents
    
sudo cp install-config.yaml install-config-bak.yaml

Creating the Kubernetes manifest and Ignition config files
    sudo /usr/share/nginx/html/installations/openshift-install create manifests --dir=/usr/share/nginx/html/installations/
    sudo vi /usr/share/nginx/html/installations/manifests/cluster-scheduler-02-config.yml
        Locate the mastersSchedulable parameter and set its value to false
        Save and exit the file
    
    sudo /usr/share/nginx/html/installations/openshift-install create ignition-configs --dir=/usr/share/nginx/html/installations/
    sudo chmod o+r /usr/share/nginx/html/installations/*
    
Provision the required load balancers
    sudo vi /etc/nginx/nginx.conf
    sudo nginx -s reload
    sudo systemctl status nginx
    systemctl status dnsmasq.service
    
Create the Credentials to Log in to the OpenShift Cluster
    vi $HOME/source.rc
        add these 2 lines to the file
        export KUBECONFIG=/usr/share/nginx/html/installations/auth/kubeconfig
        PATH=$PATH:/usr/share/nginx/html/installations
        
        ip a add 10.1.10.100/24 dev eth1


    
    
    