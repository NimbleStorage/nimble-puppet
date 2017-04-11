# Nimble Array Puppet Module

This wrapper module allows to interact with different objects in Nimble Storage Arrays like Volumes, Snapshot etc.

## Usage
### Requirements
- fqdn, ip address and credentials of below machines
	- Puppet master
	- Puppet agent
	- Nimble array (Management portal)

### How to steps

#### On Puppet Master
* Preparing master (installing puppet server & other utility tools)
```
ssh root@<ip master>
curl https://raw.githubusercontent.com/NimbleStorage/nimble-puppet/master/config/client-server-init-scripts/master.sh | sh
```


* (Optional) Configuring array credentials for security
```
export EYAML_CONFIG=/etc/eyaml-conf.yaml
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

* Creating node specific config script
```
cd /etc/puppetlabs/code/environments/production/hieradata/nodes/
```

* Edit `<fqdn-agent-machine>.yaml` template to a node specific script as below.


change the section accordingly in template.
> `agent`
	
_Note_ :- Add or remove below classes according to requirements.

```
<hostname>:
    - nimblestorage::init
    - nimblestorage::chap
    - nimblestorage::initiator_group
    - nimblestorage::initiator
    - nimblestorage::volume
    - nimblestorage::acr
    - nimblestorage::fs_mount

```

> `initiator`

```
initiator:
  ensure: present
  groupname:
  label:
  #ip_address:
  ip_address: "*"
  access_protocol: "iscsi"
  description: "This is a puppet initiator group"
  subnets:
   - <subnet>
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

---
#### On Puppet agent

* Preparing agent (installing puppet agent & others tools) 
```
ssh root@<ip agent>
wget https://raw.githubusercontent.com/NimbleStorage/nimble-puppet/master/config/client-server-init-scripts/agent.sh -O agent.sh
sh agent.sh
```
You will be asked for the puppet master IP address. If not available hit return and enter the fqdn of the master server.

---
####  Running puppet agent
* Signing certificate request (runs on Puppet master)

```
puppet cert sign <fqdn-agent>
```

* Running puppet agent (on Puppet agent)
```
puppet agent -t -v
```

* Explore config directory to use nimblestorage module in your existing puppet environment.

* A pre Beta Release is avaiable on https://forge.puppet.com/ashishnkmsys/nimblestorage

* Use Git issues to report and track all activites, also attach (mandatory) tracelog for the same.

* Users who would like to write custom manifests can utilize the module structure to eliminate the wrapper built for usage. (Note: Part manifest and part hiera is also allowed) 
