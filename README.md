# Nimble Array Puppet Module

This wrapper module allows to interact with different objects in Nimble Storage Arrays like Volumes, Snapshot etc.

## Usage
### Requirements
- fqdn, ip address and credentials of below machines
	- Puppet master
	- Puppet agent
	- Nimble array (Management portal)

### How to steps
---

#### Installing Puppet

#### Pre-install tasks

- Puppet usually uses an agent/master (client/server) architecture, but it can also run in a self-contained architecture.
- Network configuration
	- **Firewalls** : The Puppet master server must allow incoming connections on port 8140.
	> on Apt-based systems
	 
	```
	ufw allow 8140
	```
	> on Yum-based systems
	
	```
	iptables -F
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8140 -j ACCEPT
	```
- **Timekeeping** on your Puppet master server & agent.	Choose time zone accordingly.
> on Yum-based systems

```
timedatectl list-timezones
timedatectl set-timezone <timeZone>
yum -y install ntp net-tools  
ntpdate pool.ntp.org
systemctl restart ntpd
systemctl enable ntpd
```

> on Apt-based systems
```
timedatectl list-timezones
timedatectl set-timezone <timeZone>
apt-get -y install ntp ntpdate
ntpdate -u 0.ubuntu.pool.ntp.org
service ntp restart
```


- Installing Rubygems & git
> on Yum-based systems
```
yum -y install rubygems git
```

> on Apt-based systems
```
apt-get install rubygems git
```
---

#### Installing Puppet Master

> on Yum-based systems

```
# rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-<COLLECTION>-<OS ABBREVIATION>-<OS VERSION>.noarch.rpm

rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install puppetserver
systemctl start puppetserver
systemctl enable puppetserver
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

> on Apt-based systems

```
# wget https://apt.puppetlabs.com/puppetlabs-release-<CODE NAME>.deb

wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
dpkg -i puppetlabs-release-pc1-xenial.deb
apt-get update
apt-get install -y puppetserver
systemctl start puppetserver
systemctl enable puppetserver
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

---

#### Installing Puppet agent

> on Yum-based systems

```
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install puppet-agent
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

> on Apt-based systems

```
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
dpkg -i puppetlabs-release-pc1-xenial.deb
apt-get update
apt-get install puppet-agent
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
```

---

#### Post installation tasks on master

* installing puppet module for NimbleStorage
```
puppet module install ashishnkmsys-nimblestorage
```

* Installing **eyaml** & creating secret keys

```
gem install hiera hiera-eyaml
/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml

export EYAML_CONFIG=/etc/eyaml-conf.yaml
eyaml createkeys
mv keys /etc/puppetlabs
```

* cloning git repository & putting other files in place
```
git clone 'https://github.com/ashishnk/nimble-puppet'
cd nimble-puppet
git checkout msys

cp config/eyaml/eyaml-conf.yaml /etc/eyaml-conf.yaml
cp config/hiera/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml
cp -r config/hiera/hieradata /etc/puppetlabs/code/environments/production
cp config/site.pp /etc/puppetlabs/code/environments/production/manifests
chmod 644 /etc/puppetlabs/keys/*
puppet generate types
```

* (Optional) Configuring array credentials for security
```
cd /etc/puppetlabs/code/environments/production/hieradata
eyaml edit secure.yaml
```

```
credentials:
  username: DEC::PKCS7[<mgmt-array-username>]!
  password: DEC::PKCS7[<mgmt-array-password>]!
```

* Edit `common.yaml`
```
cd /etc/puppetlabs/code/environments/production/hieradata/
```
```
transport:
  server: <mgmt array-ip address>
  port: <mgmt array-REST API port>
```
---
* **Creating node specific config script**
```
cd /etc/puppetlabs/code/environments/production/hieradata/nodes/
```

* Edit `<fqdn-agent-machine>.yaml` template to a node specific script as below.


change the section accordingly in template.

> `agent`
	
```
<hostname>:
    - nimblestorage::create
#    - nimblestorage::cleanup
```

_Note_ :- Above configuration covers below resource configs, add or remove classes according to requirements.(optional) 

```
<hostname>:
    - nimblestorage::init
    - nimblestorage::chap
    - nimblestorage::initiator_group
    - nimblestorage::initiator
    - nimblestorage::protection_template
    - nimblestorage::volume_collection
    - nimblestorage::volume
    - nimblestorage::acr
    - nimblestorage::fs_mount
    - nimblestorage::snapshot
```

> `iscsiadm`

```
iscsiadm:
  config: 
    ensure: present
    port: <port>
    target: <data ip>
    user:
    password:
``` 

> `multipath`

```
  config: true
```

> chap

```
  ensure: present
  username: chapuser
  password: password_25-24
  systemIdentifier: test-chap-account
```

> `initiator`

```
initiator:
  ensure: present
  groupname: initiator-group
  label: initiator
  #ip_address:
  ip_address: "*"
  access_protocol: "iscsi"
  description: "This is a puppet initiator group"
  subnets:
   - <subnet>
```

> `protection_template`  

```
  prot-temp-1:
    ensure: present
    schedule_list:
      - name: schedule-1-1
        num_retain: 10
      - name: schedule-2-1
        num_retain: 20
```

> `volume_collection`

```
  vol-coll-1:
    ensure: present
    prottmpl_name: prot-temp-1
```

> `volumes`

```
volumes:
  volume_1:
    ensure: present
    name: volume-1
    size: <volume size><mgt>
   #clone: <true/false>
   #base_snap_name: <base snapshot name>
    description: sample
    perfpolicy: default
    force: true
    online: true
    vol_coll: vol-coll-1
   #restore_from: <base snapshot name>
```

> `access_control`

```
  volume_1:
    ensure: present
    volume_name: volume-1
    chap_user: chapuser
    initiator_group: initiator-group
    apply_to: both
```

> `mount_points`

```
  volume_1:
    ensure: present
    target_vol: volume-1
    mount_point: </path/to/mount>
    fs: <file system>
    label: vol_1
```

> `snapshots`

```
  snapshot-1:
    ensure: absent
    vol_name: volume-1
    online: true
    writable: true
```

---

#### Post installation tasks on Puppet agent

* editing hosts configs
```
ip=<master-ip>
echo "$ip puppet" | sudo tee -a /etc/hosts
```

* Start puppet agent on the node and make it start automatically on system boot.
```
puppet resource service puppet ensure=running enable=true
```

* submiting a certificate signing request (CSR) to the certificate authority (CA) Puppet master.
```
puppet agent --server <master-fqdn/master-ip> --waitforcert 60 -t --verbose
```

---
####  Running puppet agent
* Signing agent node certificate request (on Puppet master)

```
# puppet cert list --all
puppet cert sign <fqdn-agent>
```

* Running agent (on Puppet agent machine)
```
puppet agent -t -v
```

---

* Explore config directory to use nimblestorage module in your existing puppet environment.

* A pre Beta Release is avaiable on https://forge.puppet.com/ashishnkmsys/nimblestorage

* Use Git issues to report and track all activites, also attach (mandatory) tracelog for the same.

* Users who would like to write custom manifests can utilize the module structure to eliminate the wrapper built for usage. (Note: Part manifest and part hiera is also allowed) 
