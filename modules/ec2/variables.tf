variable "name" {
  description = "Name prefix for EC2 resources"
  type        = string
}

variable "instance_family" {
  description = "EC2 instance family (e.g., t3, m5, c5)"
  type        = string
  default     = "t3"
}

variable "instance_size" {
  description = "EC2 instance size (e.g., micro, small, medium, large)"
  type        = string
  default     = "micro"
}

variable "subnets" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "target_group_arns" {
  description = "List of target group ARNs to associate with the ASG"
  type        = list(string)
  default     = []
}



# Auto Scaling Group Configuration
variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

# Optional Configuration
variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "puppet_enabled" {
  description = "Enable Puppet agent installation and configuration"
  type        = bool
  default     = false
}

variable "puppet_server" {
  description = "Puppet server hostname or IP"
  type        = string
  default     = null
}

variable "puppet_environment" {
  description = "Puppet environment"
  type        = string
  default     = "production"
}

variable "puppet_certname" {
  description = "Puppet certificate name (defaults to instance hostname)"
  type        = string
  default     = null
}

variable "health_check_grace_period" {
  description = "Health check grace period for ASG"
  type        = number
  default     = 300
}

# Target Group Configuration
variable "target_group_port" {
  description = "Port for the target group"
  type        = number
  default     = 5000
}

variable "target_group_protocol" {
  description = "Protocol for the target group"
  type        = string
  default     = "HTTP"
}

# Health Check Configuration
variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks before healthy"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30
}

variable "health_check_matcher" {
  description = "HTTP codes for healthy response"
  type        = string
  default     = "200"
}

variable "health_check_path" {
  description = "Path for health check requests"
  type        = string
  default     = "/"
}

variable "health_check_timeout" {
  description = "Timeout for health check requests (seconds)"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks before unhealthy"
  type        = number
  default     = 2
}

variable "db_secret_arn" {
  description = "The ARN of the secret containing the database credentials"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region for environment variables"
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
