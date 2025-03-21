terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.20.0"
    }
  }
}

provider "aws" {
  region = var.region
}

#get aws account id
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

#aws vpc
resource "aws_vpc" "main_data" {
    cidr_block = "10.0.0.0/16"
}

#metabase instance
data "aws_ami" "data_board_image" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "architecture"
      values = ["x86_64"]
    }
    filter {
        name = "name"
        values = ["al2023-ami-2023*"]
    }
}

resource "aws_instance" "data_board" {
  ami = data.aws_ami.data_board_image.id
  instance_type = "t3.small" # 2 vCPU, 2GB RAM

    user_data = file("../src/data_board_img.sh")

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0100 #how much max we'll pay for the spot instance
    }
  }
}

#security group
resource "aws_security_group" "allow_metabase" {
  name = "allow_tls"
  description = "Allow SSH, HTTP, HTTPS for Metabase"
  vpc_id =  aws_vpc.main_data.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
    security_group_id = aws_security_group.allow_metabase.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
    security_group_id = aws_security_group.allow_metabase.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
}

#all outbound traffic (for metabase reqs)
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
    security_group_id = aws_security_group.allow_metabase.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
    security_group_id = aws_security_group.allow_metabase.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
}
