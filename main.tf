# This creates the RDS for the blog deployment
resource "aws_db_instance" "blog_db" {
  allocated_storage       = 20
  db_name                 = var.db_name
  engine                  = "mysql"
  engine_version          = "8.4"
  instance_class          = "db.t4g.micro"
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.blog_sg.id]
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
