# Class: nimblestorage
# ===========================
#
# Authors
# -------
#
# Author Name <ashish.koushik@msystehnologies.com>
#
# Copyright
# ---------
#
# Copyright 2017 Nimble Storage, Inc
#

class nimblestorage{
  hiera_include("${::hostname}")
}

class nimblestorage::host_init{
  host_init{ 'prepare_facts':
    ensure    => present,
    transport => merge(hiera('credentials'), hiera('transport'))
  }

  package{'xfsprogs': 
    ensure => present
  }

  case $::osfamily {
    'Debian': {
      file { '/usr/bin/sed':
        ensure => 'link',
        target => '/bin/sed',
      }
    }
  }

}

class nimblestorage::init{
  class { 'ntp': }
  class { 'nimblestorage::multipath::load': }
  class { 'nimblestorage::iscsi::service': }
  class { 'nimblestorage::host_init': }
}


define multipath (
  Boolean $ensure=true
  ) {
   $mod = "nimblestorage"
   if $ensure{
     package { $::nimblestorage::multipath::params::mp_packages: }
     file { "multipath.conf":
       require => Package[$::nimblestorage::multipath::params::mp_packages],
       backup  => "true",
       path    => "/etc/multipath.conf",
       content => template("${mod}/multipath.conf.erb"),
     }
     service { $::nimblestorage::multipath::params::mp_services:
       require   => File["multipath.conf"],
       subscribe => File["multipath.conf"],
       notify    => Exec["multipath"],
       ensure    => "running",
       enable    => "true",
     }
     exec { "multipath":
       path        => "/bin:/usr/bin:/usr/sbin:/sbin",
       command     => "multipath",
       logoutput   => "true",
       refreshonly => "true",
     }
   }else{
     service { $::nimblestorage::multipath::params::mp_services:
       ensure    => "stopped",
       enable    => "false",
     }
     package { $::nimblestorage::multipath::params::mp_packages:
      ensure => absent 
     }
     file { "multipath.conf":
       path    => "/etc/multipath.conf",
       ensure => absent
     }
   }
}