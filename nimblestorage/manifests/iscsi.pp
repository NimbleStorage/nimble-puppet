
class nimblestorage::iscsi::params {

    case $::osfamily {
        'RedHat': {
            $initiator_packages = 'iscsi-initiator-utils'
            $initiator_services = 'iscsid'
        }
      'Debian': {
        $initiator_packages = 'open-iscsi'
        $initiator_services = 'open-iscsi'
        $iscsid_startup = 'iscsid'
      }
        default: {
            fail ("${title}: operating system '${::operatingsystem}' is not supported")
        }
    }
}

class nimblestorage::iscsi::service (
        Boolean $enable=true,
        Variant[Boolean, Enum['running', 'stopped']] $ensure='running',
    ) inherits nimblestorage::iscsi::params {

    package { $::nimblestorage::iscsi::params::initiator_packages:
        ensure => installed,
        notify => Service[$::nimblestorage::iscsi::params::initiator_services],
    }

    service { $::nimblestorage::iscsi::params::initiator_services:
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => true,
        hasstatus  => true
    }

}

define nimblestorage::iscsi (
  String[1] $password,
  String[1] $user,
  Variant[Boolean, Enum['present', 'absent']] $ensure='present',
  Integer[0, 65535] $port=3260,
  String[1] $target=$title,
) {

  include '::nimblestorage::iscsi::service'

  file { '/etc/iscsi/iscsid.conf':
    ensure    => $ensure,
    owner     => 'root',
    group     => 'root',
    mode      => '0600',
    seluser   => 'system_u',
    selrole   => 'object_r',
    seltype   => 'etc_t',
    before    => Service[$::nimblestorage::iscsi::params::initiator_services],
    notify    => Service[$::nimblestorage::iscsi::params::initiator_services],
    subscribe => Package[$::nimblestorage::iscsi::params::initiator_packages],
    content   => template("nimblestorage/iscsid.conf.erb"),
    show_diff => false,
  }

  if $ensure == 'present'{

    $iface = split($::interfaces, ',')

    $iface.each |String $i| {
    if($i != 'lo'){
      exec { "/usr/sbin/iscsiadm -m iface --op new -I $i":
      unless => "/usr/sbin/iscsiadm -m iface --op show -I $i | grep 'iface.iscsi_ifacename'"
        }
      }
    }
  }


}
