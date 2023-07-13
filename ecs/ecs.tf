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
# vpc에서 데이터 끌어오기
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}
# ecr에서 데이터 끌어오기
data "terraform_remote_state" "ecr" {
  backend = "local"

  config = {
    path = "../ecr/terraform.tfstate"
  }
}

# 역할-task
resource "aws_iam_role" "ecs_role" {
  name               = "ecs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 정책-task
data "aws_iam_policy_document" "assume_role" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
# policy-ecs-task
resource "aws_iam_role_policy_attachment" "role-policy-attach1" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "role-policy-attach2" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# policy-ecs
resource "aws_iam_role_policy_attachment" "role-policy-attach3" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

/*
# 역할-ecr
resource "aws_iam_role" "ecr_role" {
  name               = "ecr-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecr.json
}

# 정책-ecr
data "aws_iam_policy_document" "assume_role_ecr" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecr.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "role-policy-attach-ecr" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
*/

### ecs 생성 ###
# ecs cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my_cluster" # Name your cluster

}


# ecs_definition
resource "aws_ecs_task_definition" "service" {
  family                   = "service"   # Name your task
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.ecs_role.arn
  container_definitions = jsonencode([
    {
      name      = "service"
      image     = "${data.terraform_remote_state.ecr.outputs.ecr_url}" #URI
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          name          = "serivce-80-tcp"
          containerPort = 80
          hostPort      = 80
          appProtocol   = "http"
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

}




# ECS service
resource "aws_ecs_service" "ecs_service" {
  name            = "service" # Name the service
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  # iam_role        = aws_iam_role.ecs_role.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.ALB-TG.arn
    container_name   = aws_ecs_task_definition.service.family
    container_port   = 80
  }

  # private subnet에 할당
  network_configuration {
    subnets = [
      data.terraform_remote_state.vpc.outputs.private_subnet1,
      data.terraform_remote_state.vpc.outputs.private_subnet2
    ]
    security_groups  = [aws_security_group.SG_alb.id]
    assign_public_ip = true

  }

}


#LB 구성
# 보안그룹 - ALB
resource "aws_security_group" "SG_alb" {
  name        = "WEBSG"
  description = "Allow HTTP(80/tcp, 8080/tcp)"
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


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG_alb"
  }
}
# Tagret Group 생성
resource "aws_lb_target_group" "ALB-TG" {
  name        = "myALB-TG"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

}
/*
resource "aws_lb_target_group_attachment" "ALB-TG-Attachment" {
  target_group_arn = aws_lb_target_group.ALB-TG.arn
  target_id        = aws_ecs_task_definition.service.id
  port             = 80
}
*/

# ALB 생성
resource "aws_lb" "ALB" {
  name               = "myALB"
  load_balancer_type = "application"
  subnets = [
    data.terraform_remote_state.vpc.outputs.public_subnet1,
    data.terraform_remote_state.vpc.outputs.public_subnet2
  ]
  security_groups = [aws_security_group.SG_alb.id]

}

# ALB Listner 생성
resource "aws_lb_listener" "ALB-Listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALB-TG.arn
  }
}
