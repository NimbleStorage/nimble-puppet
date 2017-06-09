# manifests/multipath/params.pp
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
