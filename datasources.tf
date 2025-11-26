# Get the selected VPC details
data "aws_vpc" "selected" {
  id = var.vpc_id
}
# Get all subnets in the selected VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}