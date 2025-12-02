# Create the security group for the blog deployment
 resource "aws_security_group" "blog_sg" {
  name        = var.sg_name
  description = "This is the security group for the blog deployment"
  vpc_id      = data.aws_vpc.selected.id
  tags        = var.tags
}

resource "aws_security_group_rule" "sg_rules" {

  # Convert the list into a map where the key is the description of the rule
  for_each = { for rule in var.security_group_rules : rule.description => rule }
  security_group_id = aws_security_group.blog_sg.id
  # Access individual attributes of the current rule using 'each.value'
  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  description = each.value.description
}

resource "aws_security_group_rule" "ssh_rule" {
  for_each = { for rule in var.security_group_rules : rule.description => rule if rule.description == "Allow SSH from VPC only" }
  security_group_id = aws_security_group.blog_sg.id
  # Access individual attributes of the current rule using 'each.value'
  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  cidr_blocks = ["${chomp(data.http.my_public_ip.response_body)}/32"]
  description = each.value.description
}

resource "aws_security_group_rule" "rds_rule" {
  for_each = { for rule in var.security_group_rules : rule.description => rule if rule.description == "Allow RDS access from VPC" }
  security_group_id = aws_security_group.blog_sg.id
  # Access individual attributes of the current rule using 'each.value'
  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  cidr_blocks = [data.aws_vpc.selected.cidr_block]
  description = each.value.description
}

resource "aws_security_group_rule" "efs_rule" {
  for_each = { for rule in var.security_group_rules : rule.description => rule if rule.description == "Allow EFS access from VPC" }
  security_group_id = aws_security_group.blog_sg.id
  # Access individual attributes of the current rule using 'each.value'
  type        = each.value.type
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  cidr_blocks = [data.aws_vpc.selected.cidr_block]
  description = each.value.description
}