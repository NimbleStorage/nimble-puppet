class nimblestorage::snapshot{
  create_resources(nimble_snapshot, hiera('snapshots', { }), { transport => hiera_hash('transport') })
}