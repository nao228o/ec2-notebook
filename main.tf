terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# 既存のVPCを参照
data "aws_vpc" "staging" {
  filter {
    name   = "tag:Name"
    values = ["staging-vpc"]
  }
}

# 既存のサブネットを参照
data "aws_subnet" "staging" {
  filter {
    name   = "tag:Name"
    values = ["staging-subnet"]
  }
}

# EC2インスタンスの作成
resource "aws_instance" "example" {
  ami           = "ami-0599b6e53ca798bb2"  # Amazon Linux 2023 AMI
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnet.staging.id
  vpc_security_group_ids      = [aws_security_group.example.id]
  associate_public_ip_address = true

  tags = {
    Name = "example-instance"
  }
}

# セキュリティグループの作成
resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Security group for example EC2 instance"
  vpc_id      = data.aws_vpc.staging.id

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

  tags = {
    Name = "example-security-group"
  }
} 