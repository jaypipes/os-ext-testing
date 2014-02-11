# OpenStack External Test Platform Deployer

This repository contains documentation and modules in a variety
of configuration management systems that demonstrates setting up
a real-world external testing platform that links with the upstream
OpenStack CI platform.

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
in setting up the test platform.

## Usage

Pick whichever configuration management tool you prefer and run the `install.sh`
script in the directory of this repository in a VM or host that you wish to
set up the external testing platform on. Use `wget` to retrieve the latest install
script for your configuration management flavor, like this example that fetches
the puppet stuffs:

```
wget https://raw.github.com/jaypipes/os-ext-testing/master/puppet/install.sh
bash install.sh
```
