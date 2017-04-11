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
}

class nimblestorage::init{
  class { 'ntp': }
  class { 'nimblestorage::iscsi::service': }
  class { 'nimblestorage::host_init': }
}


define multipath (
  Boolean $ensure=true
  ) {
   $mod = "nimblestorage"
   if $ensure{
     package { "device-mapper-multipath": }
     file { "multipath.conf":
       require => Package["device-mapper-multipath"],
       backup  => "true",
       path    => "/etc/multipath.conf",
       content => template("${mod}/multipath.conf.erb"),
     }
     service { "multipathd":
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
     service { "multipathd":
       ensure    => "stopped",
       enable    => "false",
     }
     package { "device-mapper-multipath": 
      ensure => absent 
     }
     file { "multipath.conf":
       path    => "/etc/multipath.conf",
       ensure => absent
     }
   }
}