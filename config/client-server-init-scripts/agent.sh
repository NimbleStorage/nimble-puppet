#! /bin/bash
read -s -p "Enter Password for sudo: " sudoPW
echo $sudoPW | sudo -S timedatectl set-timezone Asia/Kolkata
sudo yum -y install ntp net-tools
sudo ntpdate pool.ntp.org
sudo systemctl restart ntpd
sudo systemctl enable ntpd
sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum -y install puppet-agent
sudo ln -s /opt/puppetlabs/bin/puppet /bin/puppet
echo "192.168.121.210 puppet" | sudo tee -a /etc/hosts
sudo puppet agent --server puppet --waitforcert 60 -t --verbose
sudo puppet resource service puppet ensure=running enable=true