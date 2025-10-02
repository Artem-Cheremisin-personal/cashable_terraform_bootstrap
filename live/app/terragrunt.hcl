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

dependency "aurora" {
  config_path = "../aurora_postgress"
}

dependency "app_lb" {
  config_path = "../app_lb"
}

dependency "puppet" {
  config_path = "../puppet"
}

dependency "route53" {
  config_path = "../route53"
}

inputs = {
  # Name and instance configuration
  name = "cashabl-app"
  instance_family = "t3"
  instance_size = "small"
  
  # Autoscaling configuration - APP requirements: min 2, max 5
  min_size = 2
  max_size = 5
  desired_capacity = 2
  
  # VPC configuration using outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.app_subnet_ids
  security_groups = [dependency.vpc.outputs.app_sg_id]
  
  # IAM role
  iam_instance_profile = dependency.iam.outputs.instance_profile_name
  
  # Target Group ARN from ALB module
  target_group_arns = [dependency.app_lb.outputs.target_group_arn]
  
  # Puppet configuration - enabled to use puppet server
  puppet_enabled = true
  puppet_server = local.root_vars.inputs.puppet_server_hostname
  puppet_environment = "production"
  puppet_certname = "cashabl-app"
  
  # Pass database secret ARN and region as variables
  db_secret_arn = dependency.aurora.outputs.database_connection_secret_arn
  aws_region = "eu-central-1"
  
  tags = {
    Name = "cashabl-app"
    Application = "cashabl"
    Tier = "app"
  }
}