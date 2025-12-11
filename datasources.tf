# Get Route 53 hosted zone using its name
data "aws_route53_zone" "mydns" {
  provider     = aws.management
  name         = "deji-stack.com"
  private_zone = false
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_ami" "amazon_linux" {
  owners      = ["186769093804"]
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}
