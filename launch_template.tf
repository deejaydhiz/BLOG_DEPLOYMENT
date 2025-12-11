resource "aws_launch_template" "this" {
  name                    = "${var.project_name}-web_template"
  image_id                = data.aws_ami.amazon_linux.id
  instance_type           = var.ec2_properties["instance_type"]
  key_name                = "${var.project_name}-kp"
  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  
  iam_instance_profile {
    name = var.ec2_properties["iam_instance_profile"]
  }

  block_device_mappings {
    device_name = "/dev/xvda"   
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = false
      throughput            = 125
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-server"
    }
  }
  user_data = filebase64("${path.module}/scripts/blogbootstrap.sh")
}