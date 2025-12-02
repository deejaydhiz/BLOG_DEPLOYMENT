# Get the selected VPC details
data "aws_vpc" "selected" {
  default = true
}
# Get all subnets in the selected VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Get Route 53 hosted zone using its name
data "aws_route53_zone" "blog_dns" {
  provider     = aws.management
  name         = "deji-stack.com"
  private_zone = false
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}