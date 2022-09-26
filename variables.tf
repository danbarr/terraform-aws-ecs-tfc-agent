variable "name" {
  type        = string
  description = "A unique name to apply to resources."
}

variable "tfc_address" {
  type        = string
  description = "The HTTPS address of the TFC or TFE instance."
  default     = "https://app.terraform.io"
}

variable "tfc_org_name" {
  type        = string
  description = "The name of the TFC/TFE organization where the agent pool will be configured."
}

variable "agent_cpu" {
  type        = number
  description = "The CPU units allocated to the agent container(s). See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size"
  default     = 256
}

variable "agent_memory" {
  type        = number
  description = "The amount of memory, in MB, allocated to the agent container(s)."
  default     = 512
}

variable "agent_log_level" {
  type        = string
  description = "The logging verbosity for the agent. Valid values are trace, debug, info (default), warn, and error."
  default     = "info"
}

variable "agent_image" {
  type        = string
  description = "The Docker image to launch."
  default     = "hashicorp/tfc-agent:latest"
}

variable "extra_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Extra environment variables to pass to the agent container."
  default     = []
}

variable "num_agents" {
  type        = number
  description = "The number of agent containers to run."
  default     = 1
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "The name of the CloudWatch log group where agent logs will be sent."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster where the agent will be deployed."
}

variable "use_spot_instances" {
  type        = bool
  description = "Whether to use Fargate Spot instances."
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the cluster is running."
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of the subnet(s) where agents can be deployed (public subnets required)"
}

variable "task_policy_arns" {
  type        = list(string)
  description = "ARN(s) of IAM policies to attach to the agent task. Determines what actions the agent can take without requiring additional AWS credentials."
  default     = []
}
