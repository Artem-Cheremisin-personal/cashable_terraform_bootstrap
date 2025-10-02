include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/aurora_postgress"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.db_subnet_ids
  security_group_ids = [dependency.vpc.outputs.database_sg_id]
  
  cluster_identifier = "cashabl-aurora-cluster"
  engine_version = "15.4"
  
  # Multi-AZ configuration
  
  # Instance configuration
  instance_class = "db.t3.medium"
  instance_count = 3
  
  # Enable Multi-AZ for high availability
  multi_az = true
  
  # Use DB subnet group from VPC module (spans across AZs)
  db_subnet_group_name = dependency.vpc.outputs.db_subnet_group_name
  
  # IAM authentication enabled
  iam_database_authentication_enabled = false
  # IAM roles will be added later after IAM module creates them
  
  # Database settings
  database_name = "cashabl"
  master_username = "postgres"
  
  # Secrets Manager for password
  secret_name = "cashabl-aurora-master-password"
  
  # Backup and maintenance
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  # Encryption
  storage_encrypted = true
  
  tags = {
    Application = "cashabl"
  }
}