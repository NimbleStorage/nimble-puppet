# manifests/iscsi/service.pp
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
