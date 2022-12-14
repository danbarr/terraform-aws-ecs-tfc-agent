# Terraform module aws-ecs-tfc-agent

This module creates a Terraform Cloud Agent pool in a TFC org, and deploys a task definition and service into an existing ECS Fargate cluster. It includes the required security group and IAM roles for a basic deployment. For all options, see variables.tf

Prerequisites:

- An existing VPC with at least one public subnet
- An existing ECS Fargate cluster
- A Terraform Cloud organization with self-hosted agent support (Business tier), or a Terraform Enterprise instance

Hat tip to Andy Assareh for his [excellent examples](https://github.com/assareh/tfc-agent).

Minimal example using the standard agent image (hashicorp/tfc-agent):

```terraform
module "agent_standard" {
  source  = "github.com/danbarr/terraform-aws-ecs-tfc-agent?ref=v0.3.0"

  name                      = "ecs"
  tfc_org_name              = "My-TFC-Org"
  ecs_cluster_arn           = "arn:aws:ecs:us-east-1:111111111111:cluster/my-ecs-cluster"
  cloudwatch_log_group_name = "/ecs/tfc-agents"
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
}
```

Example using a customized tfc-agent image hosted in ECR, plus my aws-ecs-fargate-cluster module to also create the ECS cluster:

```terraform
module "agent_cluster" {
  source             = "github.com/danbarr/terraform-aws-ecs-fargate-cluster?ref=v0.9.1"
  cluster_name       = "tfc-agent-cluster"
}

module "agent_standard" {
  source  = "github.com/danbarr/terraform-aws-ecs-tfc-agent?ref=v0.3.0"

  name                      = "ecs-custom"
  tfc_org_name              = "My-TFC-Org"
  agent_image               = "111111111111.dkr.ecr.us-east-1.amazonaws.com/tfc-custom-agent"
  ecs_cluster_arn           = module.agent_cluster.cluster_arn
  use_spot_instances        = true
  cloudwatch_log_group_name = "/ecs/tfc-agents"
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
}
```
