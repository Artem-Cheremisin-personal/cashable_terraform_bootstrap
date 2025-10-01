include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/alb"
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id = "mock-vpc-id"
    backend_lb_subnet_ids = ["mock-subnet-1", "mock-subnet-2"]
    app_lb_sg_id = "mock-sg-id"
  }
}

dependency "app" {
  config_path = "../app"
  
  mock_outputs = {
    autoscaling_group_arn = "arn:aws:autoscaling:eu-central-1:123456789012:autoScalingGroup:mock-asg-id:autoScalingGroupName/mock-asg"
    target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/mock-tg/mock-id"
  }
}

dependency "route53" {
  config_path = "../route53"
  
  mock_outputs = {
    hosted_zone_id = "Z123456789"
    alb_record_name = "app-alb"
  }
}

inputs = {
  # ALB Configuration for APP Load Balancer
  name = "cashabl-app-alb"
  internal = true  # Internal ALB for backend communication
  
  # VPC configuration using outputs
  subnets = dependency.vpc.outputs.backend_lb_subnet_ids
  security_groups = [dependency.vpc.outputs.app_lb_sg_id]
  
  # APP ALB Listener configuration
  listeners = [
    {
      port = 80
      protocol = "HTTP"
      default_action = {
        type = "forward"
        target_group_arn = "" # Will be overridden by app_target_group_arn variable
      }
    }
  ]
  
  # VPC ID for target group
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # Target group from APP module
  app_target_group_arn = dependency.app.outputs.target_group_arn
  
  # Route 53 DNS configuration
  route53_zone_id = dependency.route53.outputs.private_zone_id
  route53_record_name = "app-alb"
  
  tags = {
    Application = "cashabl"
  }
}