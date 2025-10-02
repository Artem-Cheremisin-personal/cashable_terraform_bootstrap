include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/vpn"
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
  # VPC configuration using outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  vpc_cidr = "192.168.0.0/16"  # Match VPC CIDR
  vpc_dns_resolver = "192.168.0.2"  # VPC DNS resolver (VPC CIDR base + 2)
  db_subnet_cidr = "192.168.100.0/24"  # Database subnet CIDR for restricted access
  subnet_id = dependency.vpc.outputs.vpn_association_subnet_id
  
  # VPN Configuration
  vpn_name = "cashabl-vpn"
  client_cidr = "10.10.0.0/16"  # Separate CIDR for VPN clients
  
  tags = {
    Application = "cashabl"
  }
}