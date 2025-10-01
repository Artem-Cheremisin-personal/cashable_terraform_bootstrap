variable "name" {
  description = "Name prefix for Puppet server resources"
  type        = string
  default     = "puppet"
}

variable "instance_type" {
  description = "Instance type for Puppet server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for Puppet server"
  type        = string
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "alb_dns_name" {
  description = "ALB DNS name for nginx upstream configuration"
  type        = string
}

variable "app_repo_url" {
  description = "Git repository URL for the Python Flask app"
  type        = string
  default     = "https://github.com/yourusername/payabl_flask_app.git"
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS record"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Route 53 record name for the Puppet server"
  type        = string
  default     = ""
}

variable "db_secret_arn" {
  description = "Database connection secret ARN from Aurora module"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
