resource "aws_workspaces_directory" "prototype" {
  directory_id = aws_directory_service_directory.prototype.id
  subnet_ids = [
    element(var.vpc_private_subnet_ids, 2),
    element(var.vpc_private_subnet_ids, 3)
  ]

  tags = {
    Example = true
  }

  self_service_permissions {
    change_compute_type  = true
    increase_volume_size = true
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = true
  }

  workspace_access_properties {
    device_type_android    = "ALLOW"
    device_type_chromeos   = "ALLOW"
    device_type_ios        = "ALLOW"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "DENY"
  }

  workspace_creation_properties {
    custom_security_group_id = aws_security_group.allow_ssh.id
    #default_ou                          = "OU=AWS,DC=Workgroup,DC=Homegauge,DC=com"
    enable_internet_access              = true
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.workspaces_default_service_access,
    aws_iam_role_policy_attachment.workspaces_default_self_service_access
  ]
}

resource "aws_directory_service_directory" "prototype" {
  name     = "prototype.homegauge.com"
  password = "#S1ncerely"
  size     = "Small"

  vpc_settings {
    vpc_id = var.vpc_id
    subnet_ids = [
      element(var.vpc_private_subnet_ids, 2),
      element(var.vpc_private_subnet_ids, 3)
    ]
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh`"
  }
}

resource "aws_ssm_parameter" "prototype_directory_id" {
  name  = "/workspaces/prototype/directory_id"
  type  = "String"
  value = aws_directory_service_directory.prototype.id
}

resource "aws_workspaces_directory" "live" {
  directory_id = aws_directory_service_directory.live.id
  subnet_ids = [
    element(var.vpc_private_subnet_ids, 0),
    element(var.vpc_private_subnet_ids, 1)
  ]

  tags = {
    Example = true
  }

  self_service_permissions {
    change_compute_type  = false
    increase_volume_size = false
    rebuild_workspace    = false
    restart_workspace    = true
    switch_running_mode  = false
  }

  workspace_access_properties {
    device_type_android    = "ALLOW"
    device_type_chromeos   = "ALLOW"
    device_type_ios        = "ALLOW"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "DENY"
  }

  workspace_creation_properties {
    #custom_security_group_id            = aws_security_group.workspaces.id
    #default_ou                          = "OU=AWS,DC=Workgroup,DC=Homegauge,DC=com"
    enable_internet_access              = true
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.workspaces_default_service_access,
    aws_iam_role_policy_attachment.workspaces_default_self_service_access
  ]
}

resource "aws_directory_service_directory" "live" {
  name     = var.live_directory_name
  password = var.live_directory_password
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id = var.vpc_id
    subnet_ids = [
      element(var.vpc_private_subnet_ids, 0),
      element(var.vpc_private_subnet_ids, 1)
    ]
  }
}

resource "aws_ssm_parameter" "live_directory_id" {
  name  = "/workspaces/live/directory_id"
  type  = "String"
  value = aws_directory_service_directory.live.id
}

data "aws_iam_policy_document" "workspaces" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workspaces_default" {
  name               = "workspaces_DefaultRole"
  assume_role_policy = data.aws_iam_policy_document.workspaces.json
}

resource "aws_iam_role_policy_attachment" "workspaces_default_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_default_self_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "aws_ssm_parameter" "prototype_linux_username" {
  name  = "/workspaces/prototype/username"
  type  = "String"
  value = "prototypelinux"
}

resource "aws_ssm_parameter" "prototype_linux_password" {
  name  = "/workspaces/prototype/password"
  type  = "SecureString"
  value = "MSDd48!@Rc58iYy"
}
