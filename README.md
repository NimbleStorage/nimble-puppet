# Nimble Array Puppet Module

This module allows to interact with different objects in Nimble Storage Arrays like Volumes, Snapshot etc.

## Usage

Define your environment in the yaml file where hiera can find them. For example in /etc/puppetlabs/code/environments/production/hieradata/nodes/primary.yaml

```
credentials:
  server: array.vlab.nimblestorage.com
  username: admin
  password: admin
  port: 5392
```

Then in your foo.pp file create a resource.
```
include ::nimblestorage
nimblearray { 'create a volume':
  type        => 'volume',
  ensure      => present,
  name        => "puppet-test",
  description => 'This is a volume',
  size        => 100,
  force       => true,
  perfpolicy  => "VMware ESX",
  agent_type  => "vvol",
  transport   => hiera('credentials')
}
```

For creating a snapshot

```
nimblearray { 'create a snapshot':
  type        => 'snapshot',
  ensure      => present,
  name        => "puppet-test-snap",
  vol_name    => 'puppet-test',
  online      => true,
  writable    => true,
  description => 'Snap of puppet-test',
  transport   => hiera('credentials')
}
```

Now apply it like
```$ puppet apply --certname=primary foo.pp ```
