include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/iam"
}

dependency "aurora" {
  config_path = "../aurora_postgress"
  
  mock_outputs = {
    aurora_cluster_arn = "arn:aws:rds:eu-central-1:123456789012:cluster:mock-aurora-cluster"
    rds_iam_auth_resource_arn = "arn:aws:rds-db:eu-central-1:123456789012:dbuser:mock-aurora-cluster/*"
  }
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