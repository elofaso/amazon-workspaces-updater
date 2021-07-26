provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  #profile                 = "mindk"
  profile                 = "default"

  #  assume_role {
  #    role_arn = "arn:aws:iam::326570447294:role/OrganizationAccountAccessRole/elofaso@mindk.com"
  #  }
}

locals {
  region = "us-east-1"
}
