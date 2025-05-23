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
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "data_board" {
  ami                    = data.aws_ami.data_board_image.id
  instance_type          = "t3.small" # 2 vCPU, 2GB RAM
  vpc_security_group_ids = [aws_security_group.allow_metabase.id]

  iam_instance_profile = aws_iam_instance_profile.metabase_s3_output_profile.name

  user_data = templatefile("../src/data_board_img.sh", {
    EMAIL   = var.email_address
    DB_USER = aws_db_instance.metabase_db.username
    DB_PASS = aws_db_instance.metabase_db.password
    DB_HOST = aws_db_instance.metabase_db.address
  })

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0100 #how much max we'll pay for the spot instance
    }
  }
}
