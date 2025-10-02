variable "region" {
  type        = string
  description = "AWS region to create resources in"
}

variable "cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpn_client_cidr" {
  description = "CIDR block for the VPN client"
  type        = string
  default     = "10.10.0.0/16"
}