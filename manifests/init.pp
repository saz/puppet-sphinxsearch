class sphinxsearch(
  $ensure = 'present',
  $instances = [0],
  $config_source = undef,
  $config_dir = $sphinxsearch::params::config_dir,
  $default_file = $sphinxsearch::params::default_file,
  $work_dir = $sphinxsearch::params::work_dir,
  $work_dir_recurse = false,
  $work_dir_mode = '0640',
  $user = $sphinxsearch::params::user,
  $group = $sphinxsearch::params::group,
  $autoupgrade = false,
  $service_ensure = 'running',
  $service_enable = true,
  $service_hasstatus = $sphinxsearch::params::service_hasstatus,
  $service_hasrestart = $sphinxsearch::params::service_hasrestart,
  $monitor = false,
  $monitor_tool = false,
  $firewall = false,
  $firewall_tool = false,
  $firewall_src = false,
  $firewall_dst = false,
  $service = $sphinxsearch::params::service,
  $package = $sphinxsearch::params::package
) inherits sphinxsearch::params {

  validate_bool(
    $autoupgrade,
    $service_enable,
    $service_hasstatus,
    $service_hasrestart,
    $monitor,
    $firewall
  )

  case $ensure {
    present: {
      if $autoupgrade == true {
        $package_ensure = 'latest'
      } else {
        $package_ensure = 'present'
      }

      case $service_ensure {
        running, stopped: {
          $service_ensure_real = $service_ensure
        }
        default: {
          fail("service_ensure parameter must be running or stopped, not ${service_ensure}")
        }
      }

      $file_ensure = 'file'
      $dir_ensure = 'directory'
    }
    absent: {
      $package_ensure = 'absent'
      $service_ensure_real = 'stopped'
      $file_ensure = 'absent'
      $dir_ensure = 'absent'
    }
    default: {
      fail("ensure parameter must be present or absent, not ${ensure}")
    }
  }

  package { $package:
    ensure => $package_ensure,
  }

  file { $default_file:
    ensure  => $file_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('sphinxsearch/default-searchd.erb'),
    require => Package[$package],
    notify  => Service[$service],
  }

  file { $config_dir:
    ensure  => $dir_ensure,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    recurse => true,
    purge   => true,
    force   => true,
    require => Package[$package],
    notify  => Service[$service],
  }

  file { $work_dir:
    ensure  => $dir_ensure,
    owner   => $user,
    group   => $group,
    mode    => $work_dir_mode,
    force   => true,
    recurse => $work_dir_recurse,
    require => Package[$package],
    notify  => Service[$service],
  }

  sphinxsearch::instance { $instances:
    ensure     => $file_ensure,
    source     => $config_source,
    config_dir => $config_dir,
    user       => $user,
    group      => $group,
    require    => File[$work_dir],
    notify     => Service[$service],
  }

  service { $service:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasstatus  => $service_hasstatus,
    hasrestart => $service_hasrestart,
    require    => Package[$package],
  }
}
