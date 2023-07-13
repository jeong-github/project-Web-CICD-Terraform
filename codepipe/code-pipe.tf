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
# s3에서 데이터 끌어오기
data "terraform_remote_state" "s3" {
  backend = "local"

  config = {
    path = "../s3/terraform.tfstate"
  }
}
# commit에서 데이터 끌어오기
data "terraform_remote_state" "commit" {
  backend = "local"

  config = {
    path = "../codecommit/terraform.tfstate"
  }
}


# 역할-pipe
resource "aws_iam_role" "pipe_role" {
  name               = "pipe-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 정책 - pipe
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
# policy-pipeline
resource "aws_iam_role_policy_attachment" "role-policy-attach1" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "role-policy-attach2" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# policy-commit
resource "aws_iam_role_policy_attachment" "role-policy-attach3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

# policy-build
resource "aws_iam_role_policy_attachment" "role-policy-attach4" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

# policy-ecs-task
resource "aws_iam_role_policy_attachment" "role-policy-attach5" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# policy-ecs-ecs
resource "aws_iam_role_policy_attachment" "role-policy-attach6" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# policy-ecs-deploy
resource "aws_iam_role_policy_attachment" "role-policy-attach7" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}





### pipeline ###
resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.pipe_role.arn

  artifact_store {
    location = data.terraform_remote_state.s3.outputs.s3_bucket
    type     = "S3"
  }
  # sorcecommit 부분
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS" # 작업의 생성자
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = "MyCommitRepository"
        BranchName     = "master"
      }
    }
  }
  # codebuild
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "MyBuildProject"
      }
    }
  }
  # elasitc container service
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = "my_cluster"
        ServiceName = "service"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
