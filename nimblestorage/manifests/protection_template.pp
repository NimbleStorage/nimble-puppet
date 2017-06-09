# manifests/protection_templates
class nimblestorage::protection_template{
  create_resources(nimble_protection_template, hiera('protection_template', { }), {
    transport => hiera_hash('transport')
  })
}
