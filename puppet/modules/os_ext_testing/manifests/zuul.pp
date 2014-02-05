class os_ext_testing::zuul(
  $vhost_name = $::fqdn,
  $gerrit_server = 'review.openstack.org',
  $gerrit_user = '',
  $zuul_ssh_private_key = '',
  $url_pattern = '',
  $zuul_url = '',
  $sysadmins = [],
  $statsd_host = '',
  $gearman_workers = [],
  $replication_targets = []
) {
  include os_ext_testing::base

  class { '::zuul':
    vhost_name           => $vhost_name,
    gerrit_server        => $gerrit_server,
    gerrit_user          => $gerrit_user,
    zuul_ssh_private_key => $zuul_ssh_private_key,
    url_pattern          => $url_pattern,
    zuul_url             => $zuul_url,
    push_change_refs     => false,
    job_name_in_report   => true,
    status_url           => 'http://status.$::fqdn/zuul/',
    statsd_host          => $statsd_host,
    replication_targets  => $replication_targets,
  }

  file { '/etc/zuul/layout.yaml':
    ensure => present,
    source => 'puppet:///modules/os_ext_testing/zuul/layout.yaml',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/openstack_functions.py':
    ensure => present,
    source => 'puppet:///modules/openstack_project/zuul/openstack_functions.py',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/logging.conf':
    ensure => present,
    source => 'puppet:///modules/openstack_project/zuul/logging.conf',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/gearman-logging.conf':
    ensure => present,
    source => 'puppet:///modules/openstack_project/zuul/gearman-logging.conf',
    notify => Exec['zuul-reload'],
  }

  class { '::recheckwatch':
    gerrit_server                => $gerrit_server,
    gerrit_user                  => $gerrit_user,
    recheckwatch_ssh_private_key => $zuul_ssh_private_key,
  }

  file { '/var/lib/recheckwatch/scoreboard.html':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/scoreboard.html',
    require => File['/var/lib/recheckwatch'],
  }
}
