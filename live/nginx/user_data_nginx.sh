#!/bin/bash
yum update -y

# Install Puppet agent
rpm -Uvh https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
yum install -y puppet-agent

# Configure Puppet agent
echo "puppet-server.internal.cashabl.local puppet" >> /etc/hosts
/opt/puppetlabs/bin/puppet config set server puppet-server.internal.cashabl.local
/opt/puppetlabs/bin/puppet config set runinterval 300

# Start and enable Puppet agent
systemctl enable puppet
systemctl start puppet

# Run Puppet immediately to configure the node
/opt/puppetlabs/bin/puppet agent --test --server puppet-server.internal.cashabl.local || true

# Signal that the instance is ready  
/opt/aws/bin/cfn-signal -e $? --region ${aws_region} || true
