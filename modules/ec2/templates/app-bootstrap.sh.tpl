#!/bin/bash
# App Bootstrap Script for Amazon Linux 2023

# Enable logging
exec > >(tee /var/log/app-bootstrap.log)
exec 2>&1

echo "Starting App bootstrap at $(date)"

# Update system
dnf update -y

# Set environment variables for the application
%{ if db_secret_arn != null ~}
echo "export DB_SECRET_ARN=${db_secret_arn}" >> /etc/environment
%{ endif ~}
echo "export AWS_DEFAULT_REGION=${aws_region}" >> /etc/environment

# Install Git and other dependencies (skip GPG checks for reliability)
dnf install -y git wget curl bind-utils telnet --nogpgcheck

dnf install -y bind-utils telnet

# Install Puppet agent repository

dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm --nogpgcheck

# Install Puppet agent (skip GPG checks for reliability)
dnf install -y puppet-agent --nogpgcheck

# Configure PATH for Puppet
export PATH="/opt/puppetlabs/bin:$PATH"
echo 'export PATH="/opt/puppetlabs/bin:$PATH"' >> /etc/environment

# Create puppet config directory if it doesn't exist
mkdir -p /etc/puppetlabs/puppet

# Configure puppet.conf using echo commands for proper SSL and concurrent connections
{
echo "[main]"
echo "server = ${puppet_server}"
echo "environment = ${puppet_environment}"
echo "runinterval = 300"
echo "waitforlock = 30"
echo "maxwaitforlock = 300" 
echo ""
echo "[agent]"
echo "certname = $(hostname -f)"
echo "ssl_client_verify_header = SSL_CLIENT_VERIFY"
echo "ssl_client_header = SSL_CLIENT_S_DN"
} > /etc/puppetlabs/puppet/puppet.conf

# Configure Puppet agent - ensure DNS resolution to puppet server
# Note: puppet_server should resolve via Route53, but add hosts entry as backup
echo "Adding ${puppet_server} to hosts file for reliable resolution"
echo "${puppet_server} puppet" >> /etc/hosts

# Ensure the server IP is accessible
SERVER_IP=$(nslookup ${puppet_server} | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -n1)
if [ ! -z "$SERVER_IP" ] && [ "$SERVER_IP" != "${puppet_server}" ]; then
    echo "$SERVER_IP ${puppet_server} puppet" >> /etc/hosts
    echo "Added server IP $SERVER_IP for ${puppet_server}"
fi

# Set proper permissions on puppet config
chown -R puppet:puppet /etc/puppetlabs/puppet/ 2>/dev/null || true
chmod 644 /etc/puppetlabs/puppet/puppet.conf

# Create external facts directory and dynamically determine the role from EC2 tags.
# This requires the EC2 instance to have an IAM role with ec2:DescribeTags permissions.
mkdir -p /etc/puppetlabs/facter/facts.d

# Get this instance's ID from metadata using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# Retry loop to wait for tags to be available
TIER_TAG="None"
for i in {1..6}; do
  echo "Attempt $i to fetch EC2 tags..."
  TAG_VALUE=$(aws ec2 describe-tags --region ${aws_region} --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Tier" --query "Tags[0].Value" --output text)
  if [ "$TAG_VALUE" != "None" ] && [ -n "$TAG_VALUE" ]; then
    TIER_TAG=$TAG_VALUE
    echo "Successfully fetched tag: Tier = $TIER_TAG"
    break
  fi
  echo "Tags not available yet. Retrying in 10 seconds..."
  sleep 10
done

# If the tag is not found or is the string "None", default the role to 'default'. Otherwise, use the tag value.
if [ "$TIER_TAG" == "None" ]; then
  ROLE="default"
else
  ROLE="$TIER_TAG"
fi

# Create the external fact script with the determined role
cat > /etc/puppetlabs/facter/facts.d/role.sh << EOF
#!/bin/sh
echo "role=$ROLE"
EOF

chmod +x /etc/puppetlabs/facter/facts.d/role.sh

# Download CA certificate and bootstrap SSL
echo "Downloading CA certificate from puppet server..."
mkdir -p /etc/puppetlabs/puppet/ssl/certs
curl -k https://${puppet_server}:8140/puppet-ca/v1/certificate/ca -o /etc/puppetlabs/puppet/ssl/certs/ca.pem
chmod 644 /etc/puppetlabs/puppet/ssl/certs/ca.pem

# Bootstrap SSL certificates with proper PATH
echo "Bootstrapping SSL certificates..."
env PATH="/opt/puppetlabs/bin:$PATH" /opt/puppetlabs/bin/puppet ssl bootstrap --server ${puppet_server} --waitforcert 300

# Run Puppet immediately to configure the node (with retries and proper locking)
# A successful puppet run that makes changes will exit with 2. We need to handle this.
for i in {1..3}; do
    echo "Puppet run attempt $i..."
    # Use full path and proper environment
    env PATH="/opt/puppetlabs/bin:$PATH" /opt/puppetlabs/bin/puppet agent --test --server ${puppet_server} --no-daemonize --onetime --verbose
    PUPPET_EXIT_CODE=$?
    if [ $PUPPET_EXIT_CODE -eq 0 ] || [ $PUPPET_EXIT_CODE -eq 2 ]; then
        echo "Puppet run successful!"
        break
    else
        echo "Puppet run $i failed with exit code $PUPPET_EXIT_CODE, retrying in 45 seconds..."
        sleep 45
    fi
done

# Now start and enable Puppet agent service for ongoing management
systemctl enable puppet
systemctl start puppet

echo "App bootstrap completed at $(date)"
