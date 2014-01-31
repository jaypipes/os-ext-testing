# Simple base class, modeled after the base.pp manifest in
# openstack-infra/config/modules/openstack_project/manifests/base.pp

class os_ext_testing::base(
  $certname = $::fqdn
) {
  if ($::osfamily == 'Debian') {
    include apt
  }

  # Install some base packages
  case $::osfamily {
    'RedHat': {
      $packages = ['puppet', 'wget']
      $update_pkg_list_cmd = ''
    }
    'Debian': {
      $packages = ['puppet', 'wget']
      $update_pkg_list_cmd = 'apt-get update >/dev/null 2>&1;'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'os-ext-testing' module only supports osfamily Debian or RedHat (slaves only).")
    }
  } 
  include sudoers

  if ($::lsbdistcodename == 'oneiric') {
    apt::ppa { 'ppa:git-core/ppa': }
    package { 'git':
      ensure  => latest,
      require => Apt::Ppa['ppa:git-core/ppa'],
    }
  } else {
    package { 'git':
      ensure => present,
    }
  }

  if ($::operatingsystem == 'Fedora') {

    package { 'hiera':
      ensure   => latest,
      provider => 'gem',
    }

    exec { 'symlink hiera modules' :
      command     => 'ln -s /usr/local/share/gems/gems/hiera-puppet-* /etc/puppet/modules/',
      path        => '/bin:/usr/bin',
      subscribe   => Package['hiera'],
      refreshonly => true,
    }

  }

  package { $packages:
    ensure => present
  }

  include pip
  package { 'virtualenv':
    ensure   => '1.10.1',
    provider => pip,
    require  => Class['pip'],
  }

  # Use upstream puppet and pin to version 2.7.*
  if ($::osfamily == 'Debian') {
    apt::source { 'puppetlabs':
      location   => 'http://apt.puppetlabs.com',
      repos      => 'main',
      key        => '4BD6EC30',
      key_server => 'pgp.mit.edu',
    }

    file { '/etc/apt/preferences.d/00-puppet.pref':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/00-puppet.pref',
      replace => true,
    }

  }

  file { '/etc/puppet/puppet.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('openstack_project/puppet.conf.erb'),
    replace => true,
  }

}
