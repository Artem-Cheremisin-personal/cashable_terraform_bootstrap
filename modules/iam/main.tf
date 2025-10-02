# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Secrets Manager access
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "${var.role_name}-secrets-manager-policy"
  description = "Policy to allow reading secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_arns
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Aurora RDS IAM authentication
resource "aws_iam_policy" "rds_iam_auth_policy" {
  count       = length(var.rds_resource_arns) > 0 ? 1 : 0
  name        = "${var.role_name}-rds-iam-auth-policy"
  description = "Policy to allow IAM authentication to Aurora RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = var.rds_resource_arns
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for EC2 Describe Tags
resource "aws_iam_policy" "ec2_describe_tags_policy" {
  name        = "${var.role_name}-ec2-describe-tags-policy"
  description = "Policy to allow describing EC2 tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ec2:DescribeTags"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach EC2 Describe Tags policy to role
resource "aws_iam_role_policy_attachment" "ec2_describe_tags_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_describe_tags_policy.arn
}

# Attach Secrets Manager policy to role
resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# Attach RDS IAM auth policy to role
resource "aws_iam_role_policy_attachment" "rds_iam_auth_attachment" {
  count      = length(var.rds_resource_arns) > 0 ? 1 : 0
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.rds_iam_auth_policy[0].arn
}

# Optional: Attach additional managed policies
resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.ec2_role.name
  policy_arn = each.value
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = var.tags
}

# Puppet Server IAM Role (separate from app instances)
resource "aws_iam_role" "puppet_server_role" {
  name = "${var.role_name}-puppet-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach SSM managed policy to puppet server role
resource "aws_iam_role_policy_attachment" "puppet_ssm_attachment" {
  role       = aws_iam_role.puppet_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach EC2 Describe Tags policy to Puppet Server role
resource "aws_iam_role_policy_attachment" "puppet_ec2_describe_tags_attachment" {
  role       = aws_iam_role.puppet_server_role.name
  policy_arn = aws_iam_policy.ec2_describe_tags_policy.arn
}

# Instance Profile for Puppet Server
resource "aws_iam_instance_profile" "puppet_server_profile" {
  name = "${var.role_name}-puppet-server-instance-profile"
  role = aws_iam_role.puppet_server_role.name

  tags = var.tags
}

# Nginx IAM Role (with same permissions as puppet server)
resource "aws_iam_role" "nginx_role" {
  name = "${var.role_name}-nginx"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach SSM managed policy to nginx role
resource "aws_iam_role_policy_attachment" "nginx_ssm_attachment" {
  role       = aws_iam_role.nginx_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach EC2 Describe Tags policy to Nginx role
resource "aws_iam_role_policy_attachment" "nginx_ec2_describe_tags_attachment" {
  role       = aws_iam_role.nginx_role.name
  policy_arn = aws_iam_policy.ec2_describe_tags_policy.arn
}

# Instance Profile for Nginx
resource "aws_iam_instance_profile" "nginx_profile" {
  name = "${var.role_name}-nginx-instance-profile"
  role = aws_iam_role.nginx_role.name

  tags = var.tags
}
