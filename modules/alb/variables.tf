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
  description = "ARN of the app target group to forward traffic to"
  type        = string
  default     = ""
}
