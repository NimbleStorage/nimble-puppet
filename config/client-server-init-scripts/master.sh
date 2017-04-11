#! /bin/bash

timedatectl set-timezone Asia/Kolkata
yum -y install ntp net-tools rubygems git
ntpdate pool.ntp.org
systemctl restart ntpd
systemctl enable ntpd
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install puppetserver
systemctl start puppetserver
systemctl enable puppetserver
gem install hiera hiera-eyaml
/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml
iptables -F
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8140 -j ACCEPT
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
export EYAML_CONFIG=/etc/eyaml-conf.yaml
eyaml createkeys
mv keys /etc/puppetlabs
puppet module install ashishnkmsys-nimblestorage
git clone 'https://github.com/ashishnk/nimble-puppet'
cd nimble-puppet
git checkout msys
cp config/eyaml/eyaml-conf.yaml /etc/eyaml-conf.yaml
cp config/hiera/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml
cp -r config/hiera/hieradata /etc/puppetlabs/code/environments/production
cp config/site.pp /etc/puppetlabs/code/environments/production/manifests
chmod 644 /etc/puppetlabs/keys/*
puppet generate types