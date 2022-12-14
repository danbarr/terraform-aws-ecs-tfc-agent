output "agent_pool_name" {
  description = "Name of the TFC agent pool."
  value       = tfe_agent_pool.ecs_agent_pool.name
}

output "agent_pool_id" {
  description = "ID of the TFC agent pool."
  value       = tfe_agent_pool.ecs_agent_pool.id
}

output "ecs_service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.tfc_agent.id
}

output "ecs_task_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.tfc_agent.arn
}

output "ecs_task_revision" {
  description = "Revision number of the ECS task definition."
  value       = aws_ecs_task_definition.tfc_agent.revision
}

output "log_stream_prefix" {
  description = "Prefix for the CloudWatch log stream."
  value       = jsondecode(aws_ecs_task_definition.tfc_agent.container_definitions)[0].logConfiguration.options.awslogs-stream-prefix
}

output "security_group_name" {
  description = "Name of the VPC security group attached to the service."
  value       = aws_security_group.tfc_agent.name
}

output "security_group_id" {
  description = "ID of the VPC security group attached to the service."
  value       = aws_security_group.tfc_agent.id
}

output "task_role_name" {
  description = "Name of the IAM role attached to the task containers."
  value       = aws_iam_role.ecs_task_role.name
}

output "task_role_arn" {
  description = "ARN of the IAM role attached to the task containers."
  value       = aws_iam_role.ecs_task_role.arn
}
