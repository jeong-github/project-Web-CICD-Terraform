terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# 역할-s3
resource "aws_iam_role" "s3_role" {
  name               = "s3-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 정책 - pipe
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
# policy-pipeline
resource "aws_iam_role_policy_attachment" "role-policy-attach" {
  role       = aws_iam_role.s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

provider "aws" {
  region = "ap-northeast-2"
}
### s3 생성 ###
resource "aws_s3_bucket" "Mys3" {
  bucket = "mys3-9898"

}