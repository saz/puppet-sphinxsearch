define sphinx::instance(
  $ensure = 'present',
  $source = undef,
  $content = undef,
  $config_dir = $sphinxsearch::params::config_dir,
  $user = $sphinxsearch::params::user,
  $group = $sphinxsearch::params::group,
  $service = $sphinxsearch::params::service,
  $require = Class['sphinxsearch']
) {
  if $name == '0' {
    $instance_config_name = 'sphinx.conf'
  } else {
    $instance_config_name = "sphinx_${name}.conf"
  }

  file { "${config_dir}/${instance_config_name}":
    ensure  => $ensure,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    source  => $source,
    content => $content,
    require => $require,
    notify  => Service[$service],
  }
}
