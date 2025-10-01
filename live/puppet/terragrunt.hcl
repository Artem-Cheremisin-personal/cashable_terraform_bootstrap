include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/puppet"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id = "vpc-mockid123"
    puppet_management_subnet_ids = ["subnet-mock-puppet"]
    puppet_server_sg_id = "sg-mock-puppet"
  }
}

dependency "iam" {
  config_path = "../iam"
  
  mock_outputs = {
    instance_profile_name = "mock-instance-profile"
  }
}

dependency "route53" {
  config_path = "../route53"
  
  mock_outputs = {
    alb_dns_name = "app-alb.internal.cashabl.local"
    hosted_zone_id = "Z123456789"
    puppet_server_record_name = "puppet-server"
  }
}

dependency "aurora" {
  config_path = "../aurora_postgress"
  
  mock_outputs = {
    database_connection_secret_arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:mock-secret"
  }
}

inputs = {
  # Instance configuration - Puppet server needs minimum 2GB RAM
  instance_type = "t3.small"
  
  # VPC configuration using outputs
  subnet_id = dependency.vpc.outputs.puppet_management_subnet_ids[0]
  security_groups = [dependency.vpc.outputs.puppet_server_sg_id]
  
  # IAM role - separate puppet server role
  iam_instance_profile = dependency.iam.outputs.puppet_server_instance_profile_name
  
  # ALB DNS name for nginx configuration (static from Route53)
  alb_dns_name = dependency.route53.outputs.alb_dns_name
  
  # App repository URL - updated with correct GitHub repository
  app_repo_url = "https://github.com/Artem-Cheremisin-personal/test-flask-task.git"
  
  # Database secret ARN for Flask app
  db_secret_arn = dependency.aurora.outputs.database_connection_secret_arn
  
  # Route 53 DNS configuration for Puppet server
  route53_zone_id = dependency.route53.outputs.private_zone_id
  route53_record_name = "puppet"
  
  # Puppet server configuration
  puppet_server_name = "cashabl-puppet-server"
  
  tags = {
    Application = "cashabl"
  }
}
