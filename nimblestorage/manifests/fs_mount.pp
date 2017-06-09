# manifests/fs_mount.pp
class nimblestorage::fs_mount{
  require nimblestorage::iscsiinitiator

  create_resources(nimble_fs_mount, hiera('mount_points', { }),  {
    transport => hiera_hash('transport'),
    mp        => hiera('multipath.config'),
    config    => hiera('iscsiadm.config')
  })
}
