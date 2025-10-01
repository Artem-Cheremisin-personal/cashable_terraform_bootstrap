# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values for user data script generation
locals {
  user_data_script = templatefile("${path.module}/templates/app-bootstrap.sh.tpl", {
    puppet_server      = var.puppet_server
    puppet_environment = var.puppet_environment
    puppet_certname    = var.puppet_certname
    db_secret_arn      = var.db_secret_arn
    aws_region         = var.aws_region
  })
}

# Launch Template
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  description   = "Launch template for ${var.name}"
  image_id      = data.aws_ami.this.id
  instance_type = "${var.instance_family}.${var.instance_size}"

  vpc_security_group_ids = var.security_groups
  key_name               = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  user_data = base64encode(local.user_data_script)

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = var.name
    })
  }

  tags = var.tags
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.this.arn]
  health_check_type   = "EC2"  # Changed from ELB to EC2 to prevent killing unhealthy instances
  health_check_grace_period = var.health_check_grace_period

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Target Group
resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
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
    Name = "${var.name}-tg"
  })
}
