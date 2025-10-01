variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpn_name" {
  description = "Name of the VPN endpoint"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where VPN will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for routing"
  type        = string
}

variable "db_subnet_cidr" {
  description = "Database subnet CIDR block for restricted VPN access"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for VPN association"
  type        = string
}

variable "client_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
  default     = "10.10.0.0/16"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
