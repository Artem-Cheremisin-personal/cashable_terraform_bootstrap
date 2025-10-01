#!/bin/bash
# Enable logging
exec > >(tee /var/log/app-bootstrap.log)
exec 2>&1

echo "Starting app instance bootstrap at $(date)"

dnf update -y

# Environment variables are set by Terraform in EC2 module
# DB_SECRET_ARN and AWS_DEFAULT_REGION are automatically available

# Install Puppet agent
dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm

# Import Puppet GPG keys
rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet7-release

dnf install -y puppet-agent

# Configure Puppet agent with proper DNS resolution
echo "192.168.1.100 puppet-server.internal.cashabl.local puppet" >> /etc/hosts
/opt/puppetlabs/bin/puppet config set server puppet-server.internal.cashabl.local
/opt/puppetlabs/bin/puppet config set runinterval 300
/opt/puppetlabs/bin/puppet config set waitforcert 60

# Start and enable Puppet agent
systemctl enable puppet
systemctl start puppet

# Wait for puppet server to be available
echo "Waiting for puppet server to be available..."
for i in {1..10}; do
  if /opt/puppetlabs/bin/puppet agent --test --server puppet-server.internal.cashabl.local --noop; then
    echo "Puppet server is available"
    break
  fi
  echo "Attempt $i failed, waiting 30 seconds..."
  sleep 30
done

# Run Puppet to configure the node
echo "Running puppet agent for configuration..."
/opt/puppetlabs/bin/puppet agent --test --server puppet-server.internal.cashabl.local || true

echo "App instance bootstrap completed at $(date)"
