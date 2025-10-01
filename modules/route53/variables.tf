variable "vpc_id" {
  description = "VPC ID to associate with the private hosted zone"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the private hosted zone"
  type        = string
  default     = "internal.cashabl.local"
}

variable "alb_cname" {
  description = "CNAME record for ALB"
  type        = string
  default     = "app-alb"
}

variable "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to Route 53 resources"
  type        = map(string)
  default     = {}
}
