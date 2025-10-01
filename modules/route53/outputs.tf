output "private_zone_id" {
  description = "Route 53 private hosted zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "alb_dns_name" {
  description = "ALB DNS name in private zone"
  value       = "${var.alb_cname}.${var.domain_name}"
}
