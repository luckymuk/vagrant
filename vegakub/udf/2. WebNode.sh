#!/bin/bash
Assuming this is a CentOs 8 UDF VM - the following applies
Update the VM
sudo yum update -y
sudo reboot
sudo dnf install -y python3-devel jq ipmitool tmux tar bind-utils dnsmasq nginx telnet wget
sudo reboot

systemctl enable chronyd.service
systemctl restart chronyd.service

sudo vi /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
#DNS for bastion node and bootstrap node
10.1.1.4  api-int.openshift.aspenlab api.openshift.aspenlab
10.1.1.4  aspen-node-1.openshift.aspenlab aspen-node-1 provisioner-web.openshift.aspenlab provisioner-web
10.1.1.5  bootstrap.openshift.aspenlab bootstrap bootstrap


#DNS for master nodes
10.1.1.6  master-1.openshift.aspenlab master-1

#ETCd cluster lives on the masters
10.1.1.6  etcd-0.openshift.aspenlab etcd-0

#DNS for worker nodes
10.1.1.7  aspen-node-2.openshift.aspenlab aspen-node-2



Make a directory for NGINX and get your secrets file.
sudo mkdir /usr/share/nginx/html/installations
sudo chmod -R g+srwx /usr/share/nginx/html/
# sudo chown -R :libvirt /usr/share/nginx/html/sudo chmod -R g+srwx /usr/share/nginx/html/
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
    listen       10.1.1.4:80 default_server;

sudo nginx -s reload
systemctl status nginx

Create the OpenShift installation configuration file.  Once created the certificate inside this file is only good for 24 Hours.
If you do not complete the OpenShift cluster installation within that time you will need to start over beginning at Preparing for OpenShift Installation

sudo vi /usr/share/nginx/html/installations/install-config.yaml
    Add the following lines in it: where the pullSecret is from https://cloud.redhat.com/openshift/install/metal/user-provisioned
    
apiVersion: v1
baseDomain: aspenlab
compute:
- name: worker
  replicas: 1
controlPlane:
  name: master
  replicas: 1
metadata:
  name: openshift
platform:
  none: {}
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2RncmltYXJkNzFkbHM2ZHFxamZueXdsdG1yanB3b3FpaW5maDpIUkNHUTlCMDNJQkxJMUYxWUpWOTBCV1IxTVBLQzBSVEI0VFBZSU40MlJUSU9DUU9GN05VVEo5UDZRVkk4UTJU","email":"d.grimard@f5.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2RncmltYXJkNzFkbHM2ZHFxamZueXdsdG1yanB3b3FpaW5maDpIUkNHUTlCMDNJQkxJMUYxWUpWOTBCV1IxTVBLQzBSVEI0VFBZSU40MlJUSU9DUU9GN05VVEo5UDZRVkk4UTJU","email":"d.grimard@f5.com"},"registry.connect.redhat.com":{"auth":"NTM1MzQ1MjZ8dWhjLTFkbHM2RHFRSkZOeXdsdG1SSlBXT1FJaU5GaDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXpPR1F6TlRjNFptWmtNbUUwT1RJek9UVTVObVEwTURaa05tVTVNbVV4WmlKOS5XNVE5bmdGdTl6WllBT1JGTVE3WndTZC0wdW14VjJRVXZrTkdlRGlscFlvZDktVXJnTkhUdm9QNzRBS01TZXdMazJPbjdIOC12Q29uNW5JYnQwTGdFdU1xVmM4S05pb3lTaFdFRVdHc1ZPVUxhS1pEUDN0WFdqZElteTM1aE1ZNDJodkF0SC1qUEo2T3JfZEpMWHp2bHlkQ2hoUktLcnZfR3BYUUM4OXNieDBhM2wxejZqU0N5LTFYNzRCb3dMcGNPZ21ISHBpSUU5cEp1aTRTaVpTMTYwdE4td2FhMVRJcHVETE1IWDJzVUs2TnlfZUdTbXBub25lTUg2SGZ6eFd6UHZVV2tZOE0xMGpTVEFXUkk5TGFQeVphWm9KX0gwS1dEV3E1OURtT1NhVFJTalpqSVFPTDkwWTNDTFNKd3VtN1gwNzkwRmprZ3hGSk9GT0txTU45QlVBLTlOWTVXeXRmcGk4dUJPYkh4SW1WU29KUDI1V080bm1TMTlBY3J1SGpnVldySGJDWkpQS0tWMDBWdXZLdXJnN0YzWjhTUlhfS1REMWZKdkowSGtDOGxWRTJVQ1JhWjlHMVp2UVBscFlZVlBIRlNGcUVqSlF4b3BFNklmVi1SM1czV1FpQzNxeTkxX2RiU3psVzBTdEQ5ZDFVQXFsMnZubWo1V2l6ZXpUc2REbmMxZWFMaXNpbnlKYndzNjZzMDdySk42VHhJNDUtbHhtWE1WZ2NiRWlKbmY3T1FKaHJiNDQ4ZjBLQWhZM2pIMFFCdW9ZVUdmTldIdDhpNjJTRGNzTFRheEFETWxkcE9KamdEc0pYbzVjX2NKOEE3a0lWVkpCeUtKXzhVaXBZN1ZieWRqSk9BMGV6bTFCTm1QcEFDb3FmTHVDbU5lczRvNEhtRGtYUzRHOA==","email":"d.grimard@f5.com"},"registry.redhat.io":{"auth":"NTM1MzQ1MjZ8dWhjLTFkbHM2RHFRSkZOeXdsdG1SSlBXT1FJaU5GaDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXpPR1F6TlRjNFptWmtNbUUwT1RJek9UVTVObVEwTURaa05tVTVNbVV4WmlKOS5XNVE5bmdGdTl6WllBT1JGTVE3WndTZC0wdW14VjJRVXZrTkdlRGlscFlvZDktVXJnTkhUdm9QNzRBS01TZXdMazJPbjdIOC12Q29uNW5JYnQwTGdFdU1xVmM4S05pb3lTaFdFRVdHc1ZPVUxhS1pEUDN0WFdqZElteTM1aE1ZNDJodkF0SC1qUEo2T3JfZEpMWHp2bHlkQ2hoUktLcnZfR3BYUUM4OXNieDBhM2wxejZqU0N5LTFYNzRCb3dMcGNPZ21ISHBpSUU5cEp1aTRTaVpTMTYwdE4td2FhMVRJcHVETE1IWDJzVUs2TnlfZUdTbXBub25lTUg2SGZ6eFd6UHZVV2tZOE0xMGpTVEFXUkk5TGFQeVphWm9KX0gwS1dEV3E1OURtT1NhVFJTalpqSVFPTDkwWTNDTFNKd3VtN1gwNzkwRmprZ3hGSk9GT0txTU45QlVBLTlOWTVXeXRmcGk4dUJPYkh4SW1WU29KUDI1V080bm1TMTlBY3J1SGpnVldySGJDWkpQS0tWMDBWdXZLdXJnN0YzWjhTUlhfS1REMWZKdkowSGtDOGxWRTJVQ1JhWjlHMVp2UVBscFlZVlBIRlNGcUVqSlF4b3BFNklmVi1SM1czV1FpQzNxeTkxX2RiU3psVzBTdEQ5ZDFVQXFsMnZubWo1V2l6ZXpUc2REbmMxZWFMaXNpbnlKYndzNjZzMDdySk42VHhJNDUtbHhtWE1WZ2NiRWlKbmY3T1FKaHJiNDQ4ZjBLQWhZM2pIMFFCdW9ZVUdmTldIdDhpNjJTRGNzTFRheEFETWxkcE9KamdEc0pYbzVjX2NKOEE3a0lWVkpCeUtKXzhVaXBZN1ZieWRqSk9BMGV6bTFCTm1QcEFDb3FmTHVDbU5lczRvNEhtRGtYUzRHOA==","email":"d.grimard@f5.com"}}}'
## The default SSH key that will be programmed for `core` user.
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCLK8LTLF0ILRMVwGwSSmDZRGSypWVLwbfIB66H0HOwvdubCY/0PqoAiJn/r/XeZ1Nve84IFZJ2EHTjwKdhEIJ2rT+7/cqirBr03EwM0H7fZG5lnqnGwqW1/nuNWva8vjjyTXDoOzW8KT0qrjhfbVoaQ71SUYIDXgqp0NCZXAYyoVF5aOuEM1zAfX3G8gu+iEL32xuOFiAyFE7E1h1GdpL3rvwV8yb4Ox+o/3yHgcQse1ou7dYNIpy+OTh4Lj7pl+AKPSzJ0EB94M5gMhyI5nVyUXIvWR9MKDr2H8uiWXpiH/Asc2FgkCzLijXlLU0dr95+TEZaFZNVdUkt/KE9gmfN access-method-key'


#Also edit the nodes=1
#Master=1
#Delete the network lines

#Change the next two lines with the below ones:
#        pullSecret: '<insert pull-secret text here>'
#        sshKey: '<insert users id_rsa.pub ssh key here>'
#    pullSecret: Copy the contents of the pull-secret.txt file that you downloaded previously (cat /usr/share/nginx/html/installations/pull-secret.txt) between the '  ' to set the pullSecret: value
#    Use this these next two lines in the ssh section:
#        pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2RncmltYXJkNzFkbHM2ZHFxamZueXdsdG1yanB3b3FpaW5maDpIUkNHUTlCMDNJQkxJMUYxWUpWOTBCV1IxTVBLQzBSVEI0VFBZSU40MlJUSU9DUU9GN05VVEo5UDZRVkk4UTJU","email":"d.grimard@f5.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K2RncmltYXJkNzFkbHM2ZHFxamZueXdsdG1yanB3b3FpaW5maDpIUkNHUTlCMDNJQkxJMUYxWUpWOTBCV1IxTVBLQzBSVEI0VFBZSU40MlJUSU9DUU9GN05VVEo5UDZRVkk4UTJU","email":"d.grimard@f5.com"},"registry.connect.redhat.com":{"auth":"NTM1MzQ1MjZ8dWhjLTFkbHM2RHFRSkZOeXdsdG1SSlBXT1FJaU5GaDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXpPR1F6TlRjNFptWmtNbUUwT1RJek9UVTVObVEwTURaa05tVTVNbVV4WmlKOS5XNVE5bmdGdTl6WllBT1JGTVE3WndTZC0wdW14VjJRVXZrTkdlRGlscFlvZDktVXJnTkhUdm9QNzRBS01TZXdMazJPbjdIOC12Q29uNW5JYnQwTGdFdU1xVmM4S05pb3lTaFdFRVdHc1ZPVUxhS1pEUDN0WFdqZElteTM1aE1ZNDJodkF0SC1qUEo2T3JfZEpMWHp2bHlkQ2hoUktLcnZfR3BYUUM4OXNieDBhM2wxejZqU0N5LTFYNzRCb3dMcGNPZ21ISHBpSUU5cEp1aTRTaVpTMTYwdE4td2FhMVRJcHVETE1IWDJzVUs2TnlfZUdTbXBub25lTUg2SGZ6eFd6UHZVV2tZOE0xMGpTVEFXUkk5TGFQeVphWm9KX0gwS1dEV3E1OURtT1NhVFJTalpqSVFPTDkwWTNDTFNKd3VtN1gwNzkwRmprZ3hGSk9GT0txTU45QlVBLTlOWTVXeXRmcGk4dUJPYkh4SW1WU29KUDI1V080bm1TMTlBY3J1SGpnVldySGJDWkpQS0tWMDBWdXZLdXJnN0YzWjhTUlhfS1REMWZKdkowSGtDOGxWRTJVQ1JhWjlHMVp2UVBscFlZVlBIRlNGcUVqSlF4b3BFNklmVi1SM1czV1FpQzNxeTkxX2RiU3psVzBTdEQ5ZDFVQXFsMnZubWo1V2l6ZXpUc2REbmMxZWFMaXNpbnlKYndzNjZzMDdySk42VHhJNDUtbHhtWE1WZ2NiRWlKbmY3T1FKaHJiNDQ4ZjBLQWhZM2pIMFFCdW9ZVUdmTldIdDhpNjJTRGNzTFRheEFETWxkcE9KamdEc0pYbzVjX2NKOEE3a0lWVkpCeUtKXzhVaXBZN1ZieWRqSk9BMGV6bTFCTm1QcEFDb3FmTHVDbU5lczRvNEhtRGtYUzRHOA==","email":"d.grimard@f5.com"},"registry.redhat.io":{"auth":"NTM1MzQ1MjZ8dWhjLTFkbHM2RHFRSkZOeXdsdG1SSlBXT1FJaU5GaDpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXpPR1F6TlRjNFptWmtNbUUwT1RJek9UVTVObVEwTURaa05tVTVNbVV4WmlKOS5XNVE5bmdGdTl6WllBT1JGTVE3WndTZC0wdW14VjJRVXZrTkdlRGlscFlvZDktVXJnTkhUdm9QNzRBS01TZXdMazJPbjdIOC12Q29uNW5JYnQwTGdFdU1xVmM4S05pb3lTaFdFRVdHc1ZPVUxhS1pEUDN0WFdqZElteTM1aE1ZNDJodkF0SC1qUEo2T3JfZEpMWHp2bHlkQ2hoUktLcnZfR3BYUUM4OXNieDBhM2wxejZqU0N5LTFYNzRCb3dMcGNPZ21ISHBpSUU5cEp1aTRTaVpTMTYwdE4td2FhMVRJcHVETE1IWDJzVUs2TnlfZUdTbXBub25lTUg2SGZ6eFd6UHZVV2tZOE0xMGpTVEFXUkk5TGFQeVphWm9KX0gwS1dEV3E1OURtT1NhVFJTalpqSVFPTDkwWTNDTFNKd3VtN1gwNzkwRmprZ3hGSk9GT0txTU45QlVBLTlOWTVXeXRmcGk4dUJPYkh4SW1WU29KUDI1V080bm1TMTlBY3J1SGpnVldySGJDWkpQS0tWMDBWdXZLdXJnN0YzWjhTUlhfS1REMWZKdkowSGtDOGxWRTJVQ1JhWjlHMVp2UVBscFlZVlBIRlNGcUVqSlF4b3BFNklmVi1SM1czV1FpQzNxeTkxX2RiU3psVzBTdEQ5ZDFVQXFsMnZubWo1V2l6ZXpUc2REbmMxZWFMaXNpbnlKYndzNjZzMDdySk42VHhJNDUtbHhtWE1WZ2NiRWlKbmY3T1FKaHJiNDQ4ZjBLQWhZM2pIMFFCdW9ZVUdmTldIdDhpNjJTRGNzTFRheEFETWxkcE9KamdEc0pYbzVjX2NKOEE3a0lWVkpCeUtKXzhVaXBZN1ZieWRqSk9BMGV6bTFCTm1QcEFDb3FmTHVDbU5lczRvNEhtRGtYUzRHOA==","email":"d.grimard@f5.com"}}}'
        ## The default SSH key that will be programmed for `core` user.
#        sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCLK8LTLF0ILRMVwGwSSmDZRGSypWVLwbfIB66H0HOwvdubCY/0PqoAiJn/r/XeZ1Nve84IFZJ2EHTjwKdhEIJ2rT+7/cqirBr03EwM0H7fZG5lnqnGwqW1/nuNWva8vjjyTXDoOzW8KT0qrjhfbVoaQ71SUYIDXgqp0NCZXAYyoVF5aOuEM1zAfX3G8gu+iEL32xuOFiAyFE7E1h1GdpL3rvwV8yb4Ox+o/3yHgcQse1ou7dYNIpy+OTh4Lj7pl+AKPSzJ0EB94M5gMhyI5nVyUXIvWR9MKDr2H8uiWXpiH/Asc2FgkCzLijXlLU0dr95+TEZaFZNVdUkt/KE9gmfN access-method-key'
#cp install-config.yaml install-config-bak.yaml

Creating the Kubernetes manifest and Ignition config files
    sudo /usr/share/nginx/html/installations/openshift-install create manifests --dir=/usr/share/nginx/html/installations/
    #sudo vi /usr/share/nginx/html/installations/manifests/cluster-scheduler-02-config.yml
    #    Locate the mastersSchedulable parameter and set its value to False
    #    Save and exit the file
    
    sudo /usr/share/nginx/html/installations/openshift-install create ignition-configs --dir=/usr/share/nginx/html/installations/
    sudo chmod o+r /usr/share/nginx/html/installations/*
    