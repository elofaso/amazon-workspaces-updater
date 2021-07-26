module "workspaces" {
  source = "../"

  vpc_id = "vpc-039986426c8bfeaee"
  vpc_private_subnet_ids = [
                     "subnet-0e40dbad77458d9a4",
                     "subnet-0e9618cba036e86ab",
                     "subnet-0ee191a03e6ebf5c6",
                     "subnet-0fc67ee4b6714b55d"
  ]
  vpc_default_security_group_id = "sg-0d19d98ea9342b01a"
  prototype_directory_password = "hadify9947532ladfaphgsafhoh"
  live_directory_password = "afdahi$eth896394zodfaiadhoha"
} 
