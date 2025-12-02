variable "aws_region" {
  description = "This is the AWS region to build the resources"
  type = string
  default = "us-east-1"
}

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
  description = "Mapping of environment names to AWS account IDs"
  type        = map(string)
  default = {
    dev  = "186769093804"
    prod = "807867956627"
  }
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Name        = "blog-WP"
    stackTeam   = "stackcloud14"
    OwnerEmail  = "stackawsdeij@gmail.com"
    Environment = "dev"
    Project     = "blog-deployment"
    CostCenter  = "cc1234"
    Application = "blog-website"
  }
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = true
}

variable "sg_name" {
  description = "The name of the security group for the blog deployment"
  type        = string
  default     = "blog_SG"
}

variable "security_group_rules" {
  description = "A list of security group rules"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from anywhere"
    },
        {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere"
    },
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow SSH from VPC only"
    },
    {
      type        = "ingress"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow RDS access from VPC"
    },
    {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow EFS access from VPC"
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

# variable "db_name" {  
#   description = "The name of the database to create"
#   type        = string
#   default     = "blog_db"
# }

# variable "db_username" {
#   description = "The master username at time of database creation"
#   type        = string
#   default     = "admin"
# }

# variable "db_password" {
#   description = "The master password for the database, must be at least 8 characters"
#   type        = string
#   sensitive   = true

#   validation {
#     condition     = length(var.db_password) >= 8
#     error_message = "The database password must be at least 8 characters long."
#   }
# }

variable "ec2_properties" {
  description = "A map of EC2 instance properties"
  type        = map(string)
  default = {
    name                    = "blog-web"
    instance_type           = "t2.micro"
    ami_id                  = "ami-0cae6d6fe6048ca2c"
    key_name                = "blog-kp"
    iam_instance_profile    = "IAM_instance_profile"
  }
}

variable "rds_instance_properties" {
  description = "A map of RDS instance properties"
  type        = map(string)
  default = {
    identifier          = "blog-db"
    username            = "admin"
    instance_class      = "db.t4g.micro"
    allocated_storage   = "20"
    engine              = "mysql"
    engine_version      = "8.4"
    publicly_accessible = "true"
    snapshot_identifier = "deijwordpressdb"
    skip_final_snapshot = "true"
  }
} 