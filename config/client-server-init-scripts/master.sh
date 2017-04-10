#! /bin/bash
read -s -p "Enter Password for sudo: " sudoPW
echo $sudoPW | sudo -S timedatectl set-timezone Asia/Kolkata
sudo yum -y install ntp net-tools rubygems
sudo ntpdate pool.ntp.org
sudo systemctl restart ntpd
sudo systemctl enable ntpd
sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum -y install puppetserver
sudo systemctl start puppetserver
sudo systemctl enable puppetserver
gem install hiera hiera-eyaml
sudo /opt/puppetlabs/bin/puppetserver gem install hiera-eyaml
#sudo iptables -A INPUT -p tcp --dport 8140 -j ACCEPT
sudo iptables -F
sudo ln -s /opt/puppetlabs/bin/puppet /bin/puppet
export EYAML_CONFIG=/etc/eyaml-conf.yaml
eyaml create keys
sudo mv ~/keys /etc/puppetlabs
sudo echo <<<EOF
---

version: 5

defaults:
  datadir: /etc/puppetlabs/code/environments/%{environment}/hieradata
  data_hash: eyaml_lookup_key

hierarchy:
  - name: "Secret's"
    path: "secure.yaml"
    lookup_key: eyaml_lookup_key
    options:
        pkcs7_private_key: /etc/puppetlabs/keys/private_key.pkcs7.pem
        pkcs7_public_key: /etc/puppetlabs/keys/public_key.pkcs7.pem

  - name: "Other"
    path: "common.yaml"
    data_hash: yaml_data

  - name: "Per-node data"
    path: "nodes/%{fqdn}.yaml"
    data_hash: yaml_data

EOF > /etc/eyaml.conf