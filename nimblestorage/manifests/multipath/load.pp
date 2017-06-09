# manifests/multipath/load.pp
class nimblestorage::multipath::load inherits nimblestorage::multipath::params{
  multipath { 'multipath-config':
    ensure => hiera('multipath.config')
  }
}
