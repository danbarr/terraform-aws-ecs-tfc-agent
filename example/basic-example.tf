terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.56"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "tfe" {}

module "agent_pool" {
  source                    = "github.com/danbarr/terraform-aws-ecs-tfc-agent?ref=v0.3.0"
  name                      = "ecs"
  tfc_org_name              = "My-TFC-Org"
  agent_image               = "hashicorp/tfc-agent:latest"
  agent_cpu                 = 512
  agent_memory              = 1024
  ecs_cluster_arn           = "arn:aws:ecs:us-east-1:111111111111:cluster/my-tfc-agents"
  use_spot_instances        = true
  cloudwatch_log_group_name = "/ecs/tfc-agents"
  vpc_id                    = "vpc-41a433131d9569b7d"
  subnet_ids                = ["subnet-5e3d39071f6217087", "subnet-1c4d9edecb26cefd8", "subnet-55703c241c0acb3c3"]
}
