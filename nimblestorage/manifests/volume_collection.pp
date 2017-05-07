class nimblestorage::volume_collection{
  create_resources(nimble_volume_collection, hiera('volume_collection', { }), {
    transport => hiera_hash('transport')
  })
}