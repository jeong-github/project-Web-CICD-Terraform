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
data "terraform_remote_state" "s3" {
  backend = "local"

  config = {
    path = "../s3/terraform.tfstate"
  }
}

data "terraform_remote_state" "commit" {
  backend = "local"

  config = {
    path = "../codecommit/terraform.tfstate"
  }
}
### Codebuild  ###

# 역할- codbuild
resource "aws_iam_role" "build_role" {
  name               = "build-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 정책-codebuild
data "aws_iam_policy_document" "assume_role" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}
# policy-build
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}
# policy-ecr
resource "aws_iam_role_policy_attachment" "role_policy_attachment2" {
  role       = aws_iam_role.build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "role_policy_attachment3" {
  role       = aws_iam_role.build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# codebuildproject
resource "aws_codebuild_project" "MyBuildProject" {
  name         = "MyBuildProject"
  description  = "code-build-project"
  service_role = aws_iam_role.build_role.arn # IAM 역할지정
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"       # 빌드환경컴퓨팅유형
    image                       = "aws/codebuild/standard:2.0" # 사용자 지정 이미지-도커이미지
    type                        = "LINUX_CONTAINER"            # 환경유형 - Linux
    image_pull_credentials_type = "CODEBUILD"                  # 자격증명 유형 
    privileged_mode             = true
  }
  #의심 - 인터넷에서는 아티팩트 설정 필요했음
  /*
  artifacts {
    type = "NO_ARTIFACTS"
  }
  */

  artifacts {
    type = "S3"
    #name     = data.terraform_remote_state.s3.outputs.s3_name
    location  = data.terraform_remote_state.s3.outputs.s3_bucket
    path      = "/"
    packaging = "ZIP"
  }

  source {
    type     = "CODECOMMIT"
    location = data.terraform_remote_state.commit.outputs.commit_url
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
  }
}
