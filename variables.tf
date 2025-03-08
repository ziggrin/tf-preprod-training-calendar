variable "aws_account" {
  description = "Name of the AWS Account to connect to"
  type        = string
  default = "main-01"
}

variable "aws_account_id" {
  description = "ID of the AWS Account"
  type        = string
  default = "241533118713"
}

variable "aws_region" {
  description = "AWS region to connect to"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Select instance environment PROD_PILOT | PROD_STAGING | PRODUCTION | PREPROD_PILOT | PREPROD"
  type        = string
  default = "PREPROD"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default = "vpc-0a3ae58a47b87c64e"
}

variable "vpc_cidr_block_ipv4" {
  description = "VPC CIDR block"
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets for ALB, EC2(ecs)"
  type = list
  default = [ "subnet-036216a2ab8ca1411", "subnet-08a065b009661e6d6" ]
}

variable "intra_subnets" {
  description = "Intra subnets for RDS"
  type = list
  default = [ "subnet-0f8dee0d865e1f183", "subnet-06bd09c19dd0a28a2" ]
}

variable "lb_listener_arn" {
  description = "HTTPS listener arn -> hosting-alb"
  type        = string
  default = "arn:aws:elasticloadbalancing:eu-north-1:241533118713:listener/app/preprod-omega/e5ed61ebdcefbd87/e88f90c0c7914486"
}

variable "db_sg" {
  description = "RDS security groups"
  type        = list
  default = ["sg-0e19ee34771259038"]
}


####################
## terraform.auto.tfvars // enterprise vault
####################
variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}
