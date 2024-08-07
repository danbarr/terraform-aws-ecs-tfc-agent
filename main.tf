terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.24"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.36"
    }
  }
}

data "aws_region" "current" {}

resource "tfe_agent_pool" "ecs_agent_pool" {
  name         = "${var.name}-agent-pool"
  organization = var.tfc_org_name
}

resource "tfe_agent_token" "ecs_agent_token" {
  agent_pool_id = tfe_agent_pool.ecs_agent_pool.id
  description   = "${var.name}-agent-token"
}

resource "aws_ssm_parameter" "agent_token" {
  name        = "/tfc-agent-token/${var.tfc_org_name}/${var.name}"
  description = "HCP Terraform agent token"
  type        = "SecureString"
  value       = tfe_agent_token.ecs_agent_token.token
}

resource "aws_ecs_task_definition" "tfc_agent" {
  family                   = "tfc-agent-${var.tfc_org_name}-${var.name}"
  cpu                      = var.agent_cpu
  memory                   = var.agent_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  runtime_platform {
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        name : "tfc-agent"
        image : var.agent_image
        essential : true
        cpu : 0
        memory : 256
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-create-group : "true",
            awslogs-group : var.cloudwatch_log_group_name
            awslogs-region : data.aws_region.current.name
            awslogs-stream-prefix : "tfc-agent-${var.tfc_org_name}-${var.name}"
          }
        }
        environment = concat([
          {
            name  = "TFC_AGENT_SINGLE",
            value = tostring(var.agent_single_execution)
          },
          {
            name  = "TFC_AGENT_NAME",
            value = "tfc-agent-${var.name}"
          },
          {
            name  = "TFC_ADDRESS",
            value = var.tfc_address
          },
          {
            name  = "TFC_AGENT_LOG_LEVEL",
            value = var.agent_log_level
          },
          {
            name  = "TFC_AGENT_AUTO_UPDATE",
            value = var.agent_auto_update
          }
        ], var.extra_env_vars),
        secrets = [
          {
            name      = "TFC_AGENT_TOKEN",
            valueFrom = aws_ssm_parameter.agent_token.arn
          }
        ]
      }
    ]
  )
}

resource "aws_ecs_service" "tfc_agent" {
  name            = "tfc-agent-${var.tfc_org_name}-${var.name}"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.tfc_agent.arn
  desired_count   = var.num_agents
  propagate_tags  = "SERVICE"

  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "33"
  enable_ecs_managed_tags            = "true"

  capacity_provider_strategy {
    capacity_provider = var.use_spot_instances ? "FARGATE_SPOT" : "FARGATE"
    weight            = "1"
  }

  network_configuration {
    assign_public_ip = "true"
    security_groups  = [aws_security_group.tfc_agent.id]
    subnets          = var.subnet_ids
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

moved {
  from = aws_ecs_service.tfc-agent
  to   = aws_ecs_service.tfc_agent
}

resource "aws_security_group" "tfc_agent" {
  name_prefix = "tfc-agent-${var.tfc_org_name}-${var.name}-sg"
  description = "Security group for tfc-agent: ${var.name} in org ${var.tfc_org_name}"
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress" {
  security_group_id = aws_security_group.tfc_agent.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

## IAM
# Two roles are defined: the task execution role used during initialization,
# and the task role which is assumed by the container(s).

data "aws_iam_policy_document" "agent_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "tfc-agent-${var.tfc_org_name}-${var.name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "agent_init_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = [aws_ssm_parameter.agent_token.arn]
  }
}

resource "aws_iam_role_policy" "agent_init_policy" {
  role   = aws_iam_role.ecs_task_execution_role.name
  name   = "AccessSSMforAgentToken"
  policy = data.aws_iam_policy_document.agent_init_policy.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "tfc-agent-${var.tfc_org_name}-${var.name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  for_each = toset(var.task_policy_arns)

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = each.key
}
