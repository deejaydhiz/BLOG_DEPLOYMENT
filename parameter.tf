### Create parameters in Parameter store for use in blog user data ###
resource "aws_ssm_parameter" "blogdb_endpoint" {
  name  = "blogdb-host"
  type  = "String"
  value = aws_db_instance.blog_db.address
}

resource "aws_ssm_parameter" "blog_efs" {
  name  = "blogdb-EFS"
  type  = "String"
  value = aws_efs_file_system.blog_efs.dns_name
}

resource "aws_ssm_parameter" "blog_dns" {
  name  = "blog-DNS"
  type  = "String"
  value = aws_route53_record.blog_dns.name
}


