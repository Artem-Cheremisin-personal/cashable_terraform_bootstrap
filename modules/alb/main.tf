# Application Load Balancer
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets

  enable_deletion_protection = var.enable_deletion_protection

  tags = var.tags
}

# Listeners
resource "aws_lb_listener" "this" {
  for_each = { for idx, listener in var.listeners : idx => listener }

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null

  default_action {
    type             = var.app_target_group_arn != "" ? "forward" : each.value.default_action.type
    target_group_arn = var.app_target_group_arn != "" ? var.app_target_group_arn : (each.value.default_action.type == "forward" ? each.value.default_action.target_group_arn : null)

    dynamic "fixed_response" {
      for_each = each.value.default_action.type == "fixed-response" ? [1] : []
      content {
        content_type = each.value.default_action.fixed_response.content_type
        message_body = each.value.default_action.fixed_response.message_body
        status_code  = each.value.default_action.fixed_response.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.default_action.type == "redirect" ? [1] : []
      content {
        port        = each.value.default_action.redirect.port
        protocol    = each.value.default_action.redirect.protocol
        status_code = each.value.default_action.redirect.status_code
      }
    }
  }

  tags = var.tags
}

# Route 53 CNAME record to point to ALB
resource "aws_route53_record" "alb_cname" {
  count   = var.route53_zone_id != "" && var.route53_record_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.this.dns_name]
}
