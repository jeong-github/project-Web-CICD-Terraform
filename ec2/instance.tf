terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
# vpc 에서 데이터 끌어오기
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}
# 내부 instance에 접근하기위한 key 생성
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2_key"
  public_key = file("./testPubkey.pub")
}

# 보안그룹 - instance
resource "aws_security_group" "SG_instance" {
  name        = "SG_instance"
  description = "Allow HTTP(80/tcp, 8080/tcp), ssh(22/tcp)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow HTTP(80)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "Allow HTTPs(8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ssh(22)"
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
    Name = "SG_instance"
  }
}
### iam role ###
# role
resource "aws_iam_role" "ecr-role" {
  name               = "ecr-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
#정책
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role_policy_attachment" "role-policy-attach" {
  role       = aws_iam_role.ecr-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.ecr-role.name
}

# bastion-인스턴스 생성
resource "aws_instance" "bastion-host" {
  ami                    = "ami-0a734c0832772f63f" # amazon linux2 -> 만든 이미지 파일
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids = [aws_security_group.SG_instance.id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet1
  user_data              = <<-EOF
  #!/bin/bash
  sudo -i
  sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
  systemctl restart sshd
  echo 'qwe123' | passwd --stdin root 
  yum install -y docker
  
  EOF

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "bastion-host"
  }
}