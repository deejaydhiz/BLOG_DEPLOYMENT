#### Restores the database from the provided snapshot ####
resource "aws_db_instance" "this" {
  identifier              = "${var.project_name}-db"
  instance_class          = var.rds_instance_properties["instance_class"]
  snapshot_identifier     = var.rds_instance_properties["snapshot_identifier"]
  skip_final_snapshot     = var.rds_instance_properties["skip_final_snapshot"]
  publicly_accessible     = var.rds_instance_properties["publicly_accessible"]
  
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
}

### Create EFS for network file sharing ###
resource "aws_efs_file_system" "this" {
  creation_token    = "${var.project_name}-efs"
  tags = var.tags
}

### Attach EFS to mount targets in each az for high availability ###
resource "aws_efs_mount_target" "subnet_mounts" {
  count           = length(aws_subnet.private_sub)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = aws_subnet.private_sub[count.index].id
  security_groups = [aws_security_group.efs_sg.id]
}

### Application Load Balancer ###
resource "aws_lb" "this" {
  name                = "${var.project_name}-lb"
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.public_sg.id]
  subnets             = [for subnet in aws_subnet.public_sub : subnet.id]
  tags                = var.tags
}

### Target group for load balancer ###
resource "aws_lb_target_group" "this" {
  name     = "${var.project_name}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
}

### LB listener, forwards HTTP requests to target group ###
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

### Create Auto Scaling Group ###
resource "aws_autoscaling_group" "this" {
  vpc_zone_identifier = [ aws_subnet.private_sub[0].id, aws_subnet.private_sub[1].id ]
  name               = "${var.project_name}-asg"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  target_group_arns  = [ aws_lb_target_group.this.arn ]
  
  depends_on = [ aws_db_instance.this ]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "this" {
  name                   = "${var.project_name}-scale-out-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.this.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

### Create keypair ###
resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-kp"
  public_key = file(var.public_key_path)
}

### Resolve Load Balancer DNS to our Route 53 domain ###
resource "aws_route53_record" "this" {
  provider = aws.management
  zone_id  = data.aws_route53_zone.mydns.zone_id
  name     = "${var.project_name}.${data.aws_route53_zone.mydns.name}"
  type     = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  } 
}

# # Create one EC2 instance (Bastion) for debugging
# resource "aws_instance" "bastion" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = var.ec2_properties.instance_type
#   subnet_id     = aws_subnet.public_sub[0].id
#   key_name      = "${var.project_name}-kp"
#   vpc_security_group_ids = [
#     aws_security_group.public_sg.id
#   ]

#   associate_public_ip_address = true

#   user_data = <<EOF
# #!/bin/bash
# yum update -y
# yum install -y httpd
# systemctl enable httpd
# systemctl start httpd
# echo "Web server is running" > /var/www/html/index.html
# EOF

#   tags = {
#     Name = "${var.project_name}-web-server"
#   }
# }