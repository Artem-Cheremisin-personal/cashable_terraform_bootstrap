output "puppet_server_private_ip" {
  description = "Private IP of the Puppet server"
  value       = aws_instance.puppet_server.private_ip
}
