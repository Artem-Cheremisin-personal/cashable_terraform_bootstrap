output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets (for VPN, NAT, IGW)"
  value       = [aws_subnet.public.id]
}

output "vpn_lb_subnet_ids" {
  description = "IDs of VPN load balancer subnets"
  value       = aws_subnet.vpn_load_balancer[*].id
}

output "backend_lb_subnet_ids" {
  description = "IDs of Backend load balancer subnets"
  value       = aws_subnet.backend_load_balancer[*].id
}

output "nginx_subnet_ids" {
  description = "IDs of NGINX subnets"
  value       = aws_subnet.nginx[*].id
}

output "app_subnet_ids" {
  description = "IDs of App subnets"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "IDs of DB subnets for Aurora"
  value       = aws_subnet.db[*].id
}

output "db_subnet_cidrs" {
  description = "CIDR blocks of DB subnets"
  value       = aws_subnet.db[*].cidr_block
}

output "db_subnet_group_name" {
  description = "Name of DB subnet group for Aurora"
  value       = aws_db_subnet_group.aurora.name
}

output "puppet_management_subnet_ids" {
  description = "IDs of Puppet management subnets"
  value       = [aws_subnet.puppet_management.id]
}

# Security Group Outputs
output "puppet_server_sg_id" {
  description = "ID of the Puppet server security group"
  value       = aws_security_group.puppet_server.id
}

output "nginx_sg_id" {
  description = "ID of the NGINX instances security group"
  value       = aws_security_group.nginx.id
}

output "app_sg_id" {
  description = "ID of the App instances security group"
  value       = aws_security_group.app.id
}

output "nginx_lb_sg_id" {
  description = "ID of the NGINX Load Balancer security group"
  value       = aws_security_group.nginx_lb.id
}

output "app_lb_sg_id" {
  description = "ID of the App Load Balancer security group"
  value       = aws_security_group.app_lb.id
}

output "database_sg_id" {
  description = "ID of the Database security group"
  value       = aws_security_group.database.id
}

output "vpn_association_subnet_id" {
  description = "The ID of the subnet for the Client VPN association"
  value       = aws_subnet.vpn_association.id
}