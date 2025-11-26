output "security_group_id" {
  value = aws_security_group.blog_sg.id
}

output "master_user" {
  value = var.db_username
}

output "master_secret" {
  value = aws_db_instance.blog_db.master_user_secret
}

output "db_endpoint" {
  value = aws_db_instance.blog_db.endpoint
}

output "efs_id" {
  value = aws_efs_file_system.blog_efs.id
}