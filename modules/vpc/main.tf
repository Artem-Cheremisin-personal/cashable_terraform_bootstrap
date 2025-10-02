terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Local backend - state files stored locally
  backend "local" {}
}

provider "aws" {
  region = var.region
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = { Name = "task-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 12, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

# VPN Load Balancer subnets 
resource "aws_subnet" "vpn_load_balancer" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 12, 1 + count.index) 
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Backend Load Balancer subnets 
resource "aws_subnet" "backend_load_balancer" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 12, 3 + count.index) 
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
# Puppet Management subnets
resource "aws_subnet" "puppet_management" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 12, 24)
  availability_zone = data.aws_availability_zones.available.names[0]
}

# Subnet for Client VPN association
resource "aws_subnet" "vpn_association" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 11, 25) 
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "nginx" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, 10 + count.index) 
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# App subnets 
resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, 20 + count.index) 
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# DB subnets 
resource "aws_subnet" "db" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 12, 5 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# DB subnet group for Aurora
resource "aws_db_subnet_group" "aurora" {
  name       = "cashabl-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "cashabl-db-subnet-group"
  }
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Route table associations
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "app_assoc" {
  count          = 2
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "puppet_assoc" {
  subnet_id      = aws_subnet.puppet_management.id
  route_table_id = aws_route_table.private.id
}

# Route table associations for nginx subnets (use private route table with NAT gateway)
resource "aws_route_table_association" "nginx_assoc" {
  count          = 2
  subnet_id      = aws_subnet.nginx[count.index].id
  route_table_id = aws_route_table.private.id
}

# Route table associations for VPN Load Balancer subnets (make them public for internet-facing ALB)
resource "aws_route_table_association" "vpn_lb_assoc" {
  count          = 2
  subnet_id      = aws_subnet.vpn_load_balancer[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table association for the new VPN subnet
resource "aws_route_table_association" "vpn_assoc" {
  subnet_id      = aws_subnet.vpn_association.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "puppet_server" {
  name_prefix = "puppet-server-"
  description = "Security group for Puppet server"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "puppet-server-sg"
  }
}

resource "aws_security_group" "nginx" {
  name_prefix = "nginx-"
  description = "Security group for NGINX instances"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nginx-sg"
  }
}

resource "aws_security_group" "app" {
  name_prefix = "app-"
  description = "Security group for app instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "app-sg"
  }
}

# NGINX LB Security Group - accepts traffic on port 80 from anywhere
resource "aws_security_group" "nginx_lb" {
  name_prefix = "nginx-lb-"
  description = "Security group for NGINX LB (public traffic)"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nginx-lb-sg"
  }
}

# APP LB Security Group - accepts traffic on port 80 from NGINX subnet only
resource "aws_security_group" "app_lb" {
  name_prefix = "app-lb-"
  description = "Security group for APP LB (NGINX traffic)"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-lb-sg"
  }
}

# Database Security Group - accepts traffic on port 5432 from app instances and VPN clients
resource "aws_security_group" "database" {
  name_prefix = "database-"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-sg"
  }
}

# Security Group Rules - created separately to avoid circular dependencies
resource "aws_security_group_rule" "puppet_server_ingress" {
  type              = "ingress"
  from_port         = 8140
  to_port           = 8140
  protocol          = "tcp"
  cidr_blocks = concat(
    aws_subnet.app[*].cidr_block,
    aws_subnet.nginx[*].cidr_block,
    [aws_subnet.puppet_management.cidr_block]
  )
  security_group_id = aws_security_group.puppet_server.id
}

# Allow all outbound traffic for app instances
resource "aws_security_group_rule" "app_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_from_lb" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_lb.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "nginx_lb_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nginx_lb.id
}

resource "aws_security_group_rule" "nginx_from_lb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nginx_lb.id
  security_group_id        = aws_security_group.nginx.id
}

resource "aws_security_group_rule" "app_lb_from_nginx" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nginx.id
  security_group_id        = aws_security_group.app_lb.id
}

# Database ingress rules
resource "aws_security_group_rule" "database_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.database.id
}

resource "aws_security_group_rule" "database_from_vpn" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpn_client_cidr]  # VPN client CIDR block
  security_group_id = aws_security_group.database.id
}

resource "aws_security_group_rule" "database_from_vpn_subnet" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.vpn_association.cidr_block]  # VPN association subnet
  security_group_id = aws_security_group.database.id
}