output "aurora_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "database_connection_secret_arn" {
  description = "ARN of the complete database connection secret"
  value       = aws_secretsmanager_secret.database_connection.arn
}

output "rds_iam_auth_resource_arn" {
  description = "ARN for RDS IAM database authentication"
  value       = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.cluster_identifier}/*"
}
