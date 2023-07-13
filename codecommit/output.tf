output "commit_url" {
  description = "commit url"
  value       = aws_codecommit_repository.commit_repository.clone_url_http # ssh로 할거면 clone_rul_ssh
}
output "commit_name" {
  description = "commit name"
  value       = aws_codecommit_repository.commit_repository.repository_name
}