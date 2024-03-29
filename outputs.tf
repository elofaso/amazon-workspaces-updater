output "prototype_directory_id" {
  description = "ID of the prototype workspaces directory"
  value = aws_directory_service_directory.prototype.id
}

output "live_directory_id" {
  description = "ID of the live workspaces directory"
  value = aws_directory_service_directory.live.id
}

output "step_function_workspaces_management_arn" {
  description = "The ARN of the Step Function"
  value = module.step_function_workspaces_management.state_machine_arn
}

output "lambda_layer_layer_arn" {
  description = "The ARN of the Lambda Layer without version"
  value       = module.lambda_layer_python_paramiko.lambda_layer_layer_arn
}

output "lambda_function_get_workspace_state_arn" {
  description = "The ARN of the Lambda Function"
  value       = module.lambda_function_get_workspace_state.lambda_function_arn
}

output "lambda_function_rebuild_workspaces_arn" {
  description = "The ARN of the Lambda Function"
  value       = module.lambda_function_rebuild_workspaces.lambda_function_arn
}

output "lambda_function_configure_linux_workspace_arn" {
  description = "The ARN of the Lambda Function"
  value       = module.lambda_configure_linux_workspace.lambda_function_arn
}

output "lambda_function_check_for_new_workspace_image_arn" {
  description = "The ARN of the Lambda Function"
  value       = module.lambda_check_for_new_workspace_image.lambda_function_arn
}

output "lambda_function_update_workspace_bundle_arn" {
  description = "The ARN of the Lambda Function"
  value       = module.lambda_update_workspace_bundle.lambda_function_arn
}

output "sns_topic_step_function_status_arn" {
  description = "The ARN of the SNS Topic"
  value       = aws_sns_topic.step_function_status.arn
}

output "windows_server_public_ip" {
  value=aws_instance.windows_server.public_ip
}

output "windows_server_private_ip" {
  value=aws_instance.windows_server.private_ip
}
