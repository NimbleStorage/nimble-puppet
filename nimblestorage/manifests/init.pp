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

# nimblestorage
class nimblestorage {
  hiera_include($::hostname)
}

# nimblestorage::init
class nimblestorage::init {
  class { 'nimblestorage::multipath::load': }
  class { 'nimblestorage::iscsi::service': }
  class { 'nimblestorage::host_init': }
}

# multipath
define multipath (
  Boolean $ensure=true
  )
  {
    $mod = 'nimblestorage'
    if $ensure {
      package { $::nimblestorage::multipath::params::mp_packages: }
      file { 'multipath.conf':
        require => Package[$::nimblestorage::multipath::params::mp_packages],
        backup  => true,
        path    => '/etc/multipath.conf',
        content => template("${mod}/multipath.conf.erb")
      }
      service { $::nimblestorage::multipath::params::mp_services:
        ensure    => running,
        require   => File['multipath.conf'],
        subscribe => File['multipath.conf'],
        notify    => Exec['multipath'],
        enable    => true
      }
      exec { 'multipath':
        path        => '/bin:/usr/bin:/usr/sbin:/sbin',
        command     => 'multipath',
        logoutput   => true,
        refreshonly => true
      }
    } else {
      service { $::nimblestorage::multipath::params::mp_services:
        ensure => stopped,
        enable => false
      }
      package { $::nimblestorage::multipath::params::mp_packages:
        ensure => absent
      }
      file { 'multipath.conf':
        ensure => absent,
        path   => '/etc/multipath.conf'
      }
    }
  }
