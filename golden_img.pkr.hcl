variable "aws_source_ami" {
  default = "al2023-ami-2023*-x86_64"
}

variable "aws_instance_type" {
  default = "t3.micro"
}

variable "ami_name" {
  default = "deji-blog-ami-1"
}

variable "component" {
  default = "blog"
}


variable "aws_accounts" {
  type = list(string)
  # default = ["651974166650", "055081916963"]
  default = ["186769093804"]
}

variable "ami_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "aws_region" {
  default = "us-east-1"
}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

data "amazon-ami" "source_ami" {
  filters = {
    name = "${var.aws_source_ami}"
  }
  most_recent = true
  owners      = ["336528460023", "amazon"]
  region      = "${var.aws_region}"
}

# locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioners and post-processors on a
# source.

source "amazon-ebs" "startup_ebs" {
  assume_role {
    role_arn     = "arn:aws:iam::186769093804:role/Engineer"
  }
  ami_name       = "${var.ami_name}"
  ami_regions    = "${var.ami_regions}"
  ami_users      = "${var.aws_accounts}"
  snapshot_users = "${var.aws_accounts}"
  encrypt_boot   = false
  instance_type  = "${var.aws_instance_type}" 
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = false
    volume_size           = 20
    volume_type           = "gp2"
  }
  region       = "${var.aws_region}"
  source_ami   = "${data.amazon-ami.source_ami.id}"
  ssh_pty      = true
  ssh_timeout  = "5m"
  ssh_username = "ec2-user"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.startup_ebs"]
  provisioner "shell" {
    script = "./scripts/setup.sh"
  }
}
