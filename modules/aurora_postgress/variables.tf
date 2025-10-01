variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_identifier" {
  description = "The cluster identifier"
  type        = string
}

variable "engine_version" {
  description = "The engine version"
  type        = string
  default     = "15.4"
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "postgres"
}

variable "database_name" {
  description = "The name of the database"
  type        = string
}

variable "instance_class" {
  description = "The instance class to use"
  type        = string
  default     = "db.t3.micro"
}

variable "instance_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 3
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "iam_roles" {
  description = "List of IAM roles ARNs to associate with the cluster"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "The daily time range for backups"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "The weekly time range for maintenance"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name of the secrets manager secret"
  type        = string
  default     = "cashabl-aurora-master-password"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
