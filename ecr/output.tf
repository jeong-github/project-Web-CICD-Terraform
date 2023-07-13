output "ecr_name" {
  description = "ECR NAME"
  value       = aws_ecr_repository.my_ecr.name
}
output "ecr_url" {
  description = "ECR NAME"
  value       = aws_ecr_repository.my_ecr.repository_url
}
