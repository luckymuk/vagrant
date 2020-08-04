1.  SSH into the Web - Bastion VM
    Update the VM
        sudo yum update -y
        sudo reboot
    
2.  Add some additonal Packages:
        sudo dnf install -y python3-devel jq ipmitool tmux tar bind-utils dnsmasq nginx telnet wget tcpdump
        sudo vi /etc/selinux/config
            If needed change the line to:
                SELINUX=disabled
        sudo reboot

3. We are going to enable NTP and DNSMASQ
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
        sudo su
        vi $HOME/source.rc
            add these 2 lines to the file
                export KUBECONFIG=/usr/share/nginx/html/installations/auth/kubeconfig
                PATH=$PATH:/usr/share/nginx/html/installations
        source $HOME/source.rc

10.  *** Go to the Masters Install Now ***
        
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

17. Upgrade to Openshift 4.4.5
        Place the OpenShift Cluster in a Unmanaged or offline stat
            oc patch --type='json' configs.samples cluster -p '[{"op": "add", "path": "/spec/managementState", "value": "Unmanaged"}]'
        Perfrom the Upgrade
            oc adm upgrade --to-image=quay.io/openshift-release-dev/ocp-release:4.4.5-x86_64 --allow-explicit-upgrade --force
        Watch the upgrade - 60 minutes
            watch "oc get clusterversion,nodes;oc get co| head -1;oc get co | grep 4.4.3; oc get co | head -1; oc get co | grep 4.4.5; oc get po -A -o wide | egrep -vi 'running|completed'" 
        Return the OpenShift Cluster to a Managed or online state 
            oc patch --type='json' configs.samples cluster -p '[{"op": "add", "path": "/spec/managementState", "value": "Managed"}]'
        Check version
            oc version
            
18. Subscribing to the Container-native virtualization catalog
        Follow the instructions here - https://gitlab.com/f5-vwells/vega-f5-only/-/blob/master/sp-lab/OpenShift_Lab_Build_Instructions/procedures/12-Installing_Container_Native_Virtualization.md
        
        Short Form below:
        RDP into jumphost and add the following to the hosts file c:\windows\system32\drivers\etc\hosts
            10.1.1.4 console-openshift-console.apps.openshift.aspenlab oauth-openshift.apps.openshift.aspenlab
        On the web node run the following to get the consoleURL and password
            oc edit console.config.openshift.io
                It will return consoleURL: https://console-openshift-console.apps.openshift.aspenlab
            cat /usr/share/nginx/html/installations/auth/kubeadmin-password
                for me it was: 9SoMf-kYCbT-JKdbk-xN6vK
        Open a browser on the jumphost and browse:
            https://console-openshift-console.apps.openshift.aspenlab
        and login with:
            kubeadmin:9SoMf-kYCbT-JKdbk-xN6vK
        Navigate to the Operators > OperatorHub page
        Search for Container-native virtualization and then select it
        Click Install
        On the Create Operator Subscription page
        For Installed Namespace, ensure that the Operator recommended namespace option is selected.
        Click Subscribe
        From the Operators > Installed Operators page make sure you are in the openshift-cnv ProjectClick Container-native virtualization
        Click the CNV Operator Deployment tab and click Create HyperConverged Cluster
        Ensure that the custom resource is named the default kubevirt-hyperconverged
        Create
        
        On the web node run this command to check the installation status:
            oc get pod --all-namespaces | grep cni
            
        