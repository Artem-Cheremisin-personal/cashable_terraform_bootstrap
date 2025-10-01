variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager secret ARNs that the role can access"
  type        = list(string)
  default     = ["*"]
}

variable "rds_resource_arns" {
  description = "List of RDS resource ARNs for IAM authentication"
  type        = list(string)
  default     = []
}

variable "additional_policy_arns" {
  description = "List of additional policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
