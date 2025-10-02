provider "aws" {
  region = var.region
}

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
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn

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

# Target Group - created here to avoid circular dependencies
resource "aws_lb_target_group" "this" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = var.target_group_protocol
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(var.tags, {
    Name = var.target_group_name
  })
}

# Route 53 ALIAS record to point to ALB
resource "aws_route53_record" "alb_alias" {
  count   = var.route53_zone_id != "" && var.route53_record_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
