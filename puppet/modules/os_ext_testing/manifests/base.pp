# Simple base class, modeled after the base.pp manifest in
# openstack-infra/config/modules/openstack_project/manifests/base.pp

class os_ext_testing::base(
  $certname = $::fqdn,
) {
  if ($::osfamily == 'Debian') {
    include apt
  }
  include ssh
  include snmpd
  include ntp

  # Install some base packages
  case $::osfamily {
    'RedHat': {
      $packages = ['puppet', 'wget', 'strace', 'tcpdump']
      $update_pkg_list_cmd = ''
    }
    'Debian': {
      $packages = ['puppet', 'wget', 'strace', 'tcpdump']
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

  if $::osfamily == 'Debian' {
    # Custom rsyslog config to disable /dev/xconsole noise on Debuntu servers
    file { '/etc/rsyslog.d/50-default.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  =>
        'puppet:///modules/openstack_project/rsyslog.d_50-default.conf',
      replace => true,
      notify  => Service['rsyslog'],
    }

    # Ubuntu installs their whoopsie package by default, but it eats through
    # memory and we don't need it on servers
    package { 'whoopsie':
      ensure => absent,
    }
  }

  # Increase syslog message size in order to capture
  # python tracebacks with syslog.
  file { '/etc/rsyslog.d/99-maxsize.conf':
    ensure  => present,
    # Note MaxMessageSize is not a puppet variable.
    content => '$MaxMessageSize 6k',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service['rsyslog'],
  }

  service { 'rsyslog':
    ensure     => running,
    enable     => true,
    hasrestart => true,
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

  file { '/opt/nodepool-scripts':
    ensure => directory,
  }

  # Although we don't use Nodepool itself, we DO make use of some
  # of the scripts that are housed in the nodepool openstack-infra/config
  # files directory.
  file { '/opt/nodepool-scripts':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    require => File['/opt/nodepool-scripts'],
    source  => 'puppet:///modules/openstack_project/nodepool/scripts',
  }

}
