include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/ec2"
}

# Access global variables from root
locals {
  root_vars = read_terragrunt_config(find_in_parent_folders())
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

dependency "puppet" {
  config_path = "../puppet"
}

dependency "route53" {
  config_path = "../route53"
}

dependency "nginx_lb" {
  config_path = "../nginx_lb"
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
  iam_instance_profile = dependency.iam.outputs.nginx_instance_profile_name
  
  # Use target group created by nginx_lb
  target_group_arns = [dependency.nginx_lb.outputs.target_group_arn]
  
  # Puppet configuration - enabled to use puppet server
  puppet_enabled = true
  puppet_server = local.root_vars.inputs.puppet_server_hostname
  puppet_environment = "production"
  puppet_certname = "nginx-app"
                                                                  
  tags = {
    Name = "cashabl-nginx"                                                 
    Application = "cashabl"
    Tier = "nginx"                                                                          
  }
}