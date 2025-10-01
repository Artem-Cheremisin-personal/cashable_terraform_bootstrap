#!/bin/bash
# Puppet Server Bootstrap Script for Amazon Linux 2023

# Enable logging
exec > >(tee /var/log/puppet-bootstrap.log)
exec 2>&1

echo "Starting Puppet Server bootstrap at $(date)"

# Update system
dnf update -y

# Install Git, SSM Agent and other dependencies
dnf install -y git wget curl amazon-ssm-agent

# Ensure SSM agent enabled early for remote access
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent || systemctl start amazon-ssm-agent
echo "Waiting for SSM agent to register..."
SSM_WAIT=0
while [ ! -f /var/lib/amazon/ssm/registration/registration ]; do
  sleep 3
  SSM_WAIT=$((SSM_WAIT+3))
  [ $SSM_WAIT -gt 60 ] && echo "SSM registration wait exceeded 60s, continuing" && break
done
echo "SSM bootstrap phase complete"

# Install Puppet Server repository
dnf install -y https://yum.puppet.com/puppet7-release-el-9.noarch.rpm

# Import Puppet GPG keys
rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet7-release

# Install Puppet Server
dnf install -y puppetserver

# Configure Puppet Server memory (for t3.small - 2GB RAM)
sed -i 's/-Xms2g/-Xms1g/g' /etc/sysconfig/puppetserver
sed -i 's/-Xmx2g/-Xmx1536m/g' /etc/sysconfig/puppetserver

# Configure DNS resolution for puppet server (preserving original hostname for SSM)
ORIGINAL_HOSTNAME=$(hostname)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo "Original hostname: $ORIGINAL_HOSTNAME (preserving for SSM)"
echo "Private IP: $PRIVATE_IP"

# Add DNS entries for puppet resolution
echo "127.0.0.1 puppet.internal.cashabl.local puppet" >> /etc/hosts
echo "$PRIVATE_IP puppet.internal.cashabl.local puppet" >> /etc/hosts

# Configure Puppet Server with correct certificate settings
/opt/puppetlabs/bin/puppet config set server puppet.internal.cashabl.local --section main || true
/opt/puppetlabs/bin/puppet config set dns_alt_names "puppet,puppet.internal.cashabl.local,$(hostname -f)" --section main
/opt/puppetlabs/bin/puppet config set certname puppet.internal.cashabl.local --section main
/opt/puppetlabs/bin/puppet config set trusted_node_data true --section master


# Configure for multiple concurrent connections
/opt/puppetlabs/bin/puppet config set max_concurrent_connections 10 --section main

# Start and enable Puppet Server
systemctl enable puppetserver
systemctl start puppetserver

# Wait and verify Puppet Server is running
sleep 90
systemctl status puppetserver

# If it failed to start, try again
if ! systemctl is-active --quiet puppetserver; then
  echo "Puppet Server failed to start on first attempt, retrying..."
  systemctl restart puppetserver
  sleep 60
  systemctl status puppetserver
fi

# Wait for port 8140 to accept TLS connections (max 90s)
echo "Waiting for puppetserver port 8140 to become ready..."
P_READY=0
while ! (echo | openssl s_client -connect localhost:8140 -servername puppet.internal.cashabl.local >/dev/null 2>&1); do
  sleep 5
  P_READY=$((P_READY+5))
  [ $P_READY -ge 90 ] && echo "Puppetserver TLS port not ready after 90s" && break
done
echo "Puppetserver TLS readiness wait complete"

# Generate SSL certificate with correct DNS names
/opt/puppetlabs/bin/puppetserver ca generate --certname puppet.internal.cashabl.local --subject-alt-names DNS:puppet,DNS:puppet.internal.cashabl.local

# Install Puppet agent for local management
dnf install -y puppet-agent
export PATH="/opt/puppetlabs/bin:$PATH"
echo 'export PATH="/opt/puppetlabs/bin:$PATH"' >> /etc/environment

# Configure Puppet agent to connect to local server
/opt/puppetlabs/bin/puppet config set server puppet.internal.cashabl.local --section main

# Create directory structure for environments
mkdir -p /etc/puppetlabs/code/environments/production/manifests

# Write the static site.pp content
cat > /etc/puppetlabs/code/environments/production/manifests/site.pp << 'EOF'
${site_pp_content}
EOF

# Create app configuration module
mkdir -p /etc/puppetlabs/code/environments/production/modules/app_config/{manifests,files,templates}

cat > /etc/puppetlabs/code/environments/production/modules/app_config/manifests/init.pp << 'EOF'
class app_config {
  # Python and Flask dependencies
  package { ['python3', 'python3-pip', 'git']:
    ensure => installed,
  }

  # Clone the application repository
  exec { 'clone_app':
    command => "/usr/bin/git clone ${app_repo_url} /opt/cashabl-app",
    creates => "/opt/cashabl-app",
    require => Package['git'],
  }

  # Install Python dependencies from requirements.txt
  exec { 'install_python_deps':
    command => "/usr/bin/pip3 install -r /opt/cashabl-app/requirements.txt",
    unless  => "/usr/bin/pip3 show flask boto3 psycopg2-binary",
    require => [Package['python3-pip'], Exec['clone_app']],
  }

  # Create systemd service for the Flask app
  file { '/etc/systemd/system/cashabl-app.service':
    ensure  => present,
    content => "[Unit]
Description=Cashabl Flask Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/cashabl-app
ExecStart=/usr/bin/python3 app.py
Restart=always
Environment=FLASK_ENV=production
Environment=DB_SECRET_ARN=${db_secret_arn}
Environment=AWS_DEFAULT_REGION=eu-central-1

[Install]
WantedBy=multi-user.target
",
    notify  => Service['cashabl-app'],
  }

  service { 'cashabl-app':
    ensure  => running,
    enable  => true,
    require => [File['/etc/systemd/system/cashabl-app.service'], Exec['install_python_deps']],
  }
}
EOF

# Create nginx configuration module with ALB upstream
mkdir -p /etc/puppetlabs/code/environments/production/modules/nginx_config/{manifests,files,templates}

cat > /etc/puppetlabs/code/environments/production/modules/nginx_config/manifests/init.pp << 'EOF'
class nginx_config {
  package { 'nginx':
    ensure => installed,
  }

  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => Package['nginx'],
  }

  # NGINX configuration file with ALB upstream
  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    content => template('nginx_config/nginx.conf.erb'),
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
}
EOF

# Create NGINX template directory and template file
mkdir -p /etc/puppetlabs/code/environments/production/modules/nginx_config/templates

cat > /etc/puppetlabs/code/environments/production/modules/nginx_config/templates/nginx.conf.erb << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Upstream to ALB (Application Load Balancer) via static DNS name
    upstream app_backend {
        server ${alb_dns_name}:80;
    }

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        # Proxy all other requests to ALB
        location / {
            proxy_pass http://app_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Health check and connection settings
            proxy_connect_timeout       5s;
            proxy_send_timeout          60s;
            proxy_read_timeout          60s;
        }
    }
}
EOF

# Configure autosign for app instances with specific pattern
{
echo "*.internal.cashabl.local"
echo "cashabl-app*.internal.cashabl.local"
echo "*.eu-central-1.compute.internal"
} > /etc/puppetlabs/puppet/autosign.conf
chown puppet:puppet /etc/puppetlabs/puppet/autosign.conf
chmod 644 /etc/puppetlabs/puppet/autosign.conf

# Configure firewall for Puppet Server
firewall-cmd --permanent --add-port=8140/tcp
firewall-cmd --reload

echo "Puppet Server installation and configuration completed"
echo "ALB DNS Name configured for NGINX: ${alb_dns_name}"
echo "Puppet autosign enabled - certificates will be automatically accepted"
