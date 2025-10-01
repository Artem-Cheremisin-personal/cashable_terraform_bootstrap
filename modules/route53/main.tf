terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100.0"
    }
  }
}

# Private Hosted Zone
resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(var.tags, {
    Name = "${var.domain_name} Private Zone"
  })
}

# ALB CNAME record is managed by the ALB module itself

# Database CNAME record for Aurora cluster
resource "aws_route53_record" "database" {
  count   = var.aurora_cluster_endpoint != "" ? 1 : 0
  zone_id = aws_route53_zone.private.zone_id
  name    = "database"
  type    = "CNAME"
  ttl     = 300
  
  records = [var.aurora_cluster_endpoint]
}
