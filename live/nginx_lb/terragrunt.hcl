include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/alb"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "nginx" {
  config_path = "../nginx"
}

inputs = {
  # ALB Configuration for NGINX Load Balancer
  name = "cashabl-nginx-alb"
  
  # VPC configuration using outputs
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # NGINX ALB Listener configuration
  listeners = [
    {
      name = "nginx-lb"
      port = 80
      protocol = "HTTP"
      subnet_ids = dependency.vpc.outputs.vpn_lb_subnet_ids
      security_group_ids = [dependency.vpc.outputs.nginx_lb_sg_id]
      target_group = {
        name = "nginx-tg"
        port = 80
        protocol = "HTTP"
        health_check_path = "/"
        health_check_port = "80"
        health_check_protocol = "HTTP"
      }
    }
  ]
  
  # Target group will be attached to NGINX ASG
  nginx_asg_arn = dependency.nginx.outputs.autoscaling_group_arn
  
  tags = {
    Application = "cashabl"
  }
}
