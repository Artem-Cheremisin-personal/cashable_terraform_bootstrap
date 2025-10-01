#!/bin/bash
# Puppet Agent Installation and Configuration Script

# Enable logging
exec > >(tee /var/log/puppet-agent-bootstrap.log)
exec 2>&1

echo "Starting Puppet Agent bootstrap at $(date)"

# Update system
dnf update -y

# Install Puppet repository
dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm

# Import Puppet GPG keys
rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet7-release

# Install Puppet Agent
dnf install -y puppet-agent

# Clean up any old SSL certificates
rm -rf /etc/puppetlabs/puppet/ssl

# Configure Puppet Agent
/opt/puppetlabs/bin/puppet config set server ${puppet_server} --section main
/opt/puppetlabs/bin/puppet config set environment ${puppet_environment} --section main
/opt/puppetlabs/bin/puppet config set certname "%{facts.identity.hostname}" --section main

# Start and enable Puppet Agent
systemctl enable puppet
systemctl start puppet

echo "Puppet Agent bootstrap complete"
