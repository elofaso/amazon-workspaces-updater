variable "cron_expression" {
  type    = string
  default = "0 8 * * SUN *"
  # 08:00 every Sunday UTC
  # Minutes Hours Day-of-month Month Day-of-week Year
  # https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html#eb-cron-expressions
}

variable "vpc_id" {
  type    = string
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

variable "linux_bundle_id" {
  default = "wsb-clj85qzj1" # Standard with Amazon Linux 2 (English) with 2 vCPU 4GiB Memory 50GB Storage
}
