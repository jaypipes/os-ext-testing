# OpenStack External Test Platform Puppet Module

This directory contains some puppet modules and Bash scripts
that can be used to set up and maintain an external testing
platform that can be linked to the upstream OpenStack CI platform.

It installs Jenkins, Jenkins Job Builder (JJB), the Gerrit
Jenkins plugin, and a set of scripts that make running a variety
of OpenStack integration tests easy.

## Usage

To install Puppet and all the infrastructure components involved
in an external OpenStack testing platform, simply run the `puppet/install.sh`
Bash script, as the root user:

```
wget https://raw.github.com/jaypipes/os-ext-testing/master/puppet/install.sh
sudo bash install.sh
```
