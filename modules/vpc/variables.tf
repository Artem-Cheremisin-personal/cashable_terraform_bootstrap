variable "region" {
  type        = string
  description = "AWS region to create resources in"
}

variable "cidr" {
  type        = string
  description = "CIDR block for the VPC"
}