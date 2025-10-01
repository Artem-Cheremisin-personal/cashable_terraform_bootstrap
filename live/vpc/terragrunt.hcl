include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/vpc"
}

inputs = {
  region = "eu-central-1"
  cidr   = "192.168.0.0/16"
}