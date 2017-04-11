class nimblestorage::initiator{
  require nimblestorage::initiator_group
  nimble_initiator { 'initiator':
    ensure          => hiera('initiator.ensure'),
    name            => hiera('initiator.groupname'),
    label           => hiera('initiator.label'),
    ip_address      => hiera('initiator.ip_address'),
    access_protocol => hiera("initiator.access_protocol"),
    transport       => hiera('transport')
  }
}