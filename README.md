This Terraform module creates a system for updating Linux Workspaces from a new image.  
  
### Requirements:  
VPC with 4 private subnets having Workspaces service available.  
  
### Setup:  
Follow example to call module with vars.  
ssh-keygen -m pem -f windows_server_rsa
terraform init  
terraform apply  
(AWS Console) Create Linux Workspace in protype directory with username 'prototypelinux' and email address where you will receive web link.  
Set password from link in email sent after workspace creation.  
(AWS Console) Create SSM Parameter /workspaces/prototype/password as Type SecureString with default KMS key and just created password as Value.  
(AWS Console) Subscribe to WorkspacesUpdater-Status SNS topic for status notifications.  
  
### Run:
Workflow will run as a scheduled event or can be run by Start Execution in AWS Console|Step Functions|State Machines|WorkspacesUpdater.
Notification will be received when the prototype Linux Workspace has been rebuilt and configured, requesting a new image be created.  
After notifcation received--(AWS Console) Create image from prototype Linux Workspace.   
Notification will be received when live Workspaces have started rebuilding.  
