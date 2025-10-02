variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal or internet-facing"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "List of security group IDs to assign to the load balancer"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "listeners" {
  description = "List of listeners configuration"
  type = list(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    default_action = object({
      type             = string
      target_group_arn = optional(string)
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
      }))
    })
  }))
  default = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS record"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Route 53 record name for the ALB"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for target group"
  type        = string
  default     = ""
}

variable "app_target_group_arn" {
  description = "ARN of the target group to use for the default action"
  type        = string
  default     = ""
}

# Target Group Configuration
variable "target_group_name" {
  description = "Name of the target group"
  type        = string
}

variable "target_group_port" {
  description = "Port for the target group"
  type        = number
}

variable "target_group_protocol" {
  description = "Protocol for the target group"
  type        = string
  default     = "HTTP"
}

# Health Check Configuration
variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "health_check_matcher" {
  description = "HTTP response codes to consider healthy"
  type        = string
  default     = "200"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_timeout" {
  description = "Health check timeout"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 5
}

variable "target_groups" {
  description = "Map of target groups to create"
  type = map(object({
    name                            = string
    port                            = number
    protocol                        = string
    health_check_healthy_threshold  = number
    health_check_interval           = number
    health_check_matcher            = string
    health_check_path               = string
    health_check_timeout            = number
    health_check_unhealthy_threshold = number
  }))
  default = {}
}


