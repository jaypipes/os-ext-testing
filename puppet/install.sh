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
# Create an SSH key pair for Jenkins
if [[ ! -e $KEY_FILE_PATH ]]; then
  ssh-keygen -t rsa -b 1024 -N '' -f $KEY_FILE_PATH
fi
JENKINS_SSH_PRIVATE_KEY=`cat $KEY_FILE_PATH`
JENKINS_SSH_PUBLIC_KEY=`cat $KEY_FILE_PATH.pub`

SSL_ROOT_DIR=ssl
# Create a self-signed SSL certificate for use in Apache
if [[ ! -e $SSL_ROOT_DIR/new.ssl.csr ]]; then
  mkdir -p $SSL_ROOT_DIR
  cd $SSL_ROOT_DIR
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
  sudo openssl req -new -config ssl_req.conf -nodes > new.ssl.csr
  # Generate the certificate from the CSR
  sudo openssl rsa -in new.key.pem -out new.cert.key
  sudo openssl x509 -in new.ssl.csr -out new.cert.cert -req -signkey new.cert.key -days 3650
  sleep 1
fi
SSL_CERT_FILE=`sudo cat $SSL_ROOT_DIR/new.cert.cert`
SSL_KEY_FILE=`sudo cat $SSL_ROOT_DIR/new.cert.key`

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'os_ext_testing::jenkins': jenkins_ssh_public_key => '$JENKINS_SSH_PUBLIC_KEY', jenkins_ssh_private_key => '$JENKINS_SSH_PRIVATE_KEY', ssl_cert_file_contents = '$SSL_CERT_FILE', ssl_key_file_contents = '$SSL_KEY_FILE'}"
