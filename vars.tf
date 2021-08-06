variable "cron_expression" {
  type    = string
  default = "0 8 * * SUN *"
  # 08:00 every Sunday UTC
  # Minutes Hours Day-of-month Month Day-of-week Year
  # https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html#eb-cron-expressions
}

variable "my_ip_address" {
  type    = string
  description = "CIDR block representing IP addresses connecting to Windows Server RDP"
}

variable "vpc_id" {
  type    = string
}

variable "vpc_public_subnet_id" {
  type    = string
  description = "A public subnet ID"
}

variable "vpc_private_subnet_ids" {
  type    = list(any)
  description = "List of 4 private subnet IDs"
}

variable "vpc_default_security_group_id" { 
  type    = string
}

variable "prototype_directory_name" {
  type    = string
  default = "prototype.homegauge.com"
}

variable "prototype_directory_password" {
  description = "password to manage directory"
  type    = string
}

variable "live_directory_name" {
  type    = string
  default = "live.homegauge.com"
}

variable "live_directory_password" {
  description = "password to manage directory"
  type    = string
}

variable "win_amis" {
  type = map(string)
  default = { 
    us-east-1 = "ami-077f1edd46ddb3129"
    us-west-2 = "ami-027bdf1182290ac39"
  } 
} 

variable "path_to_windows_server_private_key" { 
  type    = string
  default = "windows_server_rsa" 
}

variable "path_to_windows_server_public_key" {
  type    = string
  default = "windows_server_rsa.pub" 
}

variable "windows_server_username" {
  type    = string
  default = "admin" 
}

variable "windows_server_password" { 
  type    = string
}
