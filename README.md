# amazon-workspaces-updater

A Terraform module that creates a system for updating Linux Amazon WorkSpaces from a new image. A scheduled AWS Step Functions workflow rebuilds and configures a prototype WorkSpace, notifies an administrator over SNS to capture a new image, and then rebuilds the live WorkSpaces from that image.

> **Status:** Not maintained. AWS has since added native support for this, so this repository is kept as a reference for Step Functions and infrastructure-as-code patterns.

## Requirements

- A VPC with 4 private subnets that have the WorkSpaces service available.

## Setup

1. Call the module with your variables, following the example in this repository.
2. Generate the key pair:

   ```
   ssh-keygen -m pem -f windows_server_rsa
   ```

3. Initialize and apply:

   ```
   terraform init
   terraform apply
   ```

4. In the AWS Console, create a Linux WorkSpace in the prototype directory with the username `prototypelinux` and an email address where you will receive the web link.
5. Set the password from the link in the email sent after the WorkSpace is created.
6. In the AWS Console, create an SSM parameter named `/workspaces/prototype/password` of type `SecureString`, using the default KMS key, with the password you just set as the value.
7. In the AWS Console, subscribe to the `WorkspacesUpdater-Status` SNS topic for status notifications.

## Run

The workflow runs as a scheduled event, or you can start it manually with **Start execution** in AWS Console > Step Functions > State machines > `WorkspacesUpdater`.

1. You receive a notification when the prototype Linux WorkSpace has been rebuilt and configured, requesting that a new image be created.
2. In the AWS Console, create an image from the prototype Linux WorkSpace.
3. You receive a notification when the live WorkSpaces have started rebuilding.
