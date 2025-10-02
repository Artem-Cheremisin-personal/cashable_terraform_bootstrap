include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/alb"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "route53" {
  config_path = "../route53"
}

inputs = {
  # ALB Configuration for App Load Balancer
  name = "cashabl-app-alb"
  
  # AWS region
  region = "eu-central-1"
  
  # Make it internal (for backend services)
  internal = true
  
  # Use backend load balancer subnets (internal)
  subnets = dependency.vpc.outputs.backend_lb_subnet_ids
  
  # Use app load balancer security group
  security_groups = [dependency.vpc.outputs.app_lb_sg_id]
  
  # VPC configuration
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # Target group configuration - created by ALB module
  target_group_name = "cashabl-app-tg"
  target_group_port = 5000
  target_group_protocol = "HTTP"
  
  # Health check configuration
  health_check_healthy_threshold = 2
  health_check_interval = 30
  health_check_matcher = "200"
  health_check_path = "/"
  health_check_timeout = 5
  health_check_unhealthy_threshold = 5
  
  # Configure listener to forward to app target group
  listeners = [
    {
      port = 80
      protocol = "HTTP"
      default_action = {
        type = "forward"
      }
    }
  ]
  
  # Route53 configuration
  route53_zone_id = dependency.route53.outputs.private_zone_id
  route53_record_name = "app-alb"
  
  tags = {
    Application = "cashabl"
    Name = "cashabl-app-alb"
  }
}