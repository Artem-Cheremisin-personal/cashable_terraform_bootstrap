include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/vpn"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id = "vpc-mockid123"
    public_subnet_ids = ["subnet-mock-public-1", "subnet-mock-public-2"]
  }
}

inputs = {
  # VPC configuration using outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  vpc_cidr = "192.168.0.0/16"  # Match VPC CIDR
  db_subnet_cidr = "192.168.100.0/24"  # Database subnet CIDR for restricted access
  subnet_id = dependency.vpc.outputs.public_subnet_ids[0]
  
  # VPN Configuration
  vpn_name = "cashabl-vpn"
  client_cidr = "10.10.0.0/16"  # Separate CIDR for VPN clients
  
  tags = {
    Application = "cashabl"
  }
}