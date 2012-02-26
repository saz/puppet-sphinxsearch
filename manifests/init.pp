# Class: sphinxsearch
#
# This module manages sphinxsearch
#
# Parameters:
#   [*ensure*]
#     Ensure if present or absent.
#     Default: present
#
#   [*instances*]
#     List of instances to use
#     Default: [0]
#
#   [*config_source*]
#     Directory to fetch config files from.
#     NOTE: Config files must be named like 'sphinx_<instance_id>.conf' or
#           'sphinx.conf' if there is only instance 0.
#     Default: undef
#
#   [*config_dir*]
#     Directory where config files resist.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*default_file*]
#     Full path and name of default file.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*work_dir*]
#     Name of the directory for index files.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*work_dir_recurse*]
#     Manage work_dir recursive (change owner/group, modes)
#     Default: false
#
#   [*work_dir_mode*]
#     Mode for files and directories in work_dir.
#     Default: 0640
#
#   [*user*]
#     Name of the user running searchd.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*group*]
#     Name of the group running searchd.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*autoupgrade*]
#     Upgrade package automatically, if there is a newer version.
#     Default: false
#
#   [*package*]
#     Name of the package.
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*service*]
#     Name of NTP service
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*service_ensure*]
#     Ensure if service is running or stopped
#     Default: running
#
#   [*service_enable*]
#     Start service at boot
#     Default: true
#
#   [*service_hasstatus*]
#     Service has status command
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
#   [*service_hasrestart*]
#     Service has restart command
#     Only set this, if your platform is not supported or you know, what you're doing.
#     Default: auto-set, platform specific
#
# Actions:
#   Installs sphinxsearch and configures one or more instances.
#
# Requires:
#   puppetlabs/stdlib
#
# Sample Usage:
#   class { 'sphinxsearch': }
#
#
# [Remember: No empty lines between comments and class definition]
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
  $package = $sphinxsearch::params::package
  $service = $sphinxsearch::params::service,
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
