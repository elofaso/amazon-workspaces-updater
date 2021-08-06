resource "aws_security_group" "allow_rdp_winrm" {
  name="allow_rdp_winrm"
  vpc_id = var.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 6556
    protocol = "tcp"
    cidr_blocks = [var.my_ip_address]
  }
  ingress {
    from_port = 0
    to_port = 5985
    protocol = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

 
  tags = {
    Name = "allow_rdp_winrm"
  }
 
}

resource "aws_key_pair" "windows_server" {
  key_name   = "WorkspacesManager-WindowsServer"
  public_key = file(var.path_to_windows_server_public_key)
}
 
data "template_file" "userdata_win" {
  template = <<EOF
<powershell>
echo "" > _INIT_STARTED_
net user ${var.windows_server_username} /add /y
net user ${var.windows_server_username} ${var.windows_server_password}
net localgroup administrators ${var.windows_server_username} /add
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
echo "" > _INIT_COMPLETE_
</powershell>
<persist>false</persist>
EOF
}

 resource "aws_network_interface" "windows_server" {
  subnet_id   = var.vpc_public_subnet_id
  security_groups=[aws_security_group.allow_rdp_winrm.id]
  tags = {
    Name = "windows_server_primary_network_interface"
  }
}

#Instance Role
resource "aws_iam_role" "windows_server" {
  name = "ec2-ssm"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "ec2-ssm"
    Project = "WorkspacesUpdater"
  }
}

#Instance Profile
resource "aws_iam_instance_profile" "windows_server" {
  name = "ec2-ssm"
  role = "${aws_iam_role.windows_server.id}"
}

#Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "ssm_1" {
  name       = "ec2-ssm"
  roles      = [aws_iam_role.windows_server.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ssm_2" {
  name       = "ec2-ssm"
  roles      = [aws_iam_role.windows_server.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
} 

data "aws_region" "current" {}

resource "aws_instance" "windows_server" {
  ami           = var.win_amis[data.aws_region.current.name]
  instance_type = "t2.micro"
  key_name      = aws_key_pair.windows_server.key_name
  iam_instance_profile = aws_iam_instance_profile.windows_server.id
  user_data = data.template_file.userdata_win.rendered

  network_interface {
    network_interface_id = aws_network_interface.windows_server.id
    device_index         = 0
  }
 
  tags = {
    Name = "WorkspacesManagement-WindowsServer"
  }
 
}

resource "aws_ssm_document" "ad_join_domain" {
  name          = "ad-join-domain"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2"
      "description"   = "aws:domainJoin"
      "mainSteps" = [
        {
          "action" = "aws:domainJoin",
          "name"   = "domainJoin",
          "inputs" = {
            "directoryId" : aws_directory_service_directory.live.id,
            "directoryName" : aws_directory_service_directory.live.name
            "dnsIpAddresses" : sort(aws_directory_service_directory.live.dns_ip_addresses)
          }
        }
      ]
    }
  )
}

resource "aws_ssm_association" "windows_server" {
  name = aws_ssm_document.ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.windows_server.id]
 
  }
}
