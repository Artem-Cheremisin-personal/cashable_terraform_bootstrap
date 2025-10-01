include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/ec2"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id = "mock-vpc-id"
    nginx_subnet_ids = ["mock-subnet-1", "mock-subnet-2"]
    nginx_sg_id = "mock-sg-id"
  }
}

dependency "iam" {
  config_path = "../iam"
  
  mock_outputs = {
    instance_profile_name = "mock-instance-profile"
  }
}

dependency "puppet" {
  config_path = "../puppet"
  
  mock_outputs = {
    puppet_server_private_ip = "10.0.1.130"
  }
}

dependency "route53" {
  config_path = "../route53"
  
  mock_outputs = {
    alb_dns_name = "app-alb.internal.cashabl.local"
  }
}

inputs = {
  # Name for EC2 resources
  name = "cashabl-nginx"
  
  # Instance configuration - Free tier
  instance_type = "t2.micro"
  
  # Autoscaling configuration - NGINX requirements: min 2, max 5
  min_size = 2
  max_size = 5
  desired_capacity = 2
  
  # VPC configuration using outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.nginx_subnet_ids
  security_groups = [dependency.vpc.outputs.nginx_sg_id]
  
  # IAM role
  iam_instance_profile = dependency.iam.outputs.instance_profile_name
  
  # Puppet configuration - use dynamic IP from Puppet server output
  puppet_server_ip = dependency.puppet.outputs.puppet_server_private_ip
  install_puppet_agent = true
  
  # APP Load Balancer DNS for proxy configuration - using Route 53 static name
  app_lb_dns = dependency.route53.outputs.alb_dns_name
  
  tags = {
    Name = "cashabl-nginx"
    Application = "cashabl"
    Tier = "nginx"
  }
}