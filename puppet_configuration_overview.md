# Puppet Configuration Guide

This document explains how to configure Puppet agents on app and nginx servers and manage services using Puppet server and systemd.

## Overview

The infrastructure uses Puppet for centralized configuration management:
- **Puppet Server**: Centralized configuration management server
- **Puppet Agents**: Installed on app and nginx instances
- **Systemd**: Service management on Linux instances

## Architecture

```
┌─────────────────┐
│   Puppet Server │
│                 │
│ puppet.internal │
└───────┬───┬─────┘
        │   │
        │   └────────────────┐
        ▼                    ▼
┌─────────────────┐    ┌─────────────────┐
│   App Servers   │    │  Nginx Servers  │
│                 │    │                 │
│  puppet agent   │    │  puppet agent   │
│   app service   │    │  nginx service  │
└─────────────────┘    └─────────────────┘
```

## Puppet Server Configuration

### 1. Server Setup
- **Hostname**: `puppet.internal.cashabl.local` (Route53 DNS)
- **Port**: 8140 (standard Puppet port)
- **SSL**: Auto-signed certificates for internal communication

### 2. Puppet Manifests Structure
```
/etc/puppetlabs/code/environments/production/
├── manifests/
│   ├── site.pp              # Main manifest
│   ├── nodes/
│   │   ├── app.pp          # App server configuration
│   │   └── nginx.pp        # Nginx server configuration
└── modules/
    ├── app/                # App module
    │   ├── manifests/
    │   ├── templates/
    │   └── files/
    └── nginx/              # Nginx module
        ├── manifests/
        ├── templates/
        └── files/
```

## Puppet Agent Configuration

### 1. Agent Installation (via user-data)
The agent is installed and configured via the user-data script located at `tf_Task/modules/ec2/templates/app-bootstrap.sh.tpl`. This script handles the installation of the `puppet-agent`, configures it to communicate with the Puppet Server, and sets up an external fact based on the instance's EC2 tags to determine its role (e.g., `app` or `nginx`).

### 2. Agent Registration
- Agents automatically request certificates from Puppet server
- Server auto-signs certificates for internal domain
- Agents run every 30 minutes by default

## Application Service Management

### 1. App Service Configuration

**Actual App Configuration** (from `tf_Task/modules/puppet/templates/puppet-server-bootstrap.sh.tpl`):
```puppet
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
```

**Key Configuration Details:**
- **Working Directory**: `/opt/cashabl-app`
- **User**: `ec2-user`
- **Database Access**: Uses `DB_SECRET_ARN` environment variable 
- **Application Source**: Cloned from Git repository
- **Dependencies**: Installed from `requirements.txt`

### 2. Nginx Service Configuration

**Actual Nginx Configuration** (from `tf_Task/modules/puppet/templates/puppet-server-bootstrap.sh.tpl`):
```puppet
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
```

**Actual Nginx Configuration** (`/etc/nginx/nginx.conf`):
```nginx
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

    # Upstream to ALB (Application Load Balancer) via static DNS name
    upstream app_backend {
        server ${alb_dns_name}:80;
    }

    server {
        listen       80 default_server;
        server_name  _;

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
```

**Key Configuration Details:**
- **Architecture**: Nginx proxies to Application Load Balancer 
- **Configuration**: Uses main `/etc/nginx/nginx.conf` 
- **Upstream**: Points to `${alb_dns_name}:80` 
- **Health Check**: Returns "OK" at `/health` endpoint


## Security Considerations

- **Certificate Management**: Puppet uses SSL certificates for secure communication
- **Node Classification**: Nodes are classified by hostname patterns
- **Secret Management**: Sensitive data (passwords, keys) stored in Hiera or AWS Secrets Manager
- **File Permissions**: Puppet ensures proper file ownership and permissions

## Monitoring and Logging

- **Service Health**: Systemd provides service status and restart capabilities
- **Logs**: Centralized logging via journalctl
- **Puppet Reports**: Puppet server maintains run reports for all agents
- **Load Balancer Health Checks**: ALB performs health checks on nginx endpoints

