# manifests/initiator_group.pp
class nimblestorage::initiator_group{
  nimble_initiatorgroup { 'initiator-group':
    ensure          => hiera('initiator.ensure'),
    name            => hiera('initiator.groupname'),
    description     => hiera('initiator.description'),
    access_protocol => hiera('initiator.access_protocol'),
    target_subnets  => hiera('initiator.subnets'),
    transport       => hiera('transport')
  }
}
