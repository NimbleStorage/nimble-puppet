
class nimblestorage::multipath::load inherits nimblestorage::multipath::params{
  multipath { 'multipath-config':
    ensure => hiera('multipath.config')
  }
}


class nimblestorage::multipath::params {

  case $::osfamily {
    'RedHat': {
      $mp_packages = 'device-mapper-multipath'
      $mp_services = 'multipathd'
    }
    'Debian': {
      $mp_packages = 'multipath-tools'
      $mp_services = 'multipathd'
      file { '/usr/sbin/multipath':
        ensure => 'link',
        target => '/sbin/multipath',
      }
    }
    default: {
      fail ("${title}: operating system '${::operatingsystem}' is not supported")
    }
  }
}