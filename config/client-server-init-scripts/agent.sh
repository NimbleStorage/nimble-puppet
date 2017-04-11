#! /bin/bash
read -p "Puppet master IP address : " ip
if [ ! $ip ]
then
read -p "Puppet master fqdn : " fqdn
fi
timedatectl set-timezone Asia/Kolkata
yum -y install ntp net-tools
ntpdate pool.ntp.org
systemctl restart ntpd
systemctl enable ntpd
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install puppet-agent
ln -s /opt/puppetlabs/bin/puppet /bin/puppet
if [ $ip ]
then
echo "$ip puppet" | sudo tee -a /etc/hosts
puppet agent --server puppet --waitforcert 60 -t --verbose
else
puppet agent --server $fqdn --waitforcert 60 -t --verbose
fi
puppet resource service puppet ensure=running enable=true
