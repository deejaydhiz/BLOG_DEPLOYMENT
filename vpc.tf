# Create a VPC with 2 private subnets and 2 public subnets 
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

# Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-igw" }
}

# Creating public subnet
resource "aws_subnet" "public_sub" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true 
  tags = { 
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}

# Creating route table for public subnet
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public-rt-assoc" {
  count          = length(aws_subnet.public_sub)
  subnet_id      = aws_subnet.public_sub[count.index].id
  route_table_id = aws_route_table.public-rt.id
} 

# resource "aws_route" "public-rt-route" {
#   route_table_id         = aws_route_table.public-rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }

# Create the elastic IP for the nat gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-nat-eip" }
  depends_on = [ aws_internet_gateway.igw ]
}

# Create NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_sub[0].id
  depends_on    = [aws_internet_gateway.igw]
  tags = { Name = "${var.project_name}-nat" }
}

# Creating private subnets
resource "aws_subnet" "private_sub" {
  count                   = length(var.private_subnet_cidr)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  tags = { 
    Name = "${var.project_name}-private-sub-${count.index + 1}"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

# resource "aws_route" "private-rt-route" {
#   route_table_id         = aws_route_table.private-rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.this.id
# }

# Associate private route
resource "aws_route_table_association" "private-rt-assoc" {
  count          = length(aws_subnet.private_sub)
  subnet_id      = aws_subnet.private_sub[count.index].id
  route_table_id = aws_route_table.private-rt.id
}

# RDS subnet group (for future RDS instances)
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private_sub[*].id
  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# resource "aws_network_acl" "this" {
#   vpc_id = aws_vpc.this.id
#   tags   = var.tags
# }

# resource "aws_network_acl_rule" "allow_efs_inbound" {
#   network_acl_id = aws_network_acl.this.id
#   rule_number    = 100
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.myvpc.cidr_block
#   from_port      = 2049
#   to_port        = 2049
# } 

# resource "aws_network_acl_rule" "allow_ssh_inbound" {
#   network_acl_id = aws_network_acl.this.id
#   rule_number    = 200
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "${chomp(data.http.my_public_ip.response_body)}/32"
#   from_port      = 22
#   to_port        = 22
# }

# resource "aws_network_acl_rule" "allow_rds_inbound" {
#   network_acl_id = aws_network_acl.this.id
#   rule_number    = 150
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.myvpc.cidr_block
#   from_port      = 3306
#   to_port        = 3306
# }

# resource "aws_network_acl_rule" "allow_https_inbound" {
#   network_acl_id = aws_network_acl.this.id
#   rule_number    = 50
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.myvpc.cidr_block
#   from_port      = 443
#   to_port        = 443 
# }

# resource "aws_network_acl_rule" "allow_http_inbound" {
#   network_acl_id = aws_network_acl.this.id
#   rule_number    = 25
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.myvpc.cidr_block
#   from_port      = 80
#   to_port        = 80 
# }

# resource "aws_network_acl_rule" "allow_all_outbound" {
#   network_acl_id = aws_network_acl.this.id
#   rule_number    = 200
#   egress         = true
#   protocol       = "-1"
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.myvpc.cidr_block
#   from_port      = 0  
#   to_port        = 65535
# }