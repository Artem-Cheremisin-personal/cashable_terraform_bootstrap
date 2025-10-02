include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/iam"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "aurora" {
  config_path = "../aurora_postgress"
}

dependency "route53" {
  config_path = "../route53"
}

inputs = {
  role_name = "cashabl-app-role"
  rds_resource_arns = [
    dependency.aurora.outputs.rds_iam_auth_resource_arn
  ]
  
  # Additional AWS managed policies for SSM and CloudWatch
  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  
  # Tags
  tags = {
    Application = "cashabl"
  }
}