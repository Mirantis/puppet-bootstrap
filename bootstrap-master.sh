#!/bin/bash

package=('git' 'http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm' 'ntp' 'puppet' 'puppet-server' 'http://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm' 'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm')

for i in ${package[@]}; do
    yum -y install $i
done

gem install hiera-eyaml
gem install deep_merge

service ntpd stop
ntpdate time.apple.com
service ntpd start

if [ -d /etc/puppet ]; then
  mv "/etc/puppet" "/etc/puppet.$(date +%Y%m%d)"
  rm -rf "/etc/puppet"
fi

sudo -u root -H sh -c "git clone https://[user]:[password]@github.com/[youraccount]/puppet-control.git /etc/puppet"

# Generate the following keys by:
# 1. installing hiera-eyaml gem
# 2. running: `eyaml createkeys`
mkdir -p /etc/puppet/keys
echo "[Your PKCS7 private key here]" > /etc/puppet/keys/private_key.pkcs7.pem

echo "[Your PKCS7 public certificate here]" > /etc/puppet/keys/public_key.pkcs7.pem

chown -R puppet:puppet /etc/puppet/keys
chmod 0700 /etc/puppet/keys
chmod 0600 /etc/puppet/keys/public_key.pkcs7.pem
chmod 0600 /etc/puppet/keys/private_key.pkcs7.pem

puppet module install zack/r10k

puppet apply /etc/puppet/configure_r10k.pp
if [[ $? != 0 ]]; then
  echo "Configure r10k failed"
  exit 1
fi
puppet apply /etc/puppet/configure_directory_environments.pp

r10k deploy environment -pv
if [[ $? != 0 ]]; then
  echo "r10k deploy failed"
  exit 1
fi

# The following sets up autosigning of the puppet cert
# The OID and key listed here need to be in /etc/puppet/csr_attributes.yaml
# prior to the cert being generated and need to be checked in your autosign
# executable at /etc/puppet/autosign-policy.rb

echo '### This file is managed by Puppet ###

# This is a yaml file for specifying custom CSR extensions for policy-based auto signing
---
extension_requests:
  [your csr_attributes oid]: "[your csr attributes key]"' > /etc/puppet/csr_attributes.yaml

puppet agent -t --server [your puppet master here] --ca_server [your CA server here]
