terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  # Local backend - state files stored locally
  backend "local" {}
}

provider "aws" {
  region = var.region
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Aurora cluster with AWS managed password
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = var.cluster_identifier
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version
  
  # Use AWS managed master user password (creates secret automatically)
  manage_master_user_password = true
  master_username            = var.master_username
  database_name              = var.database_name
  
  # Networking
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.security_group_ids
  
  # IAM authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  iam_roles                          = var.iam_roles
  
  # Backup and maintenance
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  
  # Storage
  storage_encrypted = var.storage_encrypted
  
  skip_final_snapshot = true
  
  tags = var.tags
}

# Random ID for unique secret names
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# Database connection secret (RDS/Aurora format with all connection details)
resource "aws_secretsmanager_secret" "database_connection" {
  name                    = "${var.cluster_identifier}-connection-${random_id.secret_suffix.hex}"
  description             = "Complete database connection details for ${var.cluster_identifier}"
  recovery_window_in_days = 0  # Allow immediate deletion for dev environment
  
  tags = var.tags
}

# Use data source to get the AWS managed secret password
data "aws_secretsmanager_secret_version" "aurora_master" {
  secret_id = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}

locals {
  aurora_password = jsondecode(data.aws_secretsmanager_secret_version.aurora_master.secret_string)["password"]
}

resource "aws_secretsmanager_secret_version" "database_connection" {
  secret_id = aws_secretsmanager_secret.database_connection.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_rds_cluster.aurora.endpoint
    port     = aws_rds_cluster.aurora.port
    dbname   = aws_rds_cluster.aurora.database_name
    username = aws_rds_cluster.aurora.master_username
    password = local.aurora_password
  })
}

# Aurora cluster instances
resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  
  tags = var.tags
}