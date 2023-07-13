output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.my_vpc.id
}
output "public_subnet1" {
  description = "PUBLIC SUBNET1"
  value       = aws_subnet.public_subnet1.id
}

output "public_subnet2" {
  description = "PUBLIC SUBNET2"
  value       = aws_subnet.public_subnet2.id
}

output "private_subnet1" {
  description = "PRIVATE SUBNET1"
  value       = aws_subnet.private_subnet1.id
}

output "private_subnet2" {
  description = "PRIVATE SUBNET2"
  value       = aws_subnet.private_subnet2.id
}