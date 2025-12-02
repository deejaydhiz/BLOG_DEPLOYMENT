resource "aws_launch_template" "blog_template" {
  name = var.ec2_properties.name
  image_id = var.ec2_properties.ami_id
  instance_type = var.ec2_properties.instance_type
  key_name = var.ec2_properties.key_name
  vpc_security_group_ids = [aws_security_group.blog_sg.id]
  iam_instance_profile {
    name = var.ec2_properties.iam_instance_profile
  }
  depends_on = [ aws_db_instance.blog_db ]
  tag_specifications {
    resource_type = "instance"
    tags = var.tags
  }
  user_data = filebase64("${path.module}/blogbootstrap.sh")
}
