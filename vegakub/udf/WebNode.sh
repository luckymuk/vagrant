#!/bin/bash
Assuming this is a CentOs 8 UDF VM - the following applies
Update the VM
sudo yum update -y
sudo reboot
sudo dnf install -y python3-devel jq ipmitool tmux tar bind-utils dnsmasq nginx telnet
sudo reboot

Make a directory for NGINX and get your secrets file.
sudo mkdir /usr/share/nginx/html/installations
sudo chown -R :libvirt /usr/share/nginx/html/sudo chmod -R g+srwx /usr/share/nginx/html/
Open a browser to https://cloud.redhat.com/openshift/install/metal/user-provisioned -- download the following file and store it on the Bastion node in the following directory /usr/share/nginx/html/installations
Download pull secret > pull-secret.txt

Download some installation files
cd /usr/share/nginx/html/installations
udo wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.3/openshift-install-linux-4.4.3.tar.gz
sudo wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.3/openshift-client-linux-4.4.3.tar.gz
sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-4.4.3-x86_64-metal.x86_64.raw.gz


tar xvf /usr/share/nginx/html/installations/openshift-client-linux-4.4.3.tar.gz
tar xvf /usr/share/nginx/html/installations/openshift-install-linux-4.4.3.tar.gz

NGINX Installation
sudo systemctl enable nginx
sudo systemctl start nginx
sudo vi /etc/nginx/nginx.conf
Replace the existing listen directives under server { within the http context with the following
    listen       10.1.1.4:80 default_server;
    root         /usr/share/nginx/html/installations;

sudo nginx -s reload
systemctl status nginx

Create the OpenShift installation configuration file
vi /usr/share/nginx/html/installations/install-config.yaml


Create the OpenShift installation configuration file.  Once created the certificate inside this file is only good for 24 Hours.
If you do not complete the OpenShift cluster installation within that time you will need to start over beginning at Preparing for OpenShift Installation

vi /usr/share/nginx/html/installations/install-config.yaml
Also edit the nodes=1
Master=1
Delete the network lines

Change the next two lines with the below ones:
        pullSecret: '<insert pull-secret text here>'
        sshKey: '<insert users id_rsa.pub ssh key here>'
    pullSecret: Copy the contents of the pull-secret.txt file that you downloaded previously (cat /usr/share/nginx/html/installations/pull-secret.txt) between the '  ' to set the pullSecret: value
    Use this these next two lines in the ssh section:
        ## The default SSH key that will be programmed for `core` user.
        sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCLK8LTLF0ILRMVwGwSSmDZRGSypWVLwbfIB66H0HOwvdubCY/0PqoAiJn/r/XeZ1Nve84IFZJ2EHTjwKdhEIJ2rT+7/cqirBr03EwM0H7fZG5lnqnGwqW1/nuNWva8vjjyTXDoOzW8KT0qrjhfbVoaQ71SUYIDXgqp0NCZXAYyoVF5aOuEM1zAfX3G8gu+iEL32xuOFiAyFE7E1h1GdpL3rvwV8yb4Ox+o/3yHgcQse1ou7dYNIpy+OTh4Lj7pl+AKPSzJ0EB94M5gMhyI5nVyUXIvWR9MKDr2H8uiWXpiH/Asc2FgkCzLijXlLU0dr95+TEZaFZNVdUkt/KE9gmfN access-method-key'
cp install-config.yaml install-config-bak.yaml

Creating the Kubernetes manifest and Ignition config files
    /usr/share/nginx/html/installations/openshift-install create manifests --dir=/usr/share/nginx/html/installations/
    vi /usr/share/nginx/html/installations/manifests/cluster-scheduler-02-config.yml
        Locate the mastersSchedulable parameter and set its value to False
        Save and exit the file
    
    /usr/share/nginx/html/installations/openshift-install create ignition-configs --dir=/usr/share/nginx/html/installations/
    sudo chmod o+r /usr/share/nginx/html/installations/*
    