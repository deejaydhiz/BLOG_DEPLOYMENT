output "security_group_id" {
  value = aws_security_group.blog_sg.id
}

output "rds_endpoint" {
  value = aws_db_instance.blog_db.address
}

output "efs_dns" {
  value = aws_efs_file_system.blog_efs.dns_name
}

output "load_balancer_dns" {
  value = aws_lb.blog_lb.dns_name
}

output "blog_url" {
  value = aws_route53_record.blog_dns.fqdn
}