# Puppet Server Instance
resource "aws_instance" "puppet_server" {
  ami           = data.aws_ami.this.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_groups
  iam_instance_profile   = var.iam_instance_profile

  user_data = base64encode(templatefile("${path.module}/templates/puppet-server-bootstrap.sh.tpl", {
    alb_dns_name = var.alb_dns_name
    app_repo_url = var.app_repo_url
    db_secret_arn = var.db_secret_arn
    site_pp_content = file("${path.module}/files/site.pp")
  }))

  tags = merge(var.tags, {
    Name = "${var.name}-puppet-server"
  })
}

# Route 53 A record for Puppet server
resource "aws_route53_record" "puppet_server" {
  count   = var.route53_zone_id != "" && var.route53_record_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.puppet_server.private_ip]
}

# Data source for AL2023 AMI
data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
