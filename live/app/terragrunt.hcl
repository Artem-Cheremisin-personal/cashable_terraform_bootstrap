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
  
  mock_outputs = {
    vpc_id = "vpc-mockid123"
    app_subnet_ids = ["subnet-mock-app1", "subnet-mock-app2"]
    app_sg_id = "sg-mock-app"
  }
}

dependency "iam" {
  config_path = "../iam"
  
  mock_outputs = {
    instance_profile_name = "mock-instance-profile"
  }
}

dependency "aurora" {
  config_path = "../aurora_postgress"
  
  mock_outputs = {
    database_connection_secret_arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:mock-secret"
  }
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
  
  # Target Group Configuration - Flask runs on port 5000
  target_group_port = 5000
  target_group_protocol = "HTTP"
  
  # Health check configuration for Flask app
  health_check_path = "/"
  health_check_matcher = "200"
  health_check_timeout = 5
  health_check_interval = 30
  health_check_healthy_threshold = 2
  health_check_unhealthy_threshold = 5  # Higher threshold to prevent killing instances during testing
  health_check_grace_period = 300  # 5 minutes grace period for testing
  
  # Puppet configuration - enabled to use puppet server
  puppet_enabled = true
  puppet_server = local.root_vars.inputs.puppet_server_hostname
  puppet_environment = "production"
  puppet_certname = "cashabl-app"
  
  # Pass database secret ARN and region as variables
  db_secret_arn = dependency.aurora.outputs.database_connection_secret_arn
  aws_region = "eu-central-1"
  
  # Simple user data script
  user_data = file("${get_terragrunt_dir()}/user_data.sh")
  
  tags = {
    Name = "cashabl-app"
    Application = "cashabl"
    Tier = "app"
  }
}