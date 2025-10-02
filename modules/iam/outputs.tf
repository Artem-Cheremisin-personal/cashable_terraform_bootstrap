output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "puppet_server_instance_profile_name" {
  description = "Name of the puppet server instance profile"
  value       = aws_iam_instance_profile.puppet_server_profile.name
}

output "nginx_instance_profile_name" {
  description = "Name of the nginx instance profile"
  value       = aws_iam_instance_profile.nginx_profile.name
}
