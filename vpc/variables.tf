##### VPC 생성 #####
variable "vpc_cidr" {
  description = "VPC"
  type        = string
  default     = "10.16.0.0/16"
}

variable "instance_tenancy" {
  description = "Instance Tenancy"
  type        = string
  default     = "default"
}

variable "vpc_tag" {
  description = "VPC tags"
  type        = map(string)
  default = {
    Name = "my_vpc"
  }
}