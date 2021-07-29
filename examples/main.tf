module "workspaces" {
  source = "../"

  vpc_id = "vpc-05f931f32864dd86b"
  vpc_private_subnet_ids = [
                     "subnet-000c20ecd7312c2a3",
                     "subnet-033946a105e9307a4",
                     "subnet-009fab6401c8242ef",
                     "subnet-0dfae74d5179a48c9"
  ]
  vpc_default_security_group_id = "sg-05fff065869555ec4"
  prototype_directory_password = "hadify9947532ladfaphgsafhoh"
  live_directory_password = "afdahi$eth896394zodfaiadhoha"
  cron_expression = "0 20 * * ? *"
} 
