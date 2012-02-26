class sphinxsearch::params {
  case $::operatingsystem {
    ubuntu, debian: {
      $package = 'sphinxsearch'
      $service = 'searchd'
      $service_hasstatus = false
      $service_hasrestart = true
      $user = 'sphinx'
      $group = 'sphinx'
      $config_dir = '/etc/sphinx'
      $work_dir = '/var/lib/sphinx/index'
      $default_file = '/etc/default/searchd'
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
