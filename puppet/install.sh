#! /usr/bin/env bash

set -e

THIS_DIR=`pwd`

JENKINS_TMP_DIR=$THIS_DIR/tmp/jenkins
mkdir -p $JENKINS_TMP_DIR

JENKINS_KEY_FILE_PATH=$JENKINS_TMP_DIR/jenkins_key
APACHE_SSL_ROOT_DIR=$THIS_DIR/tmp/apache/ssl

DATA_REPO_INFO_FILE=$THIS_DIR/.data_repo_info
DATA_PATH=$THIS_DIR/data
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

if [[ ! -e $DATA_REPO_INFO_FILE ]]; then
    echo "Enter the URI for the location of your config data repository. Example: https://github.com/jaypipes/os-ext-testing-data"
    read data_repo_uri
    if [[ "$data_repo_uri" == "" ]]; then
        echo "Data repository is required to proceed. Exiting."
        exit 1
    fi
    git clone $data_repo_uri $DATA_PATH
    echo "$data_repo_uri" > $DATA_REPO_INFO_FILE
else
    data_repo_uri=`cat $DATA_REPO_INFO_FILE`
    echo "Using data repository: $data_repo_uri" 
fi

if [[ "$PULL_LATEST_DATA_REPO" == "1" ]]; then
    echo "Pulling latest data repo master."
    cd $DATA_PATH; git checkout master && git pull; cd $THIS_DIR;
fi

# Pulling in variables from data repository
. $DATA_PATH/vars.sh

if [[ -z $UPSTREAM_GERRIT_USER ]]; then
    echo "Expected to find UPSTREAM_GERRIT_USER in $DATA_PATH/vars.sh. Please correct. Exiting."
    exit 1
else
    echo "Using upstream Gerrit user: $UPSTREAM_GERRIT_USER"
fi

if [[ ! -e "$DATA_PATH/$UPSTREAM_GERRIT_SSH_KEY_PATH" ]]; then
    echo "Expected to find $UPSTREAM_GERRIT_SSH_KEY_PATH in $DATA_PATH. Please correct. Exiting."
    exit 1
fi
export UPSTREAM_GERRIT_SSH_PRIVATE_KEY_CONTENTS=`cat "$DATA_PATH/$UPSTREAM_GERRIT_SSH_KEY_PATH"`

# Create a self-signed SSL certificate for use in Apache
if [[ ! -e $APACHE_SSL_ROOT_DIR/new.ssl.csr ]]; then
    echo "Creating self-signed SSL certificate for Apache"
    mkdir -p $APACHE_SSL_ROOT_DIR
    cd $APACHE_SSL_ROOT_DIR
    echo '
[ req ]
default_bits            = 2048
default_keyfile         = new.key.pem
default_md              = default
prompt                  = no
distinguished_name      = distinguished_name

[ distinguished_name ]
countryName             = US
stateOrProvinceName     = CA
localityName            = Sunnyvale
organizationName        = OpenStack
organizationalUnitName  = OpenStack
commonName              = localhost
emailAddress            = openstack@openstack.org
' > ssl_req.conf
    # Create the certificate signing request
    openssl req -new -config ssl_req.conf -nodes > new.ssl.csr
    # Generate the certificate from the CSR
    openssl rsa -in new.key.pem -out new.cert.key
    openssl x509 -in new.ssl.csr -out new.cert.cert -req -signkey new.cert.key -days 3650
    cd $THIS_DIR
fi
APACHE_SSL_CERT_FILE=`cat $APACHE_SSL_ROOT_DIR/new.cert.cert`
APACHE_SSL_KEY_FILE=`cat $APACHE_SSL_ROOT_DIR/new.cert.key`

# Create an SSH key pair for Jenkins
if [[ ! -e $JENKINS_KEY_FILE_PATH ]]; then
  ssh-keygen -t rsa -b 1024 -N '' -f $JENKINS_KEY_FILE_PATH
  echo "Created SSH key pair for Jenkins at $JENKINS_KEY_FILE_PATH."
fi
JENKINS_SSH_PRIVATE_KEY=`sudo cat $JENKINS_KEY_FILE_PATH`
JENKINS_SSH_PUBLIC_KEY=`sudo cat $JENKINS_KEY_FILE_PATH.pub`

CLASS_ARGS="jenkins_ssh_public_key => '$JENKINS_SSH_PUBLIC_KEY', jenkins_ssh_private_key => '$JENKINS_SSH_PRIVATE_KEY', "
CLASS_ARGS="$CLASS_ARGS ssl_cert_file_contents => '$APACHE_SSL_CERT_FILE', ssl_key_file_contents => '$APACHE_SSL_KEY_FILE', "
CLASS_ARGS="$CLASS_ARGS upstream_gerrit_user => '$UPSTREAM_GERRIT_USER', "
CLASS_ARGS="$CLASS_ARGS upstream_gerrit_ssh_private_key => '$UPSTREAM_SSH_PRIVATE_KEY_CONTENTS', "

# Doing this here because ran into one problem after another trying
# to do this in Puppet... which won't let me execute Ruby code in
# a manifest and doesn't allow you to "merge" the contents of two
# directory sources in the file resource. :(
sudo mkdir -p /etc/jenkins_jobs/config
sudo cp -r $DATA_PATH/etc/jenkins_jobs/config/* /etc/jenkins_jobs/config/

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'os_ext_testing::ci': $CLASS_ARGS }"
