# manifests/host_init.pp
class nimblestorage::host_init {
  host_init{ 'prepare_facts':
    ensure    => present,
    transport => merge(hiera('credentials'), hiera('transport'))
  }

  package {'xfsprogs':
    ensure => present
  }

  case $::osfamily {
    'Debian': {
      file { '/usr/bin/sed':
        ensure => 'link',
        target => '/bin/sed',
      }
    }
    default: {
    }
  }

}
