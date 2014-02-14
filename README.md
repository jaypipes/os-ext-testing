# OpenStack External Test Platform

!! THIS REPOSITORY IS VERY MUCH A WORK IN PROGRESS !!

PLEASE USE AT YOUR OWN RISK AND PROVIDE FEEDBACK IF YOU CAN!

This repository contains documentation and modules in a variety
of configuration management systems that demonstrates setting up
a real-world external testing platform that links with the upstream
OpenStack CI platform.

It installs Jenkins, Jenkins Job Builder (JJB), the Gerrit
Jenkins plugin, and a set of scripts that make running a variety
of OpenStack integration tests easy.

Currently only Puppet modules are complete and tested. Ansible scripts
will follow afterwards.

## Pre-requisites

The following are pre-requisite steps before you install anything:

1. Get a Gerrit account for your testing system registered

2. Ensure base packages installed on your target hosts/VMs

3. Set up your data repository

Below are detailed instructions for each step.

### Registering an Upstream Gerrit Account

You will need to register a Gerrit account with the upstream OpenStack
CI platform. You can read the instructions for doing
[that](http://ci.openstack.org/third_party.html#requesting-a-service-account)

### Ensure Basic Packages on Hosts/VMs

We will be installing a Jenkins master server and infrastructure on one
host or virtual machine and one or more Jenkins slave servers on hosts or VMs.

On each of these target nodes, you will want the base image to have the 
`wget`, `openssl`, `ssl-cert` and `ca-certificates` packages installed before
running anything in this repository.

### Set Up Your Data Repository 

You will want to create a Git repository containing configuration data files -- such as the
Gerrit username and private SSH key file for your testing account -- that are used
in setting up the test platform.

The easiest way to get your data repository set up is to make a copy of the example
repository I set up here:

http://github.com/jaypipes/os-ext-testing-data

and put it somewhere private. There are a few things you will need to do in this
data repository:

1. Copy the **private** SSH key that you submitted when you registered with the upstream
   OpenStack Infrastructure team into somewhere in this repo.

2. If you do not want to use the SSH key pair in the `os-ext-testing-data` example
   data repository and want to create your own SSH key pair, do this step.

   Create an SSH key pair that you will use for Jenkins. This SSH key pair will live
   in the `/var/lib/jenkins/.ssh/` directory on the master Jenkins host, and it will
   be added to the `/home/jenkins/.ssh/authorized_keys` file of all slave hosts::

    ssh-keygen -t rsa -b 1024 -N '' -f jenkins_key

   Once you do the above, copy the `jenkins_key` and `jenkins_key.pub` files into your
   data repository.

3. Open up `vars.sh` in an editor.

4. Change the value of the `$UPSTREAM_GERRIT_USER` shell
   variable to the Gerrit username you registered with the upstream OpenStack Infrastructure
   team [as detailed in these instructions](http://ci.openstack.org/third_party.html#requesting-a-service-account)

5. Change the value of the `$UPSTREAM_GERRIT_SSH_KEY_PATH` shell variable to the **relative** path
   of the private SSH key file you copied into the repository in step #2.

   For example, let's say you put your private SSH key file named `mygerritkey` into a directory called `ssh`
   within the repository, you would set the `$UPSTREAM_GERRIT_SSH_KEY_PATH` value to
   `ssh/mygerritkey`

6. If for some reason, in step #2 above, you either used a different output filename than `jenkins_key` or put the
   key pair into some subdirectory of your data repository, then change the value of the `$JENKINS_SSH_KEY_PATH`
   variable in `vars.sh` to an appropriate value.

## Usage

### Setting up the Jenkins Master

#### Installation

On the machine you will use as your Jenkins master, run the following:

```
wget https://raw.github.com/jaypipes/os-ext-testing/master/puppet/install_master.sh
bash install_master.sh
```

The script will install Puppet, create an SSH key for the Jenkins master, create
self-signed certificates for Apache, and then will ask you for the URL of the Git
repository you are using as your data repository (see Prerequisites #3 above). Enter
the URL of your data repository and hit Enter.

Puppet will proceed to set up the Jenkins master.

#### Load Jenkins Up with Your Jobs

Run the following at the command line:

    sudo jenkins-jobs --flush-cache --delete-old update /etc/jenkins_jobs/config


#### Configuration

After Puppet installs Jenkins and Zuul, you will need to do a couple manual configuration
steps in the Jenkins UI.

1. Go to the Jenkins web UI. By default, this will be `http://$IP_OF_MASTER:8080`

2. Click the `Manage Jenkins` link on the left

3. Click the `Configure System` link

4. Scroll down until you see "Gearman Plugin Config". Check the "Enable Gearman" checkbox.

5. Click the "Test Connection" button and verify Jenkins connects to Gearman.

6. Scroll down to the bottom of the page and click `Save`

7. At the command line, do this::

    sudo service zuul restart

### Setting up Jenkins Slaves

On each machine you will use as a Jenkins slave, run:

```
wget https://raw.github.com/jaypipes/os-ext-testing/master/puppet/install_slave.sh
bash install_slave.sh
```

The script will install Puppet, install a Jenkins slave, and install the Jenkins master's
public SSH key in the `authorized_keys` of the Jenkins slave.

Once the script completes successfully, you need to add the slave node to
Jenkins master. To do so manually, follow these steps:

1. Go to the Jenkins web UI. By default, this will be `http://$IP_OF_MASTER:8080`

2. Click the `Credentials` link on the left

3. Click the `Global credentials` link

4. Click the `Add credentials` link on the left

5. Select `SSH username with private key` from the dropdown labeled "Kind"

6. Enter "jenkins" in the `Username` textbox

7. Select the "From a file on Jenkins master" radio button and enter `/var/lib/jenkins/.ssh/id_rsa` in the File textbox

8. Click the `OK` button

9. Click the "Jenkins" link in the upper left to go back to home page

10. Click the `Manage Jenkins` link on the left

11. Click the `Manage Nodes` link

12. Click the "New Node" link on the left

13. Enter `devstack_slave1` in the `Node name` textbox

14. Select the `Dumb Slave` radio button

15. Click the `OK` button

16. Enter `2` in the `Executors` textbox

17. Enter `/home/jenkins/workspaces` in the `Remote FS root` textbox

18. Enter `devstack_slave` in the `Labels` textbox

19. Enter the IP Address of your slave host or VM in the `Host` textbox

20. Select `jenkins` from the `Credentials` dropdown

21. Click the `Save` button

22. Click the `Log` link on the left. The log should show the master connecting
    to the slave, and at the end of the log should be: "Slave successfully connected and online"
