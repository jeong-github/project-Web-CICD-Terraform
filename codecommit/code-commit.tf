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

### Codecommit  ###
#Codecommit-repository
resource "aws_codecommit_repository" "commit_repository" {
  repository_name = "MyCommitRepository"
  description     = "Repository for CodeCommit"

}
/*
# 승인 규칙 템플릿
resource "aws_codecommit_approval_rule_template" "code_rule_template" {
  name        = "MyCodeRuleTemplate"
  description = "aws_codecommit_approval_rule_template Code Rule Template"
  content = jsondecode({

  })
}

*/