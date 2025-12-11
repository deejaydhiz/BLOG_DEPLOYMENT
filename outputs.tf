# Output the public IP address
output "my_public_ip_address" {
  value = chomp(data.http.my_public_ip.response_body)
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_sub[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_sub[*].id
}

output "public_security_group_id" {
  value = aws_security_group.public_sg.id
}

output "app_security_group_id" {
  value = aws_security_group.app_sg.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}

output "efs_security_group_id" {
  value = aws_security_group.efs_sg.id
}

output "efs_id" {
  value = aws_efs_file_system.this.id
}

# output "bastion_server_dns" {
#   value = aws_instance.bastion.public_dns
# }
