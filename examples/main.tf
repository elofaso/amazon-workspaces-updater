module "workspaces" {
  source = "../"

  vpc_id = "vpc-05f931f32864dd86b"
  vpc_public_subnet_id = "subnet-0ccd6e0a5d59ac147"
  vpc_private_subnet_ids = [
                     "subnet-000c20ecd7312c2a3",
                     "subnet-033946a105e9307a4",
                     "subnet-009fab6401c8242ef",
                     "subnet-0dfae74d5179a48c9"
  ]
  vpc_default_security_group_id = "sg-05fff065869555ec4"
  prototype_directory_password = "hadify994753@2ladfaphgsafhoh"
  live_directory_password = "afdahi$eth896394zodfaiadhoha"
  cron_expression = "0 8 ? * SUN *"
  windows_server_password = "!@m9CEiKBL3@kL8"
  my_ip_address = "107.214.104.157/32"
} 
