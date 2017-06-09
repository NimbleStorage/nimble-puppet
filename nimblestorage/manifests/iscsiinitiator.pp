# manifests/iscsiinitiator
class nimblestorage::iscsiinitiator{
  require nimblestorage::chap
  create_resources(nimblestorage::iscsi, hiera('iscsiadm', { }))
}
