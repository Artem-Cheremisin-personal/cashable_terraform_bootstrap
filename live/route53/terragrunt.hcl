include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/route53"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id = "vpc-mockid123"
  }
}

dependency "aurora" {
  config_path = "../aurora_postgress"
  
  mock_outputs = {
    aurora_endpoint = "mock-aurora-endpoint.amazonaws.com"
  }
}

inputs = {
  # VPC association
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # Aurora endpoint
  aurora_cluster_endpoint = dependency.aurora.outputs.aurora_endpoint
  
  # Private domain configuration
  domain_name = "internal.cashabl.local"
  alb_cname = "app-alb"
  
  tags = {
    Application = "cashabl"
    Environment = "dev"
  }
}
