{
  "StartAt": "Rebuild Prototype Linux Workspace",
  "States": {
    "Rebuild Prototype Linux Workspace": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${lambda_function_rebuild_workspaces_arn}",
        "Payload": {
          "directoryIdParameter": "/workspaces/prototype/directory_id"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Get Prototype Linux Workspace State"
    },
    "Get Prototype Linux Workspace State": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${lambda_function_get_workspace_state_arn}",
        "Payload": {
          "directoryIdParameter": "/workspaces/prototype/directory_id"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 600,
          "MaxAttempts": 10,
          "BackoffRate": 1
        }
      ],
      "Next": "Rebuild complete?"
    },
    "Rebuild complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Or": [
            {
              "Variable": "$.state",
              "StringEquals": "AVAILABLE"
            },
            {
              "Variable": "$.state",
              "StringEquals": "STOPPED"
            }
          ],
          "Next": "Configure Prototype Linux Workspace"
        }
      ],
      "Default": "Wait For Rebuild"
    },
    "Configure Prototype Linux Workspace": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${lambda_function_configure_linux_workspace_arn}",
        "Payload": {
          "directoryIdParameter": "/workspaces/prototype/directory_id"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Publish to SNS (Ready for image creation)"
    },
    "Wait For Rebuild": {
      "Type": "Wait",
      "Seconds": 600,
      "Next": "Get Prototype Linux Workspace State"
    },
    "Publish to SNS (Ready for image creation)": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "ResultPath": null,
      "Parameters": {
        "TopicArn": "${sns_topic_step_function_status_arn}",
        "Subject": "SUCCESS: Configuration of Prototype Linux Workstation",
        "Message": "Ready for image creation."
      },
      "Next": "Check For New Image"
    },
    "Check For New Image": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${lambda_function_check_for_new_workspace_image_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "New Image Available?"
    },
    "New Image Available?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.statusCode",
          "NumericEquals": 200,
          "Next": "Update Linux Bundle"
        },
        {
          "Variable": "$.statusCode",
          "NumericEquals": 400,
          "Next": "Wait For New Image"
        }
      ]
    },
    "Update Linux Bundle": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${lambda_function_update_workspace_bundle_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Rebuild Live Linux Workspaces"
    },
    "Rebuild Live Linux Workspaces": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${lambda_function_rebuild_workspaces_arn}",
        "Payload": {
          "directoryIdParameter": "/workspaces/live/directory_id"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 600,
          "MaxAttempts": 10,
          "BackoffRate": 1
        }
      ],
      "Next": "Publish to SNS (Live Workspaces Rebuilding)"
    },
    "Publish to SNS (Live Workspaces Rebuilding)": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "${sns_topic_step_function_status_arn}",
        "Subject": "SUCCESS: Live Linux Workspaces are rebuilding",
        "Message": "Allow 45 minutes for rebuilding."
      },
      "Next": "SuccessState"
    },
    "Wait For New Image": {
      "Type": "Wait",
      "Seconds": 600,
      "Next": "Check For New Image"
    },
    "SuccessState": {
      "Type": "Pass",
      "End": true
    }
  }
}
