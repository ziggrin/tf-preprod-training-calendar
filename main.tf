##########
### Services in this configuration:
### preprod-training-calendar-api
### preprod-training-calendar-frontend
### CTRL+D -> preprod_training_calendar and preprod-training-calendar
##########

data "aws_caller_identity" "current" {}

locals {
  preprod_training_calendar_log_group_name = "/ecs/preprod-training-calendar"
  tags = {
    Environment = "preprod"
    Project     = "omega"
    IaaC        = "terraform"
  }
}


##############
## ECS cluster preprod-training-calendar
##############
module "preprod_training_calendar_ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.12.0"
  
  cluster_name = "preprod-training-calendar"
  
  cluster_settings = {
    name = "containerInsights"
    value = "disabled"
  } 
  create_cloudwatch_log_group = true
  cloudwatch_log_group_name   = local.preprod_training_calendar_log_group_name
  
  tags = merge(local.tags, {
    Component = "ecs-cluster"
  })
}

##########
## RDS for preprod-training-calendar
##########
module "rds_preprod_training_calendar" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "preprod-training-calendar"

  engine            = "postgres"
  engine_version    = "17.3" 
  instance_class    = "db.t4g.micro" 
  allocated_storage = 10 
  max_allocated_storage = 100 
  storage_encrypted = true
  multi_az = false

  db_name  = "preprod_training_calendar"
  username = var.db_username
  password = var.db_password
  port     = "5432"
  manage_master_user_password = false

  vpc_security_group_ids = var.db_sg
  maintenance_window = "Mon:00:00-Mon:01:00"
  backup_window      = "01:00-01:30"

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = var.intra_subnets

  # DB parameter group
  family = "postgres17"

  # DB option group
  major_engine_version = "17.3"

  # Database Deletion Protection
  deletion_protection = true

  tags = merge(local.tags, {
    Component = "rds"
  })
}
