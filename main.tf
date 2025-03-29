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

# IAMロールの作成
resource "aws_iam_role" "ssm_role" {
  name = "ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# SSMのポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAMインスタンスプロファイルの作成
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2_ssm_profile"
  role = aws_iam_role.ssm_role.name
}

# EC2インスタンスの作成
resource "aws_instance" "notebook" {
  ami           = "ami-0599b6e53ca798bb2" # Amazon Linux 2023 AMI
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnet.staging.id
  vpc_security_group_ids      = [aws_security_group.notebook.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name = "staging-notebook-ec2"
  }
}

# セキュリティグループの作成
resource "aws_security_group" "notebook" {
  name        = "notebook-security-group"
  description = "Security group for notebook EC2 instance"
  vpc_id      = data.aws_vpc.staging.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jupyter Notebook用のポート追加
  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 本番環境では適切なIPレンジに制限することを推奨
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "notebook-security-group"
  }
}

# VPCエンドポイントの作成
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.staging.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [data.aws_subnet.staging.id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags = {
    Name = "ssm-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = data.aws_vpc.staging.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [data.aws_subnet.staging.id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags = {
    Name = "ssmmessages-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = data.aws_vpc.staging.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [data.aws_subnet.staging.id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags = {
    Name = "ec2messages-vpc-endpoint"
  }
}

# VPCエンドポイント用のセキュリティグループ
resource "aws_security_group" "vpce" {
  name        = "vpce-security-group"
  description = "Security group for VPC Endpoints"
  vpc_id      = data.aws_vpc.staging.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.notebook.id]
  }

  tags = {
    Name = "vpce-security-group"
  }
}
