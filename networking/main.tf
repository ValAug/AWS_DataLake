#---networking/main---

data "aws_availability_zone" "dedicateaz" {
  name = "us-east-1a"
}


resource "tls_private_key" "prikey" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo '${tls_private_key.prikey.private_key_pem}' > ./key.pem"


  }
}

resource "aws_key_pair" "logskey" {
  key_name   = "key"
  public_key = tls_private_key.prikey.public_key_openssh

}
resource "aws_instance" "logs" {
  count = var.ec2_count
  ami                         = "ami-0742b4e673072066f"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.dlogssub.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  depends_on                  = [aws_internet_gateway.bigdataigw]
  key_name                    = aws_key_pair.logskey.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
          #!/bin/bash -xe
          yum -y update
          yum install -y aws-kinesis-agent
          EOF

  tags = {
    "Name" = "ec2-app-02"
  }
}

resource "aws_vpc" "datalogs_env" {
  cidr_block           = cidrsubnet("10.0.0.0/20", 3, var.region_number[data.aws_availability_zone.dedicateaz.region])
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "datalogs_vpc"
  }
}

resource "aws_subnet" "dlogssub" {
  vpc_id                  = aws_vpc.datalogs_env.id
  cidr_block              = cidrsubnet(aws_vpc.datalogs_env.cidr_block, 1, var.az_number[data.aws_availability_zone.dedicateaz.name_suffix])
  map_public_ip_on_launch = false

  tags = {
    Name = "dlogssubnet"
  }
}

resource "aws_internet_gateway" "bigdataigw" {
  vpc_id = aws_vpc.datalogs_env.id

  tags = {
    Name = "bigdataigw"
  }
}

resource "aws_route_table" "datalogs_env_rt" {
  vpc_id = aws_vpc.datalogs_env.id
}

resource "aws_route" "rt_route" {
  route_table_id         = aws_route_table.datalogs_env_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bigdataigw.id
}


resource "aws_route_table_association" "rt_pub_access" {
  route_table_id = aws_route_table.datalogs_env_rt.id
  subnet_id      = aws_subnet.dlogssub.id
}

resource "aws_eip" "logseip" {
  vpc = true

  tags = {
    Name = "ec2logseip"
  }
}

resource "aws_eip_association" "webeip_assoc" {
  count = var.ec2_count  
  instance_id   = aws_instance.logs[count.index].id
  allocation_id = aws_eip.logseip.id
}


resource "aws_security_group" "web_sg" {
  name        = "dnsevnsg"
  description = "Security group for pub  access"
  vpc_id      = aws_vpc.datalogs_env.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

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

}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy" "ec2_delivery_policy" {
  role = aws_iam_role.ec2_role.id

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}

EOT
}