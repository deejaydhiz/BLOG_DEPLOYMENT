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
