class pxeproxy {
  include apache::params
  include apache::ssl
  include ::passenger

  # Params
  $dns_name = "autoinstall.mydomain.com"
  $vhost    = "/var/www/$dns_name"
  $app_root = "$vhost/app"

  # Packages
  package { ["libsinatra-ruby","librestclient-ruby","libjson-ruby"]: ensure => installed }

  # Holding dirs
  $dirs = [
           "$vhost",
           "$vhost/logs",
           "$app_root",
           "$app_root/log",
           "$app_root/tmp",
          ]

  file { $dirs:
    ensure => directory,
    mode   => 0755,
    owner  => $apache::params::user,
    group  => $apache::params::group,
  }

  # Install application
  file { 
    "$app_root/pxeproxy.rb":
      mode    => 0755,
      owner   => $apache::params::user,
      group   => $apache::params::group,
      notify  => Exec['restart_pxeproxy'],
      content => template("pxeproxy/pxeproxy-app.erb");
    "$app_root/config.ru":
      mode    => 0644,
      owner   => $apache::params::user,
      group   => $apache::params::group,
      notify  => Exec['restart_pxeproxy'],
      content => template("pxeproxy/config.ru.erb");
    "$app_root/public":
      mode    => 0644,
      owner   => $apache::params::user,
      group   => $apache::params::group,
      source  => "puppet:///modules/pxeproxy/staticfiles",
      recurse => true;
  }
  
  file {'pxeproxy_vhost':
    path    => "${apache::params::configdir}/pxeproxy.conf",
    content => template('pxeproxy/pxeproxy-vhost.conf.erb'),
    mode    => '0644',
    notify  => Exec['reload-apache'],
  }

  file { 'pxeproxy_logrotate':
    path    => "/etc/logrotate.d/pxeproxy",
    content => template('pxeproxy/pxeproxy-logrotate.erb'),
  }

  exec {'restart_pxeproxy':
    command     => "/bin/touch $app_root/tmp/restart.txt",
    refreshonly => true,
    cwd         => "$app_root",
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    require     => [Class["::passenger"],File["$app_root/tmp"],Package["libsinatra-ruby"]],
  }

}
