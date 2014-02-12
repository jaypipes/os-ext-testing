# OpenStack External Test Platform Deployer

This repository contains documentation and modules in a variety
of configuration management systems that demonstrates setting up
a real-world external testing platform that links with the upstream
OpenStack CI platform.

It installs Jenkins, Jenkins Job Builder (JJB), the Gerrit
Jenkins plugin, and a set of scripts that make running a variety
of OpenStack integration tests easy.

Currently only Puppet modules are complete and tested. Ansible

## Pre-requisites

1) You will need to register a Gerrit account with the upstream OpenStack
CI platform. You can read the instructions for doing
[that](http://ci.openstack.org/third_party.html#requesting-a-service-account)

2) You will need to have the `wget`, `openssl`, `ssl-cert` and `ca-certificates`
packages installed on your host or VM before running anything in this
repository.

3) You will want to create a Git repository containing the data files -- such as the
Gerrit username and private SSH key file for your testing account -- that are used
in setting up the test platform.

## Usage

### Setting up the Jenkins Master

On the machine you will use as your Jenkins master, run:

```
wget https://raw.github.com/jaypipes/os-ext-testing/master/puppet/install_master.sh
bash install_master.sh
```

The script will install Puppet, create an SSH key for the Jenkins master, create
self-signed certificates for Apache, and then will ask you for the URL of the Git
repository you are using as your data repository (see Prerequisites #3 above). Enter
the URL of your data repository and hit Enter.

Puppet will proceed to set up the Jenkins master.

### Setting up Jenkins Slaves

On each machine you will use as a Jenkins slave, run:

```
wget https://raw.github.com/jaypipes/os-ext-testing/slave/puppet/install_slave.sh
bash install_slave.sh
```

The script will install Puppet, create an SSH key for the Jenkins slave, and then
Puppet will install the Jenkins slave.
