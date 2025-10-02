terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  
  # Local backend - state files stored locally
  backend "local" {}
}

provider "aws" {
  region = var.region
}

# Generate self-signed certificates for Client VPN
# CA Certificate
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "cashabl-vpn-ca"
    organization = "Cashabl"
  }

  validity_period_hours = 8760 # 1 year

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

# Server Certificate
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "cashabl-vpn-server"
  }

  dns_names = ["vpn.internal"]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Client Certificate
resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name = "cashabl-vpn-client"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Upload certificates to ACM
resource "aws_acm_certificate" "server" {
  certificate_body  = tls_locally_signed_cert.server.cert_pem
  private_key       = tls_private_key.server.private_key_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate" "client" {
  certificate_body  = tls_locally_signed_cert.client.cert_pem
  private_key       = tls_private_key.client.private_key_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# CloudWatch Log Group for VPN connection logs
resource "aws_cloudwatch_log_group" "vpn" {
  name              = "/aws/clientvpn/${var.vpn_name}"
  retention_in_days = 7

  tags = var.tags
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "vpn" {
  name           = "vpn-connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

# Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "Client VPN for ${var.vpn_name}"
  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = var.client_cidr
  dns_servers            = [var.vpc_dns_resolver, "8.8.8.8", "8.8.4.4", "1.1.1.1"]
  split_tunnel           = true

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }

  tags = merge(var.tags, {
    Name = var.vpn_name
  })
}

# Associate VPN endpoint with public subnet
resource "aws_ec2_client_vpn_network_association" "this" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_id
}

# Authorization rule to allow access to DATABASE subnets only
resource "aws_ec2_client_vpn_authorization_rule" "db_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.db_subnet_cidr
  authorize_all_groups   = true
  description            = "Allow access to database subnets only"
}

# Authorization rule to allow internet access
resource "aws_ec2_client_vpn_authorization_rule" "internet_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  description            = "Allow internet access through VPN"
}

# Route to DATABASE subnets only (not entire VPC)
resource "aws_ec2_client_vpn_route" "db_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = var.db_subnet_cidr
  target_vpc_subnet_id   = var.subnet_id
  description            = "Route to database subnets only"

  depends_on = [aws_ec2_client_vpn_network_association.this]
}

# Route for internet access through VPN subnet
resource "aws_ec2_client_vpn_route" "internet_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = var.subnet_id
  description            = "Route internet traffic through VPN subnet"

  depends_on = [aws_ec2_client_vpn_network_association.this]
}