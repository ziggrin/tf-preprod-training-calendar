locals {
  preprod_training_calendar_frontend_ssm_service = "training-calendar-frontend/preprod"
  preprod_training_calendar_frontend_ecr_namespace = "training-calendar-frontend"
  preprod_training_calendar_frontend_log_group_name = "/ecs/preprod-training-calendar" # loggin into cluster log group
  tags_training_calendar_frontend = {
    Environment = "prepreprod"
    Project     = "omega"
    IaaC        = "terraform"
  }
}

##########
## ECR - docker registry
##########
module "ecr_preprod_training_calendar_frontend_nginx" {
  source  = "cloudposse/ecr/aws"
  version = "0.42.1"
  image_tag_mutability = "MUTABLE"
  name = "nginx"
  stage = "preprod"
  namespace = "${local.preprod_training_calendar_frontend_ecr_namespace}"
  max_image_count = 2
  tags = local.tags_training_calendar_frontend
}


##########
## CI user
##########
module "preprod_training_calendar_iam_user_CI_frontend" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 5.52.2"

  name = "githubCI-preprod-training-calendar-frontend-aws"
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

## CI user - ECR policy
data "template_file" "preprod_training_calendar_frontend_ecr_access_policy" {
  template = "${file("${path.module}/templates/ecr/ecr-access-policy.json")}"
  vars = {
    repository_name = "${local.preprod_training_calendar_frontend_ecr_namespace}-*"
    aws_account_id = var.aws_account_id
    aws_region = var.aws_region
  }
}

module "preprod_training_calendar_frontend_iam_policy_CI_ecr_access_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.52.2"

  name        = "CI-ecr-${local.preprod_training_calendar_frontend_ecr_namespace}-access-policy"
  path        = "/"
  description = "CI access to ECR"
  policy = data.template_file.preprod_training_calendar_frontend_ecr_access_policy.rendered
}

resource "aws_iam_user_policy_attachment" "preprod_training_calendar_frontend_CI_ecr_policy_attachment" {
  user       = module.preprod_training_calendar_iam_user_CI_frontend.iam_user_name
  policy_arn = module.preprod_training_calendar_frontend_iam_policy_CI_ecr_access_policy.arn
}

## CI user - ECS policy
data "template_file" "preprod_training_calendar_frontend_ecs_update_service_policy" {
  template = "${file("${path.module}/templates/preprod-training-calendar-ecs/policy.json")}"
  vars = {
    aws_account_id = var.aws_account_id
    ecs_task_role_name = aws_iam_role.preprod_training_calendar_frontend_ecs_task_role.name
  }
}

module "preprod_training_calendar_frontend_iam_policy_CI_ecs_update_service" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.52.2"

  name        = "CI-ecs-${module.ecr_preprod_training_calendar_frontend_nginx.repository_name}-update-service"
  path        = "/"
  description = "CI access to EcsUpdateService"
  policy = data.template_file.preprod_training_calendar_frontend_ecs_update_service_policy.rendered
}

resource "aws_iam_user_policy_attachment" "preprod_training_calendar_frontend_CI_ecs_update_service_policy_attachment" {
  user       = module.preprod_training_calendar_iam_user_CI_frontend.iam_user_name
  policy_arn = module.preprod_training_calendar_frontend_iam_policy_CI_ecs_update_service.arn
}


##########
## ECS task role
##########
resource "aws_iam_role" "preprod_training_calendar_frontend_ecs_task_role" {
  name = "preprod-training-calendar-frontend-task-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "preprod_training_calendar_frontend_secrets_access_policy" {
  name = "preprod-training-calendar-frontend-secrets-access-policy" 
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "ssm:GetParametersByPath",
        "ssm:GetParameters",
        "ssm:DescribeParameters"
      ],
      "Resource": [
        "arn:aws:ssm:${var.aws_region}:*:parameter/${local.preprod_training_calendar_frontend_ssm_service}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "preprod_training_calendar_frontend_policy_attachment" {
  role       = aws_iam_role.preprod_training_calendar_frontend_ecs_task_role.name
  policy_arn = aws_iam_policy.preprod_training_calendar_frontend_secrets_access_policy.arn
}


####################
## Load balancer Target Group
####################
resource "aws_lb_target_group" "preprod_training_calendar_frontend" {
  name     = "preprod-training-calendar-front"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener_rule" "preprod_training_calendar_frontend" {
  listener_arn = var.lb_listener_arn
  priority = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.preprod_training_calendar_frontend.arn
  }

  condition {
    host_header {
      values = ["app.omega-next.online"]
    }
  }
}


##########
## ECS Task Definition
##########
resource "aws_ecs_task_definition" "preprod_training_calendar_frontend" {
  family                   = "preprod-training-calendar-front"  # NAME CANNOT BE LONGER THEN 32 CHARACTERS
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "128"

  task_role_arn        = aws_iam_role.preprod_training_calendar_frontend_ecs_task_role.arn
  execution_role_arn   = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
  

  # Containers
  container_definitions = jsonencode([
    {
      name      = "react"
      image     = "${module.ecr_preprod_training_calendar_frontend_nginx.repository_url}:latest"
      essential = true
      cpu       = 0
      memory    = null

      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.preprod_training_calendar_frontend_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          <<-EOF
            curl -f \
              -H 'User-Agent: ECS-Health-Checker' \
              http://127.0.0.1/healthcheck || exit 1
          EOF
        ]
        interval    = 60
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}


####################
## ECS Service Definition
####################
resource "aws_ecs_service" "preprod_training_calendar_frontend" {
  name            = "preprod-training-calendar-frontend"
  cluster         = module.preprod_training_calendar_ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.preprod_training_calendar_frontend.arn
  desired_count   = 0
  launch_type     = "EC2"
  enable_execute_command  = true

  load_balancer {
    target_group_arn = aws_lb_target_group.preprod_training_calendar_frontend.arn
    container_name   = "react"
    container_port   = 80
  }

  health_check_grace_period_seconds = 30

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }

  depends_on = [
    aws_lb_listener_rule.preprod_training_calendar_frontend
  ]
}
