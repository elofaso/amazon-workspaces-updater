#provider "aws" {
#  region = "eu-west-1"
#  #  region = "us-east-1"
#
#  # Make it faster by skipping something
#  skip_get_ec2_platforms      = true
#  skip_metadata_api_check     = true
#  skip_region_validation      = true
#  skip_credentials_validation = true
#  skip_requesting_account_id  = true
#}
 
module "lambda_layer_python_paramiko" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name  = "PythonParamiko"
  runtime     = "python3.7"
  compatible_runtimes = ["python3.7"]

  create_package         = false
  local_existing_package = "${path.module}/src/lambda_layer-PythonParamiko/lambda_layer-PythonParamiko.zip"
}

module "lambda_function_get_workspace_state" {
  source = "terraform-aws-modules/lambda/aws"

  publish = true

  function_name = "WorkspacesUpdater-getWorkspaceState"
  description   = "Returns state of prototype Linux Workspace"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 30

  source_path = "${path.module}/src/lambda_function-getWorkspaceState/"

  attach_cloudwatch_logs_policy = true

  attach_policy_statements = true
  policy_statements = {
    ssm_get_parameter = {
      effect    = "Allow",
      actions   = ["ssm:GetParameter"],
      resources = ["arn:aws:ssm:*:*:parameter/workspaces/*"]
    },
    workspaces_describe_workspaces = {
      effect    = "Allow",
      actions   = ["workspaces:DescribeWorkspaces"],
      resources = ["*"]
    }
  }
}

module "lambda_function_rebuild_workspaces" {
  source = "terraform-aws-modules/lambda/aws"

  publish = true

  function_name = "WorkspacesUpdater-rebuildWorkspaces"
  description   = "Rebuilds Workspaces in specified Directory"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 30

  source_path = "${path.module}/src/lambda_function-rebuildWorkspaces/"

  attach_cloudwatch_logs_policy = true

  attach_policy_statements = true
  policy_statements = {
    ssm_get_parameter = {
      effect    = "Allow",
      actions   = ["ssm:GetParameter"],
      resources = ["arn:aws:ssm:*:*:parameter/workspaces/*"]
    },
    workspaces_rebuild_workspaces = {
      effect    = "Allow",
      actions   = ["workspaces:DescribeWorkspaces", "workspaces:RebuildWorkspaces"],
      resources = ["*"]
    }
  }
}
 
module "lambda_configure_linux_workspace" {
  source = "terraform-aws-modules/lambda/aws"

  publish = true

  function_name = "WorkspacesUpdater-configureLinuxWorkspace"
  description   = "Installs software on prototype Linux Workspace"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 600

  source_path = "${path.module}/src/lambda_function-configureLinuxWorkspace/"

  vpc_subnet_ids = [
    element(var.vpc_private_subnet_ids, 2),
    element(var.vpc_private_subnet_ids, 3)
  ]
  vpc_security_group_ids = [var.vpc_default_security_group_id]
  attach_network_policy  = true

  #layers = [module.lambda_layer_python_paramiko.lambda_layer_arn]
  layers = ["arn:aws:lambda:us-east-1:898466741470:layer:paramiko-py37:2"]

  attach_cloudwatch_logs_policy = true

  attach_policy_statements = true
  policy_statements = {
    ssm_get_parameter = {
      effect    = "Allow",
      actions   = ["ssm:GetParameter", "kms:Decrypt"],
      resources = ["arn:aws:ssm:*:*:parameter/workspaces/*"]
    },
    workspaces_describe_workspaces = {
      effect    = "Allow",
      actions   = ["workspaces:DescribeWorkspaces"],
      resources = ["*"]
    }
  }
}

module "lambda_check_for_new_workspace_image" {
  source = "terraform-aws-modules/lambda/aws"

  publish = true

  function_name = "WorkspacesUpdater-checkForNewWorkspaceImage"
  description   = "Checks for AVAILABLE Workspace Image created since completion time of configure_linux_workspace"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 30

  source_path = "${path.module}/src/lambda_function-checkForNewWorkspaceImage/"

  attach_cloudwatch_logs_policy = true

  attach_policy_statements = true
  policy_statements = {
    workspaces_describe_workspace_images = {
      effect    = "Allow",
      actions   = ["workspaces:DescribeWorkspaceImages"],
      resources = ["*"]
    }
  }
}

module "lambda_update_workspace_bundle" {
  source = "terraform-aws-modules/lambda/aws"

  publish = true

  function_name = "WorkspacesUpdater-updateWorkspaceBundle"
  description   = "Updates Workspace Bundle with new Image ID"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 30

  source_path = "${path.module}/src/lambda_function-updateWorkspaceBundle/"

  attach_cloudwatch_logs_policy = true

  attach_policy_statements = true
  policy_statements = {
    ssm_get_parameter = {
      effect    = "Allow",
      actions   = [
              "ssm:GetParameter",
              "ssm:PutParameter"
      ],
      resources = ["arn:aws:ssm:*:*:parameter/workspaces/*"]
    },
    workspaces_describe_workspaces = {
      effect    = "Allow",
      actions   = [
              "workspaces:UpdateWorkspaceBundle",
              "workspaces:CreateWorkspaceBundle"
      ],
      resources = ["*"]
    }
  }
}

resource "aws_sns_topic" "step_function_status" {
  name = "WorkspacesUpdater-Status"
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.step_function_status.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_caller_identity" "current" {}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.step_function_status.arn,
    ]

    sid = "__default_statement_ID"
  }
}

module "step_function_workspaces_management" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = "WorkspacesUpdater"
  definition = templatefile("${path.module}/step_function_workspaces_updater.tpl",{
 			lambda_function_get_workspace_state_arn = module.lambda_function_get_workspace_state.lambda_function_qualified_arn,
 			lambda_function_rebuild_workspaces_arn = module.lambda_function_rebuild_workspaces.lambda_function_qualified_arn,
		        lambda_function_configure_linux_workspace_arn = module.lambda_configure_linux_workspace.lambda_function_qualified_arn,
 			lambda_function_check_for_new_workspace_image_arn = module.lambda_check_for_new_workspace_image.lambda_function_qualified_arn,
                        lambda_function_update_workspace_bundle_arn = module.lambda_update_workspace_bundle.lambda_function_qualified_arn,
			sns_topic_step_function_status_arn = aws_sns_topic.step_function_status.arn
  })

  attach_cloudwatch_logs_policy = true
  logging_configuration = {
    include_execution_data = false
    level                  = "ERROR"
  } 

  attach_policy_statements = true
  policy_statements = {
    ssm_get_parameter = {
      effect    = "Allow",
      actions   = ["lambda:InvokeFunction"],
      resources = [
               module.lambda_function_get_workspace_state.lambda_function_qualified_arn,
               module.lambda_function_rebuild_workspaces.lambda_function_qualified_arn,
               module.lambda_configure_linux_workspace.lambda_function_qualified_arn,
               module.lambda_check_for_new_workspace_image.lambda_function_qualified_arn,
               module.lambda_update_workspace_bundle.lambda_function_qualified_arn
      ]
    },
    sns_publish = {
      effect    = "Allow",
      actions   = ["sns:Publish"],
      resources = [aws_sns_topic.step_function_status.arn]
    }
  }
}

module "eventbridge_workspaces_updater-cron" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  role_name ="WorkspacesUpdater-eventbridge-cron"

  attach_sfn_policy = true
  sfn_target_arns   = [module.step_function_workspaces_management.state_machine_arn]

  #attach_cloudwatch_policy = true
  #cloudwatch_target_arns   = [aws_cloudwatch_log_group.this.arn]

  rules = {
    WorkspacesUpdater-cron = {
      description   = "Start step function"
      schedule_expression = "cron(${var.cron_expression})"
      enabled       = true
    }
 }
 
  targets = {
    WorkspacesUpdater-cron = [
      {
        name              = "WorkspacesUpdater-start"
        arn               = module.step_function_workspaces_management.state_machine_arn
	attach_role_arn   = true
      }
    ]
 }
}

resource "aws_cloudwatch_log_group" "log_group_workspaces_updater_status" {
  name = "/aws/events/WorkspacesUpdater-Status"
}

module "eventbridge_workspaces_updater_status_failed" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  role_name ="WorkspacesUpdater-eventbridge-status-failed"

  attach_cloudwatch_policy = true
  cloudwatch_target_arns   = [aws_cloudwatch_log_group.log_group_workspaces_updater_status.arn]

  rules = {
   WorkspacesUpdater-failed = {
      description   = "Report step function failures"
      event_pattern = jsonencode(
                {
                  "source": ["aws.states"],
                  "detail-type": ["Step Functions Execution Status Change"],
                  "detail": {
                     "status": ["FAILED"],
                     "stateMachineArn": [module.step_function_workspaces_management.state_machine_arn]
                  }
                }
      )
      enabled       = true
    }
  }
 
  targets = {
   WorkspacesUpdater-failed = [
      {
        name              = "WorkspacesUpdater-failed"
        arn               = aws_sns_topic.step_function_status.arn
      }
    ]
  }
}

