#### Restores the database from the provided snapshot ####
resource "aws_db_instance" "blog_db" {
  identifier              = var.rds_instance_properties.identifier
  instance_class          = var.rds_instance_properties.instance_class
  snapshot_identifier     = var.rds_instance_properties.snapshot_identifier
  skip_final_snapshot     = var.rds_instance_properties.skip_final_snapshot
  vpc_security_group_ids  = [aws_security_group.blog_sg.id]
  publicly_accessible     = var.rds_instance_properties.publicly_accessible
}

### Create EFS for for blog network file sharing ###
resource "aws_efs_file_system" "blog_efs" {
  creation_token = "blog-web"
  encrypted      = true
  tags           = var.tags
}

## Create mount targets for each subnet in the selected VPC ##
resource "aws_efs_mount_target" "subnet_mounts" {
  for_each = toset(data.aws_subnets.default.ids)
  file_system_id  = aws_efs_file_system.blog_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.blog_sg.id]
}

### Application Load Balancer ###

resource "aws_lb" "blog_lb" {
  name               = "blog-lb-tf"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.blog_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = var.tags
}

### Target group for load balancer ###

resource "aws_lb_target_group" "blog_tg" {
  name     = "tf-blog-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
}

### LB listener, forwards HTTP requests to target group ###

resource "aws_lb_listener" "blog_front-end" {
  load_balancer_arn = aws_lb.blog_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog_tg.arn
  }
}

### Resolve Load Balancer DNS to our Route 53 domain (blog.deji-stack.com) ###

resource "aws_route53_record" "blog_dns" {
  provider = aws.management
  zone_id  = data.aws_route53_zone.blog_dns.zone_id
  name     = "blog.${data.aws_route53_zone.blog_dns.name}"
  type     = "A"

  alias {
    name                   = aws_lb.blog_lb.dns_name
    zone_id                = aws_lb.blog_lb.zone_id
    evaluate_target_health = true
  }
}

### Create key pair ###

resource "aws_key_pair" "blog_kp" {
  key_name   = "blog-kp"
  public_key = file("~/.ssh/blog-kp.pub")
}

### Create Auto Scaling Group ###

resource "aws_autoscaling_policy" "blog_scaling_policy" {
  name                   = "blog-scale-out-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.blog_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

resource "aws_autoscaling_group" "blog_asg" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  name                = "blog-asg-tf"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.blog_tg.arn]
  depends_on          = [ aws_db_instance.blog_db, aws_efs_file_system.blog_efs ]

  launch_template {
    id      = aws_launch_template.blog_template.id
    version = "$Latest"
  }
}
