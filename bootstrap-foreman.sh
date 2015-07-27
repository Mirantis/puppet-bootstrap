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

sudo -u root -H sh -c "git clone https://[youruser]:[yourpass]@github.com/[youruser]/puppet-control.git /etc/puppet"

# Generate the following keys by:
# 1. installing hiera-eyaml gem
# 2. running: `eyaml createkeys`
mkdir -p /etc/puppet/keys
echo "[Place your private PKCS7 key here]" > /etc/puppet/keys/private_key.pkcs7.pem

echo "[Place your public PKCS7 certificate here]" > /etc/puppet/keys/public_key.pkcs7.pem

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

export FACTER_application_tier='foreman'

puppet apply --modulepath=/etc/puppet/environments/production/modules --hiera_config=/etc/puppet/environments/production/hiera.yaml -e "include ::roles::foreman::bootstrap_server"
perl -p -i -e "s/storeconfigs\ \ \ =\ true/#storeconfigs\ \ \ =\ true/" /etc/puppet/puppet.conf
perl -p -i -e "s/storeconfigs_backend\ =\ puppetdb/#storeconfigs_backend\ =\ puppetdb/" /etc/puppet/puppet.conf
service httpd restart

# import puppet classes
curl -X POST -k -u "admin:[foreman password]" "https://foreman.[yourdomain.tld]/api/smart_proxies/1/import_puppetclasses"
