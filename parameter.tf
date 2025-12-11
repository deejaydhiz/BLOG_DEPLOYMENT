### Create parameters in Parameter store for use in blog user data ###
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "${var.project_name}db-host"
  type  = "String"
  value = aws_db_instance.this.address
}

resource "aws_ssm_parameter" "efs" {
  name  = "${var.project_name}db-EFS"
  type  = "String"
  value = aws_efs_file_system.this.dns_name
}

resource "aws_ssm_parameter" "dns" {
  name  = "${var.project_name}db-DNS"
  type  = "String"
  value = aws_route53_record.this.name
}
