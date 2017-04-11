
class nimblestorage::multipath::load{
  multipath { 'multipath-config':
    ensure => hiera('multipath.config')
  }
}

