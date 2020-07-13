1.  SSH into the Web - Bastion VM
    Update the VM
        sudo yum update -y
        sudo reboot
    
2.  We Might need to bind this IP address - I dont hink so anymore
        #sudo vi /etc/sysconfig/network-scripts/ifcfg-eth1
        # Created by cloud-init on instance boot automatically, do not edit.
        #
        BOOTPROTO=static
        DEVICE=eth1
        HWADDR=52:54:00:3c:a4:da
        ONBOOT=yes
        TYPE=Ethernet
        IPADDR0=10.1.10.150
        # IPADDR1=10.1.10.100
        PREFIX0=24
        GATEWAY0=10.1.10.1
        USERCTL=no

3.  Add some additonal Packages:
        sudo dnf install -y python3-devel jq ipmitool tmux tar bind-utils dnsmasq nginx telnet wget
        sudo vi /etc/selinux/config
            If needed change the line to:
                SELINUX=disabled
        sudo reboot

4. We are going to enable NTP and DNSMASQ
       sudo systemctl enable chronyd.service
       sudo systemctl restart chronyd.service

       sudo vi /etc/hosts
           copy in the hosts file contents - dG to delete all in vi

       sudo vi /etc/resolv.conf
           copy inthe resolv.conf file contents

       sudo systemctl enable dnsmasq
       sudo systemctl restart dnsmasq

4.  NGINX config so we can serve web pages
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
                    listen       8080 default_server;

            sudo nginx -s reload
            sudo systemctl status nginx

5.  Create the OpenShift installation configuration file.  Once created the certificate inside this file is only good for 24 Hours.
    *** If you do not complete the OpenShift cluster installation within that time you will need to start over beginning at Preparing for OpenShift Installation

        sudo vi /usr/share/nginx/html/installations/install-config.yaml
            Add the following lines in it: where the pullSecret is from https://cloud.redhat.com/openshift/install/metal/user-provisioned
            and the rest from the install-config.yaml file contents
    
        sudo cp install-config.yaml install-config-bak.yaml

6.  Creating the Kubernetes manifest and Ignition config files
        sudo /usr/share/nginx/html/installations/openshift-install create manifests --dir=/usr/share/nginx/html/installations/
        sudo vi /usr/share/nginx/html/installations/manifests/cluster-scheduler-02-config.yml
            Locate the mastersSchedulable parameter and set its value to false
            Save and exit the file
    
        sudo /usr/share/nginx/html/installations/openshift-install create ignition-configs --dir=/usr/share/nginx/html/installations/
        sudo chmod o+r /usr/share/nginx/html/installations/*
        
7.  *** Go to the BootStrap Install Now ***
        
8.  Provision the required load balancers
    sudo vi /etc/nginx/nginx.conf
        Replace with the master-nginx.conf file contents
    sudo nginx -s reload
    sudo systemctl status nginx
    systemctl status dnsmasq.service
    
9.  Create the Credentials to Log in to the OpenShift Cluster
        vi $HOME/source.rc
            add these 2 lines to the file
                export KUBECONFIG=/usr/share/nginx/html/installations/auth/kubeconfig
                PATH=$PATH:/usr/share/nginx/html/installations

10.  *** Go to the Maters Install Now ***

        
11. Edit the nginx config for the worker nodes:
        sudo vi /etc/nginx/nginx.conf
            Replace with the worker-nginx.conf contents
        sudo nginx -s reload
        sudo systemctl status nginx
        systemctl status dnsmasq.service
        


12. *** Go to the Worker Node Install Now ***
        
13. Create the OpenShift Cluster
    on the bootstrap server
        Monitor the bootstrap process
            /usr/share/nginx/html/installations/openshift-install --dir=/usr/share/nginx/html/installations wait-for bootstrap-complete --log-level=info
        When it says
            INFO It is now safe to remove the bootstrap resources 
                Then you can proceed
14. Remove the bootstrap node from the nginx and add the workers
    sudo vi /etc/nginx/nginx.conf
        Replace with the remove-bootstrap-nginx.conf contents
    sudo nginx -s reload
    sudo systemctl status nginx
    systemctl status dnsmasq.service

15. Approving the CSRs for your machines
    On the web vm:
        Check that you have the Masters up:
            oc get nodes
        Review the pending certificate CSR's
            oc get csr
        Approve the pending CSR's
            oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
        Verify all machines are now recognized
            oc get nodes --all-namespaces

16. Power off the bootstrap node.
    

    
    
    