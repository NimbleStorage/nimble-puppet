class nimblestorage::chap{
  nimble_chap { 'chap-account':
    ensure           => hiera('chap.ensure'),
    name             => hiera('chap.systemIdentifier'),
    username         => hiera('chap.username'),
    transport        => hiera('transport'),
    password         => hiera('chap.password')
  }
}