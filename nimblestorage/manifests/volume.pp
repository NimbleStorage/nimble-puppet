class nimblestorage::volume{
  require nimblestorage::chap
  create_resources(nimble_volume, hiera('volumes', { }), {
    transport => hiera_hash('transport'),
    config => hiera('iscsiadm.config'),
    mp => hiera('multipath.config'),
  })
}