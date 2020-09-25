# EC2-Nginix

## 1. Introduction 
The objective of project is to use Ansible to automate the process of Nginx Deployment in AWS EC2 environment. It consits of 4 main steps (playbook):
- `Instance Provision`, launch and provision AWS EC2 Instance
- `Instance Setup`, install Docker Engine and setup OS Firewall 
- `App Setup`, start Nginx Docker Image; and run monitoring script. 
- `App Validation`, run the health check for Nginix and process the html page date. 

By considering the future CI/CD work 4 Ansible Playbook created to perfrom the above steps. The Dirctory Structure is listed below:
```
├── ansible.cfg
├── app_setup.yml
├── app_validation.yml
├── group_vars
│   ├── all
│   │   └── pass.yml
│   └── etc
│       ├── default.yml
│       └── hosts.yml
├── instance_provision.yml
├── instance_setup.yml
└── script
    └── container_monitor.sh
```

## 2. Pre Requisite
### 2.1 AWS Account Setup 
 * Follow the [instruction](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) to create a account. 
 * Follow the [instruction](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) to create IAM user, attach `AmazonEC2FullAccess` permission policy to the user. Take note of the Access Key and Secret Key that will be used by Ansible to set up the instances.
 ### 2.2 Install Ansible and EC2 Module 
 ```
sudo apt install python
sudo apt install python-pip
pip install boto boto3 ansible
```
### 2.3 Create SSH key pair 
This is the key pair for SSH connection to EC2 instance. To generate the key pari:
```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my_aws
```
### 2.4 Create Ansible Vault File 
Clone or create the above directory, create ansible vault file to save AWS access and secret keys.
```
ansible-vault create group_vars/all/pass.yml
New Vault password:
Confirm New Vault password:
```
Save the keys in the file 
```
ansible-vault edit group_vars/all/pass.yml 
Vault password:
ec2_access_key: <this is your access key>                                      
ec2_secret_key: <this is your secret key>
```

## 3. Running 

### 3.1 Instance Provision 
To lunch and provision a EC2 instance , run
```
ansible-playbook instance_provision.yml --ask-vault-pass --tags create_ec2
```
It will perfrom the tasks include: 
* Upload created SSH public key to AWS 
* Create security group which all SSH, HTTP and Ping Procotol 
* Launch a micro EC2 instance in created security group
* Show the instance public IP. 
The following message will be printed out to show the status of created instance: 
```
"msg": "ID: i-0eca013314629635c - State: running - Public IP: 18.133.142.154"
```
### 3.2 Add Host
Replace the value of `ansible_host` in `group_vars/etc/hosts.yml` by the IP address provied in above message.  
Note this step can be improved to be automated. 


### 3.3 Instance SetUp 
To setup the created instance, run
```
ansible-playbook instance_setup.yml --ask-vault-pass
```
It will install Docker Engine in the instance, and active firewall with SSH, HTTP traffic allowed.  The following message will be printed in the end to show the firewall status 
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
80/tcp (v6)                ALLOW       Anywhere (v6)
```
Note that the Ping Traffic is set to be allowed by default by [UWF](https://help.ubuntu.com/community/UFW). The OS firewall is setup as duplicate with AWS security group for two reasons 1) it protect if the instance aws security group is changed by mistake; 2) protect the system if it need to be migrated to other platform.

### 3.4 App Setup 
To setup the Nginix, run 

```
ansible-playbook app_setup.yml --ask-vault-pass
```
It will pull and run the Nginx Docker image, and expose port 80.  It also runs a monitor script `container_monitor.log` to record the docker container memory usage info for troubleshooting propose. The recorded data saved in `/var/log/container_monitor.log`. The follwoing info is recorded in the file 
```
Time-mm-dd-yy-H:M:S CONTAINER ID        NAME                CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
09-25-2020-15:31:20 cc6dc431d56a        nginx-docker        0.00%               2.301MiB / 978.6MiB   0.24%               10.2kB / 12kB       4.71MB / 8.19kB     2
09-25-2020-15:31:23 cc6dc431d56a        nginx-docker        0.00%               2.301MiB / 978.6MiB   0.24%               10.2kB / 12kB       4.71MB / 8.19kB     2
09-25-2020-15:31:25 cc6dc431d56a        nginx-docker        0.00%               2.301MiB / 978.6MiB   0.24%               10.2kB / 12kB       4.71MB / 8.19kB     2
09-25-2020-15:31:28 cc6dc431d56a        nginx-docker        0.00%               2.301MiB / 978.6MiB   0.24%               10.2kB / 12kB       4.71MB / 8.19kB     2
09-25-2020-15:31:30 cc6dc431d56a        nginx-docker        0.00%               2.301MiB / 978.6MiB   0.24%               10.2kB / 12kB       4.71MB / 8.19kB     2
```
 
### 3.5 App Validation 
This step is to test the liveness of Nginxi Application and process the http page. To do it , run 
```
ansible-playbook app_validation.yml --ask-vault-pass
```
The following message will be printed to show the app's liveness, raw data of http page, text in the http page, word count and sorted output in alphabet order.
```

TASK [validate if Nginx is running in the server] ****************************************************************************************************************
ok: [localhost]

TASK [strip html tags and count words] ***************************************************************************************************************************
changed: [localhost]

TASK [show stripped  result] *************************************************************************************************************************************
ok: [localhost] => {
    "msg": [
        "The stripped result is",
        "   Welcome to nginx!      Welcome to nginx! If you see this page, the nginx web server is successfully installed and working. Further configuration is required. For online documentation and support please refer to nginx.org. Commercial support is available at nginx.com. Thank you for using nginx.  "
    ]
}

TASK [count the words in result] *********************************************************************************************************************************
changed: [localhost]

TASK [length] ****************************************************************************************************************************************************
ok: [localhost] => {
    "msg": "There are       44 words in the html"
}

TASK [sort the words] ********************************************************************************************************************************************
changed: [localhost]

TASK [show sorted_result] ****************************************************************************************************************************************
ok: [localhost] => {
    "msg": [
        "The alphabet sorted results is:",
        "and and at available Commercial configuration documentation For for Further If installed is is is nginx nginx! nginx! nginx. nginx.com. nginx.org. online page, please refer required. see server successfully support support Thank the this to to to using web Welcome Welcome working. you you"
    ]
}
```

## 4. Future Improvment 
### 4.1 Automate Adding Host 
The step 3.2 above can be automated by using [AWS EC2 Plugin](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html). 
### 4.2 CI/CD Intergation 
The playbooks are organised for CI/CD intergation work. A pipeline can be created to excute Instance Provisioning -> Instance Setup -> App Setup -> App Validation (Test). The ansible vault pass can be replaced by CI encrypted variables. 
### 4.3 Monitoring Tools 
A script is used to log the Nginx container usage in this script. In production, there are multiple open source tools can be used to monitor the application running. e.g [prometheus](https://prometheus.io/) 
### 4.4 Kubernetes Intergation 
This project runs the docker application in a single instance. In production, scalability, high availbility, deployment downtime, Self-Healing etc are needed to be carefully considered. [Kubernetes](https://kubernetes.io/) is a orchestration platform which can be used to enhance the system reliability. 
