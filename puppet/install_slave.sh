#! /usr/bin/env bash

set -e

THIS_DIR=`pwd`

JENKINS_TMP_DIR=$THIS_DIR/tmp/jenkins
mkdir -p $JENKINS_TMP_DIR

JENKINS_KEY_FILE_PATH=$JENKINS_TMP_DIR/jenkins_key

OSEXT_PATH=$THIS_DIR/os-ext-testing
PUPPET_MODULE_PATH="--modulepath=$OSEXT_PATH/puppet/modules:/root/config/modules:/etc/puppet/modules"

# Install Puppet and the OpenStack Infra Config source tree
if [[ ! -e install_puppet.sh ]]; then
  wget https://git.openstack.org/cgit/openstack-infra/config/plain/install_puppet.sh
  sudo bash -xe install_puppet.sh
  sudo git clone https://review.openstack.org/p/openstack-infra/config.git \
    /root/config
  sudo /bin/bash /root/config/install_modules.sh
fi

# Clone or pull the the os-ext-testing repository
if [[ ! -d $OSEXT_PATH ]]; then
    echo "Cloning os-ext-testing repo..."
    git clone https://github.com/jaypipes/os-ext-testing $OSEXT_PATH
fi

if [[ "$PULL_LATEST_OSEXT_REPO" == "1" ]]; then
    echo "Pulling latest os-ext-testing repo master..."
    cd $OSEXT_PATH; git checkout master && sudo git pull; cd $THIS_DIR
fi

# Create an SSH key pair for Jenkins
if [[ ! -e $JENKINS_KEY_FILE_PATH ]]; then
  ssh-keygen -t rsa -b 1024 -N '' -f $JENKINS_KEY_FILE_PATH
  echo "Created SSH key pair for Jenkins at $JENKINS_KEY_FILE_PATH."
fi
JENKINS_SSH_PRIVATE_KEY=`sudo cat $JENKINS_KEY_FILE_PATH`
JENKINS_SSH_PUBLIC_KEY=`sudo cat $JENKINS_KEY_FILE_PATH.pub`

CLASS_ARGS="ssh_key => '$JENKINS_SSH_PRIVATE_KEY', "

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'os_ext_testing::devstack_slave': $CLASS_ARGS }"
