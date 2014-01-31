#! /usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -e

KEY_FILE_PATH=jenkins_key
PUPPET_MODULE_PATH="--modulepath=/root/os-ext-testing/puppet/modules:/root/config/modules:/etc/puppet/modules"

# Install Puppet and the OpenStack Infra Config source tree
if [[ ! -e install_puppet.sh ]]; then
  wget https://git.openstack.org/cgit/openstack-infra/config/plain/install_puppet.sh
  sudo bash -xe install_puppet.sh
  sudo git clone https://review.openstack.org/p/openstack-infra/config.git \
    /root/config
  sudo /bin/bash /root/config/install_modules.sh
fi
if [[ ! -d /root/os-ext-testing ]]; then
  sudo git clone https://github.com/jaypipes/os-ext-testing /root/os-ext-testing
fi
# Create an SSH key pair for the Jenkins
if [[ ! -e $KEY_FILE_PATH ]]; then
  ssh-keygen -t rsa -b 1024 -N '' -f $KEY_FILE_PATH
fi
JENKINS_SSH_PRIVATE_KEY=`cat $KEY_FILE_PATH`
JENKINS_SSH_PUBLIC_KEY=`cat $KEY_FILE_PATH.pub`
sudo puppet apply $PUPPET_MODULE_PATH -e "class {'os_ext_testing::base'}"
sudo puppet apply $PUPPET_MODULE_PATH -e "class {'jenkins::master': jenkins_ssh_public_key => '$JENKINS_SSH_PUBLIC_KEY', jenkins_ssh_private_key => '$JENKINS_SSH_PRIVATE_KEY'}"
