include 'nimblestorage'
node 'node1', 'node2' {    # applies to ns1 and ns2 nodes

  package {"iscsi install":
    name   => "iscsi-initiator-utils",
    ensure => latest
  }

  nimble_volume { 'create-volume':
    ensure      => present,
    name        => hiera('volume.name'),
    description => hiera('volume.description'),
    size        => hiera('volume.size'),
    force       => true,
    perfpolicy  => hiera('volume.perfpolicy'),
    transport   => hiera('credentials')
  } 
  nimble_initiatorgroup { 'create-initiatorgroup':
    ensure          => present,
    name            => hiera('initiator.groupname'),
    description     => "This is an initiator group",
    access_protocol => "iscsi",
    target_subnets  => hiera('initiator.subnets'),
    transport       => hiera('credentials')
  } 
  nimble_initiator {'create-initiator':
    ensure          => present,
    name            => hiera('initiator.groupname'),
    label           => hiera('initiator.iqn'),
    iqn             => hiera('initiator.iqn'),
    ip_address      => hiera('initiator.ip_address'),
    access_protocol => "iscsi",
    transport       => hiera('credentials')
  }
}

node default {}       # applies to nodes that aren't explicitly defined
