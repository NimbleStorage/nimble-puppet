# manifests/iscsi/params.pp
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
