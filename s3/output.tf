output "s3_url" {
  description = "s3-url"
  value       = aws_s3_bucket.Mys3.arn
}

output "s3_name" {
  description = "s3-name"
  value       = aws_s3_bucket.Mys3.id
}

output "s3_bucket" {
  description = "s3 bucket"
  value       = aws_s3_bucket.Mys3.bucket
}