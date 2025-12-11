variable "env" {
  description = "The environment for the deployment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "uat", "prod"], var.env)
    error_message = "The env variable must be one of the following: dev, test, uat, prod."
  }
}

variable "accounts" {
    type = map(string)
    default = {
        dev     = "186769093804"
        uat     = "961424819918"
        mgmt    = "651974166650"
    }
}

variable "rds_instance_properties" {
  description = "A map of RDS instance properties"
  type        = map(string)
  default = {
    username            = "admin"
    instance_class      = "db.t4g.micro"
    publicly_accessible = false
    snapshot_identifier = "deijwordpressdb"
    skip_final_snapshot = true
  }
} 

variable "aws_region" {
  description = "This is the AWS region to build the resources"
  type = string
  default = "us-east-1"
}

variable project_name {
  description = "The project name"
  type = string
  default = "blog"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Name        = "blog-deployment"
    stackTeam   = "stackcloud14"
    OwnerEmail  = "stackawsdeij@gmail.com"
    Environment = "dev"
    Project     = "blog-web-deployment"
    CostCenter  = "cc1234"
    Application = "blog-website"
  }
}

variable "ec2_properties" {
  description = "A map of EC2 instance properties"
  type        = map(string)
  default = {
    name                    = "blog-web"
    instance_type           = "t3.micro"
    ami_id                  = "ami-08d7aabbb50c2c24e"
    key_name                = "blog-kp"
    iam_instance_profile    = "IAM_instance_profile"
  }
}

variable "public_key_path" {
  description = "Path to the public key file (.pub) used to create the AWS key pair."
  type        = string
  default     = "./blog-kp.pub"
}

variable "efs_properties" {
  description = "A map of EFS properties"
  type        = map(string)
  default = {
    creation_token = "blog-EFS"
    encrypted      = true
  }
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr" {
  type    = list(string)
  default = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "private_subnet_cidr" {
  type    = list(string)
  default = ["172.16.11.0/24", "172.16.12.0/24"]
}

variable "ami_name" {
  default = "deji-blog-ami"
}
