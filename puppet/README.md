# OpenStack External Test Platform Puppet Module

This directory contains some puppet modules and Bash scripts
that can be used to set up and maintain an external testing
platform that can be linked to the upstream OpenStack CI platform.

It installs Jenkins, Jenkins Job Builder (JJB), the Gerrit
Jenkins plugin, and a set of scripts that make running a variety
of OpenStack integration tests easy.

## Pre-requisites

1) You will need to register a Gerrit account with the upstream OpenStack
CI platform. You can read the instructions for doing
[that](http://ci.openstack.org/third_party.html#requesting-a-service-account)

2) You will need to have the `wget`, `openssl`, `ssl-cert` and `ca-certificates`
packages installed on your host or VM before running anything in this
repository.

3) You will want to create a Git repository containing the data files -- such as the
Gerrit username and private SSH key file for your testing account -- that are used
in setting up the test platform. The easiest way to get this started is to copy
(note: don't fork!) the [example data repo](http://github.com/jaypipes/os-ext-testing-data)
and adapt to your needs (just read the README)

## Usage

To install Puppet and all the infrastructure components involved
in an external OpenStack testing platform, simply run the `puppet/install.sh`
Bash script, as the root user:

```
wget https://raw.github.com/jaypipes/os-ext-testing/master/puppet/install.sh
sudo bash install.sh
```
