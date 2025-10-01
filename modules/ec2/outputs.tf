output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "target_group_arn" {
  description = "ARN of the Load Balancer Target Group"
  value       = aws_lb_target_group.this.arn
}
