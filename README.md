# Nimble Storage Puppet Module
This is the official puppet module to manage Nimble Storage resources. The module is installed from the [Nimble Storage Puppet Forge](https://forge.puppet.com/nimblestorage/nimblestorage) account.

These are the different types currently supported:
* host_init
* nimble_acr
* nimble_chap
* nimble_fs_mount
* nimble_initiator
* nimble_initiatorgroup
* nimble_protection_template
* nimble_snapshot
* nimble_volume
* nimble_volume_collection

Please see the documentation on [Puppet forge](https://forge.puppet.com/nimblestorage/nimblestorage/types) for details on types. More elaborate examples on how to use these types are outlined in the [configuration examples](#Configuration) below.

## Requirements
Examples will step through a single agent and master setup using a Hiera backend against a single Nimble Storage array. Those must meet the following requirements:

* RHEL/CentOS 7.x or Ubuntu 16.04
* Nimble Storage array with NimbleOS 3.3+
* Puppet 4.15+

## Installation
This section covers the basics on how to get started from scratch with Puppet and the Nimble Storage Puppet module.

### Assumptions
* All systems assumes having unfettered access between each other
* All hosts being time synchronized to a common time source
* All commands during the install procedure assumes root privileges

### Installing common pre-requisites
#### RHEL/CentOS
```
yum install -y rubygems
```

#### Ubuntu
```
apt-get install -y rubygems
```

### Installing a Puppet master
#### RHEL/CentOS 7.x
```
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install puppetserver git
systemctl start puppetserver
systemctl enable puppetserver
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

#### Ubuntu 16.04
```
apt-get install -y wget
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
dpkg -i puppetlabs-release-pc1-xenial.deb
apt-get update
apt-get install -y puppetserver
systemctl start puppetserver
systemctl enable puppetserver
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

### Installing a Puppet agent
#### RHEL/CentOS 7.x
```
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum install -y puppet-agent
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

#### Ubuntu 16.04
```
apt-get install -y wget
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
dpkg -i puppetlabs-release-pc1-xenial.deb
apt-get update
apt-get install -y puppet-agent
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

### Post installation tasks on Puppet master
Install the module from the official repo.
```
puppet module install nimblestorage-nimblestorage
```

The git repo contains configuration examples.

**Note:** For existing installations, please study the backend configuration examples and only add what is needed.
```
git clone 'https://github.com/NimbleStorage/nimble-puppet'
cd nimble-puppet
cp -f config/eyaml/eyaml-conf.yaml /etc/eyaml-conf.yaml
cp -f config/hiera/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml
cp -r config/hiera/hieradata /etc/puppetlabs/code/environments/production
cp config/site.pp /etc/puppetlabs/code/environments/production/manifests
puppet generate types
```

Installing eyaml & creating secret keys:
```
gem install hiera hiera-eyaml
/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml
export EYAML_CONFIG=/etc/eyaml-conf.yaml
eyaml createkeys
chown puppet /etc/puppetlabs/keys/*
```

Add Nimble Storage array credentials:
```
cd /etc/puppetlabs/code/environments/production/hieradata
eyaml edit secure.yaml
```

Contents of `/etc/puppetlabs/code/environments/production/hieradata/secure.yaml`:
```
credentials:
  username: DEC::PKCS7[<username>]!
  password: DEC::PKCS7[<password>]!
```
**Note:** Only replace `<username>` and `<password>`, don't replace the brackets!

Add the REST API transport:

Contents of `/etc/puppetlabs/code/environments/production/hieradata/common.yaml`:
```
---
transport:
  server: <Nimble Array Management IP Address>
  port: 5392
```

### Pairing the agent with the master
It's required to establish a trust between the agent and the master using a certificate signing process. Please follow the following steps to authorize an agent to use your master.

#### Agent
Submit a certificate signing request (CSR) to the certificate authority (CA) Puppet master:
```
puppet agent --server <Master FQDN or hostname> --waitforcert 60 -t --verbose
```

#### Master
Signing agent node certificate request (on Puppet master):
```
puppet cert list --all
puppet cert sign <Agent hostname>
```

#### Agent
Testing agent:
```
puppet agent -t -v --server <Master IP address or hostname>
```

If the agent doesn't return successfully (although nothing to do), please follow the troubleshooting steps in the next section. Complaints on not finding the agent in the backend is most likely related to not having any manifests configured for the agent.

Starting agent on boot requires that the agent can find the master, contents of `/etc/puppetlabs/puppet/puppet.conf`:
```
server = <Master FQDN or hostname>
```

Enable the Puppet agent at boot and make sure it starts at boot:
```
puppet resource service puppet ensure=running enable=true
```

## Troubleshooting
If the agent is croaking and complaining. Run the agent and master in verbose debug mode as it will most likely tell you why things are failing.

### Master
Shutdown the master and run it in the foreground:
```
systemctl stop puppetserver
puppet master --no-daemonize --verbose --debug
```

### Agent
Testing the agent:
```
puppet agent --test --verbose --debug
```

## Configuration
The follwing examples may be used to build custom manifests to manage Nimble Storage resources and mount points residing on Linux hosts. These files can be found in the [config/hiera/hieradata/nodes](config/hiera/hieradata/nodes) directory. They need to be renamed to the agent node fully qualified domain name (fqdn) to be picked up by the agent, i.e `myhost.example.com.yaml`.

### Provision resources (resource_provision.yaml)
Provisions everyhing needed to hand off a mounted filesystem on the agent with a custom volume collection and protection template.
```
---
example-agent:
  - nimblestorage::init
  - nimblestorage::chap
  - nimblestorage::initiator_group
  - nimblestorage::initiator
  - nimblestorage::protection_template
  - nimblestorage::volume_collection
  - nimblestorage::volume
  - nimblestorage::acr
  - nimblestorage::fs_mount

iscsiadm:
  config: 
    ensure: present
    port: 3260
    target: 192.168.59.64
    user: "%{alias('chap.username')}"
    password: "%{alias('chap.password')}"

chap:
  ensure: present
  username: chapuser
  password: password_25-24
  systemIdentifier: example-chap-account

initiator:
  ensure: present
  groupname: "%{::hostname}"
  label: "%{::hostname}:sw-iscsi"
  ip_address: "*"
  access_protocol: "iscsi"
  description: "This is an example initiator"
  subnets:
    - Management

multipath: 
  config: true

protection_template:
  example-prot-tmpl:
    ensure: present
    schedule_list:
      - name: minutes
        period_unit: minutes
        period: 5
        num_retain: 13
      - name: hours
        period_unit: hours
        period: 1
        num_retain: 25
      - name: days
        period_unit: days
        period: 1
        num_retain: 31

volume_collection:
  example-vol-coll:
    ensure: present
    prottmpl_name: example-prot-tmpl

volumes:
  example-vol:
    ensure: present
    name: example-vol
    size: 1000m
    description: Example Volume
    perfpolicy: default
    force: true
    online: true
    vol_coll: example-vol-coll

access_control:
  example-vol:
    ensure: present
    volume_name: example-vol
    chap_user: "%{alias('chap.username')}"
    initiator_group : "%{::hostname}"
    apply_to: both

mount_points:
  example-vol:
    ensure: present
    target_vol: example-vol
    mount_point: /mnt/example-vol
    fs: xfs
    label: example-vol
```

### Resize volume (volume_resize.yaml)
Resizes the volume and filesystem created in the previous example.
```
---
example-agent:
  - nimblestorage::init
  - nimblestorage::volume
  - nimblestorage::fs_mount

multipath: 
  config: true

iscsiadm:
  config: 
    ensure: present
    port: 3260
    target: 192.168.59.64
    user: "%{alias('chap.username')}"
    password: "%{alias('chap.password')}"

chap:
  ensure: present
  username: chapuser
  password: password_25-24
  systemIdentifier: example-chap-account

volumes:
  example-vol:
    ensure: present
    name: example-vol
    size: 2000m

mount_points:
  example-vol:
    ensure: present
    target_vol: example-vol
    mount_point: /mnt/example-vol
    fs: xfs
    label: example-vol
```

### Throttle volume (volume_throttle.yaml)
Throttles the allowed bandwidth to the volume (requires Nimble OS 4.0+). This is to illustrate a volume update.
```
---
example-agent:
  - nimblestorage::init
  - nimblestorage::volume

multipath: 
  config: true

iscsiadm:
  config: 
    ensure: present
    port: 3260
    target: 192.168.59.64
    user: "%{alias('chap.username')}"
    password: "%{alias('chap.password')}"

chap:
  ensure: present
  username: chapuser
  password: password_25-24
  systemIdentifier: example-chap-account

volumes:
  example-vol:
    ensure: present
    limit_mbps: 200
```

### Snapshot volume (volume_snapshot.yaml)
Creates a snapshot on the created volume.
```
---
example-agent:
  - nimblestorage::init
  - nimblestorage::volume
  - nimblestorage::snapshot

multipath: 
  config: true

iscsiadm:
  config: 
    ensure: present
    port: 3260
    target: 192.168.59.64
    user: "%{alias('chap.username')}"
    password: "%{alias('chap.password')}"

chap:
  ensure: present
  username: chapuser
  password: password_25-24
  systemIdentifier: example-chap-account

volumes:
  example-vol:
    ensure: present
    name: example-vol

snapshots:
  example-snapshot:
    ensure: present
    vol_name: "%{alias('volumes.example-vol.name')}"
```

### Clone volume (volume_clone.yaml)
Creates a snapshot, clones it into a volume and mounts the filesystem on the agent.
```
WIP
```

### Destroy clone (volume_destroy.yaml)
Umounts the filesystem, destroys the clone and snapshot.
```
WIP
```

### Decommission resources (resource_decommision.yaml)
Unmounts the filesystem from the agent, destroys the volume and all the other resources created in the provisioning phase.
```
---
example-agent:
  - nimblestorage::cleanup
  - nimblestorage::chap
  - nimblestorage::initiator_group
  - nimblestorage::initiator
  - nimblestorage::protection_template
  - nimblestorage::volume_collection
  - nimblestorage::volume
  - nimblestorage::acr
  - nimblestorage::fs_mount

mount_points:
  example-vol:
    ensure: absent
    target_vol: example-vol
    mount_point: /mnt/example-vol
    fs: xfs
    label: example-vol

access_control:
  example-vol:
    ensure: absent
    volume_name: example-vol
    chap_user: "%{alias('chap.username')}"
    initiator_group : "%{::hostname}"
    apply_to: both

iscsiadm:
  config: 
    ensure: absent
    port: 3260
    target: 192.168.59.64
    user: "%{alias('chap.username')}"
    password: "%{alias('chap.password')}"

chap:
  ensure: absent
  username: chapuser
  password: password_25-24
  systemIdentifier: example-chap-account

initiator:
  ensure: absent
  groupname: "%{::hostname}"
  label: "%{::hostname}:sw-iscsi"
  ip_address: "*"
  access_protocol: "iscsi"
  description: "This is an example initiator group"
  subnets:
    - Management

multipath: 
  config: true

protection_template:
  example-prot-tmpl:
    ensure: absent
    schedule_list:
      - name: minutes
        period_unit: minutes
        period: 5
        num_retain: 13
      - name: hours
        period_unit: hours
        period: 1
        num_retain: 25
      - name: days
        period_unit: days
        period: 1
        num_retain: 31

volume_collection:
  example-vol-coll:
    ensure: absent
    prottmpl_name: example-prot-tmpl

volumes:
  example-vol:
    ensure: absent
    name: example-vol
    size: 1000m
    description: Example Volume
    perfpolicy: default
    force: true
    online: true
    vol_coll: example-vol-coll
```

## License
Apache 2.0, please see [LICENSE](LICENSE)

## Contributing
Please feel free to submit pull requests. Please include updates to the documentation.

## Issues
Use Git issues to report and track all activities, also attach (mandatory) trace log for the same.

## Changelog
### 2.0.3
* Remved NTP dependency

### 2.0.2
* Updated documentation and supported operating systems.
* Added example manifests for common operations.

### 2.0.0
* Added support for Volume collection, snapshot, protection template & protection schedule.
* Added Ubuntu compatibilty.

### 0.1.0
* Added support for CHAP user, initiator, initiator group, acess control record & volume.
